#!/usr/bin/env python3
"""Small status page and shared atlas for one Valheim dedicated server."""

import gzip
import hmac
import json
import math
import os
import re
import struct
import subprocess
import tarfile
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

PORT = int(os.environ.get("DASHBOARD_PORT", "8000"))
WORLD_NAME = os.environ["VALHEIM_WORLD_NAME"]
WORLD_SEED = os.environ.get("VALHEIM_WORLD_SEED", "")
GAME_PORT = int(os.environ.get("VALHEIM_SERVER_PORT", "2456"))
SERVER_PASSWORD = os.environ.get("VALHEIM_SERVER_PASSWORD", "")
WORLDS_DIR = Path(os.environ["VALHEIM_WORLDS_DIR"])
STATE_DIR = Path(os.environ.get("STATE_DIRECTORY", "/var/lib/valheim-dashboard"))
IGNORED_PLAYERS = set(filter(None, os.environ.get("VALHEIM_DASHBOARD_IGNORED_PLAYERS", "").split(",")))
STATE_FILE = STATE_DIR / "state.json"
INDEX_FILE = Path(__file__).with_name("index.html")
MAP_PAGE = Path(__file__).with_name("map.html")
ATLAS_SCRIPT = Path(__file__).with_name("atlas.js")
MAP_FILE = STATE_DIR / "map.json"
EDITION_FILE = STATE_DIR / "edition.json"
EDITIONS_DIR = STATE_DIR / "editions"
EDITOR_TOKEN = os.environ.get("VALHEIM_DASHBOARD_EDITOR_TOKEN", "")
UNIT = "valheim"
BACKUP_UNIT = "backup-valheim.service"
MAX_EVENTS = 200
MAX_DEATHS = 300
STATE_SCHEMA = 5
DEFAULT_DAY_LENGTH = 1800
WEEK_SECONDS = 7 * 86400
BOSSES = (
    ("defeated_eikthyr", "Eikthyr"),
    ("defeated_gdking", "The Elder"),
    ("defeated_bonemass", "Bonemass"),
    ("defeated_dragon", "Moder"),
    ("defeated_goblinking", "Yagluth"),
    ("defeated_queen", "The Queen"),
    ("defeated_fader", "Fader"),
)
ART_DIR = STATE_DIR / "art"
ART_NAMES = ("tree", "swamp", "deathsquito", "mountain", "boar", "building", "drowned")
CAUSES = (
    "tree", "troll", "greydwarf", "neck", "boar", "deathsquito", "mountain", "building",
    "drowned", "swamp", "raid", "boss", "friend", "stupidity", "mystery",
)

GAME_LINE = re.compile(r"^\d\d/\d\d/\d{4} \d\d:\d\d:\d\d: ")
STEAM_ID = re.compile(r"\b\d{17}\b")
NOISE = re.compile(
    r"Failed to place all|Placed location|Placed \d+ rooms|To place:|Available rooms:|placed \d+ doors"
    r"|Generating DG_|Dungeon loaded|Loading dungeon|Added \d+ locations|Got status changed"
    r"|Disposing socket|Set background loading|Socket closed by peer|Connections \d+$"
    r"|Checking for any blocked players|Worldgenerator version"
)

state_lock = threading.Lock()
download_lock = threading.Lock()


# The atlas is drawn by players, so it lives apart from the summary rebuilt from logs.
MAP_COLORS = {"ink", "meadows", "forest", "swamp", "mountain", "plains", "mistlands", "ashlands", "ocean", "danger"}
MAP_PINS = {"base", "portal", "boss", "dungeon", "trader", "ore", "ship", "death", "other"}
MAP_ID = re.compile(r"[A-Za-z0-9_-]{8,40}")
MAP_MAX_ITEMS = 20000
MAP_MAX_POINTS = 4000
MAP_MAX_BODY = 256 * 1024
MAP_LIMIT = 1e6
atlas = {"schema": 1, "rev": 0, "items": {}}
atlas_lock = threading.Lock()


# The editor is an AI agent outside this host. It reads /api/digest and posts each edition
# with a bearer token; the page falls back to its templates when there is none.
EDITION_MAX_BODY = 32 * 1024
EDITION_KEEP = 60
EDITION_TEXT = {"headline": 160, "story": 1500, "caption": 300, "editorial": 1200, "ad": 400, "forecast": 120}
EDITION_PARTS = {
    "pull_quote": {"words": 300, "who": 160},
    "wanted": {"name": 120, "crime": 200, "reward": 160},
}
EDITION_LISTS = {"letters": ({"text": 600, "signed": 160}, 1, 5), "stars": ({"name": 60, "text": 300}, 0, 40)}
edition = None
edition_lock = threading.Lock()


def edition_text(value, longest):
    if not isinstance(value, str) or not value.strip():
        raise ValueError
    return " ".join(value.split())[:longest]


def clean_edition(raw):
    if not isinstance(raw, dict):
        raise ValueError
    clean = {key: edition_text(raw.get(key), longest) for key, longest in EDITION_TEXT.items()}
    for key, fields in EDITION_PARTS.items():
        part = raw.get(key)
        if not isinstance(part, dict):
            raise ValueError
        clean[key] = {field: edition_text(part.get(field), longest) for field, longest in fields.items()}
    for key, (fields, fewest, most) in EDITION_LISTS.items():
        items = raw.get(key)
        if not isinstance(items, list) or not fewest <= len(items):
            raise ValueError
        clean[key] = [
            {field: edition_text(item.get(field) if isinstance(item, dict) else None, longest) for field, longest in fields.items()}
            for item in items[:most]
        ]
    # The Malayalam edition is optional, so an editor without one still publishes.
    malayalam = raw.get("malayalam")
    if isinstance(malayalam, dict) and malayalam.get("headline") and malayalam.get("story"):
        clean["malayalam"] = {"headline": edition_text(malayalam["headline"], 300), "story": edition_text(malayalam["story"], 3000)}
        notices = malayalam.get("obituaries")
        if isinstance(notices, list):
            clean["malayalam"]["obituaries"] = [
                {"name": edition_text(notice.get("name"), 60), "text": edition_text(notice.get("text"), 600)}
                for notice in notices[:8] if isinstance(notice, dict) and notice.get("name") and notice.get("text")
            ]
        proverb = malayalam.get("proverb")
        if isinstance(proverb, dict) and proverb.get("ml") and proverb.get("en"):
            clean["malayalam"]["proverb"] = {"ml": edition_text(proverb["ml"], 300), "en": edition_text(proverb["en"], 300)}
        sport = malayalam.get("sport")
        if isinstance(sport, dict) and sport.get("headline") and sport.get("story"):
            clean["malayalam"]["sport"] = {"headline": edition_text(sport["headline"], 300), "story": edition_text(sport["story"], 2000)}
            if sport.get("score"):
                clean["malayalam"]["sport"]["score"] = edition_text(sport["score"], 80)
        shows = malayalam.get("tv")
        if isinstance(shows, list):
            clean["malayalam"]["tv"] = [
                {"time": edition_text(show.get("time"), 10), "show": edition_text(show.get("show"), 120), "about": edition_text(show.get("about"), 300)}
                for show in shows[:8] if isinstance(show, dict) and show.get("time") and show.get("show") and show.get("about")
            ]
        ads = malayalam.get("matrimonials")
        if isinstance(ads, list):
            clean["malayalam"]["matrimonials"] = [edition_text(ad, 600) for ad in ads[:4] if isinstance(ad, str) and ad.strip()]
        if malayalam.get("cartoon_caption") and malayalam.get("cartoon") in ART_NAMES:
            clean["malayalam"]["cartoon"] = malayalam["cartoon"]
            clean["malayalam"]["cartoon_caption"] = edition_text(malayalam["cartoon_caption"], 200)
    if isinstance(raw.get("model"), str):
        clean["model"] = raw["model"][:60]
    return clean


def load_edition():
    global edition
    try:
        edition = json.loads(EDITION_FILE.read_text())
    except (OSError, ValueError):
        edition = None


def publish_edition(raw):
    global edition
    clean = clean_edition(raw)
    with edition_lock:
        number = (edition or {}).get("number", 0) + 1
        clean.update({"number": number, "ts": time.time()})
        EDITIONS_DIR.mkdir(parents=True, exist_ok=True)
        text = json.dumps(clean, ensure_ascii=False)
        (EDITIONS_DIR / f"{number:05d}.json").write_text(text)
        temporary = EDITION_FILE.with_suffix(".tmp")
        temporary.write_text(text)
        temporary.replace(EDITION_FILE)
        for old in sorted(EDITIONS_DIR.glob("*.json"))[:-EDITION_KEEP]:
            old.unlink(missing_ok=True)
        edition = clean
    return clean


def digest_duration(seconds):
    minutes = round(seconds / 60)
    if minutes < 60:
        return f"{minutes} min"
    return f"{minutes // 60} h {minutes % 60:02d} min"


def digest_text():
    """Plain-text facts for the editor, worked out in full so the model has nothing to calculate.

    [NEW] marks what happened since the last edition.
    """
    with edition_lock:
        previous = edition
    now = time.time()
    since = previous["ts"] if previous else now - 86400
    clock = lambda ts: time.strftime("%a %H:%M", time.localtime(ts))
    status = status_payload()
    with state_lock:
        history = [(death, state["verdicts"].get(death_key(death), {}).get("cause") or "unknown") for death in state["deaths"]]
        events = sorted(state["events"], key=lambda item: item["ts"])
    joins = {}
    for event in events:
        if event["kind"] == "player" and event["label"] == "Joined":
            joins.setdefault(event["name"], []).append(event["ts"])
    lines = [
        f"World '{WORLD_NAME}', in-game day {status['world_day']}. No-map run: players may not use the in-game map. "
        f"Server {status['state']}, version {status['version']}. Now: {clock(now)}.",
        "Last edition: " + (f"No. {previous['number']}, {clock(previous['ts'])}, headline '{previous['headline']}'. Do not repeat its jokes."
                            if previous else "none, this is the first edition."),
        "",
        "PLAYERS (all time). These lines are complete: a player died only of the causes listed for them.",
    ]
    by_player = {}
    for death, cause in history:
        by_player.setdefault(death["name"], []).append(f"{cause} ({clock(death['ts'])})")
    for entry in status["players"]:
        count = entry["deaths"]
        died = f"died {count} {'time' if count == 1 else 'times'}: " + ", ".join(by_player.get(entry["name"], [])) if count else "has never died"
        lines.append(
            f"- {entry['name']} {died}. Played {digest_duration(entry['played'])} in {entry['sessions']} sessions; "
            f"longest life {digest_duration(entry['longest_life'])}; "
            + ("ONLINE now." if entry["online"] else f"last seen {clock(entry['last_seen'])}.")
        )
    lines += ["", f"DEATHS, oldest first ({status['total_deaths']} in all; causes are recorded by players):"]
    for death, cause in history[-40:]:
        joined = [ts for ts in joins.get(death["name"], []) if ts <= death["ts"]]
        alive = f", {digest_duration(death['ts'] - joined[-1])} after joining at {clock(joined[-1])}" if joined else ""
        new = "  [NEW]" if death["ts"] >= since else ""
        lines.append(f"- {clock(death['ts'])}: {death['name']}, their death number {death['number']}, cause {cause}{alive}{new}")
    victims = {}
    for death, cause in history:
        if cause != "unknown":
            victims.setdefault(cause, []).append(f"{death['name']} {clock(death['ts'])}")
    if victims:
        ranked = sorted(victims.items(), key=lambda item: -len(item[1]))
        lines += ["", f"KILLERS, most dangerous first (the Wanted poster is for '{ranked[0][0]}'):"]
        lines += [f"- {cause}: {len(names)} {'kill' if len(names) == 1 else 'kills'} ({', '.join(names)})" for cause, names in ranked]
    slain = [boss["name"] + (" [NEW]" if boss["ts"] >= since else "") for boss in status["bosses"] if boss["ts"]]
    lines += ["", f"BOSSES defeated in this world: {', '.join(slain) or 'none yet'}."]
    wire = [f"- {clock(event['ts'])}: {event['text']}" for event in events if event["ts"] >= since and event["kind"] != "death"]
    lines += ["", f"WIRE since the last edition, oldest first ({len(wire)} lines):"] + (wire[-60:] or ["- nothing happened"])
    with atlas_lock:
        items = [item for item in atlas["items"].values() if not item.get("deleted")]
    marks = sorted((item for item in items if item.get("kind") in ("pin", "text")), key=lambda item: item.get("ts", 0))
    fresh = [item for item in items if item.get("ts", 0) >= since]
    strokes = sum(item.get("kind") == "stroke" for item in items)
    lines += ["", "SHARED ATLAS (players draw it by hand from memory; metres east and north of the spawn stones, "
              "negative means west or south): "
              f"{len(items)} marks in all ({len(marks)} pins and labels, {strokes} pen strokes); {len(fresh)} added since the last edition."]
    for item in marks[-40:]:
        label = item.get("label") or item.get("text") or ""
        new = "  [NEW]" if item.get("ts", 0) >= since else ""
        lines.append(f"- {item.get('icon') or 'text'} pin '{label}' by {item.get('by') or 'an anonymous cartographer'}, "
                     f"{round(item['x'])} E / {round(-item['y'])} N{new}")
    lines += ["", f"CARTOON PICTURES the editor may choose from: {', '.join(ART_NAMES)}."]
    return "\n".join(lines) + "\n"


def load_atlas():
    try:
        loaded = json.loads(MAP_FILE.read_text())
    except (OSError, ValueError):
        return
    if loaded.get("schema") == 1:
        atlas.update(loaded)


def save_atlas():
    data = json.dumps(atlas, separators=(",", ":"))
    temporary = MAP_FILE.with_suffix(".tmp")
    temporary.write_text(data)
    temporary.replace(MAP_FILE)


def map_number(value):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
        raise ValueError("not a number")
    if abs(value) > MAP_LIMIT:
        raise ValueError("off the edge of the world")
    return round(float(value), 1)


def map_text(value, longest, required=False):
    text = " ".join(str(value or "").split())[:longest]
    if required and not text:
        raise ValueError("empty text")
    return text


def clean_map_item(raw):
    """Return a stored copy of one drawn item, or raise ValueError."""
    if not isinstance(raw, dict) or not MAP_ID.fullmatch(str(raw.get("id", ""))):
        raise ValueError("bad id")
    item = {"id": raw["id"], "kind": raw.get("kind"), "by": map_text(raw.get("by"), 32)}
    if item["kind"] == "stroke":
        points = raw.get("points")
        if not isinstance(points, list) or not 1 <= len(points) <= MAP_MAX_POINTS:
            raise ValueError("bad points")
        item["points"] = [[map_number(p[0]), map_number(p[1])] for p in points if isinstance(p, list) and len(p) == 2]
        if len(item["points"]) != len(points) or raw.get("color") not in MAP_COLORS:
            raise ValueError("bad stroke")
        item["color"] = raw["color"]
        item["width"] = map_number(raw.get("width"))
        if not 0 < item["width"] <= 100000:
            raise ValueError("bad width")
    elif item["kind"] in ("pin", "text"):
        item["x"], item["y"] = map_number(raw.get("x")), map_number(raw.get("y"))
        if item["kind"] == "pin":
            if raw.get("icon") not in MAP_PINS:
                raise ValueError("bad pin")
            item["icon"] = raw["icon"]
            item["label"] = map_text(raw.get("label"), 48)
        else:
            item["label"] = map_text(raw.get("label"), 48, required=True)
            item["size"] = map_number(raw.get("size"))
            if not 0 < item["size"] <= 100000:
                raise ValueError("bad size")
    else:
        raise ValueError("bad kind")
    return item


def change_map(body):
    """Apply one add or delete from a player. Returns (status, payload)."""
    op = body.get("op") if isinstance(body, dict) else None
    with atlas_lock:
        items = atlas["items"]
        if op == "add":
            try:
                item = clean_map_item(body.get("item"))
            except (ValueError, TypeError, IndexError):
                return 400, {"error": "That drawing could not be read."}
            if item["id"] in items:
                return 200, {"ok": True, "rev": items[item["id"]]["rev"]}
            if sum(1 for entry in items.values() if not entry.get("deleted")) >= MAP_MAX_ITEMS:
                return 409, {"error": "The atlas is full. Erase something first."}
        elif op == "delete":
            target = items.get(str(body.get("id")))
            if not target or target.get("deleted"):
                return 200, {"ok": True, "rev": atlas["rev"]}
            item = {"id": target["id"], "deleted": True}
        else:
            return 400, {"error": "Send an add or a delete."}
        atlas["rev"] += 1
        item.update(rev=atlas["rev"], ts=time.time())
        items[item["id"]] = item
        save_atlas()
        return 200, {"ok": True, "rev": atlas["rev"]}


def map_payload(query):
    try:
        since = int(query.get("since", ["0"])[0])
    except ValueError:
        since = 0
    with atlas_lock:
        items = [item for item in atlas["items"].values() if item["rev"] > since and (since or not item.get("deleted"))]
        return {"rev": atlas["rev"], "items": items}


def empty_state():
    return {
        "schema": STATE_SCHEMA, "cursor": None, "players": {}, "sessions": {}, "events": [], "deaths": [],
        "next_death": 1, "version": "", "ready_at": 0, "verdicts": {}, "bosses": {},
        "world_time": 0.0, "world_day": None, "save_number": None,
        "day_length": DEFAULT_DAY_LENGTH, "ignored": sorted(IGNORED_PLAYERS),
    }


state = empty_state()
state_dirty = False
cpu_percent = 0.0


def load_state():
    try:
        loaded = json.loads(STATE_FILE.read_text())
    except (OSError, ValueError):
        return
    if loaded.get("schema") == STATE_SCHEMA and loaded.get("ignored") == sorted(IGNORED_PLAYERS):
        state.update(loaded)
        return
    # An older summary has different fields or players, so rebuild it from the journal.
    # Keep what only players can provide.
    state["verdicts"] = dict(loaded.get("verdicts", {}))
    for death in loaded.get("deaths", []):
        if death.get("cause"):
            state["verdicts"].setdefault(death_key(death), {})["cause"] = death["cause"]


def death_key(death):
    return f"{death['name']}#{death['number']}"


def save_state():
    global state_dirty
    with state_lock:
        if not state_dirty:
            return
        data = json.dumps(state)
        state_dirty = False
    temporary = STATE_FILE.with_suffix(".tmp")
    temporary.write_text(data)
    temporary.replace(STATE_FILE)


def add_event(ts, kind, label, text, **extra):
    state["events"].append({"ts": ts, "kind": kind, "label": label, "text": text, **extra})
    del state["events"][:-MAX_EVENTS]


def player(name):
    if name not in state["players"]:
        state["players"][name] = {
            "deaths": 0, "online": False, "last_seen": 0, "first_seen": 0, "joined_at": 0, "played": 0,
            "sessions": 0, "session_deaths": 0, "worst_session": 0, "alive_since": 0, "life_bank": 0,
            "longest_life": 0, "streak_days": 0, "best_streak": 0,
        }
    return state["players"][name]


def end_session(name, ts):
    record = player(name)
    if record["joined_at"]:
        record["played"] += max(0, ts - record["joined_at"])
    if record["alive_since"]:
        record["life_bank"] += max(0, ts - record["alive_since"])
    record.update(online=False, last_seen=ts, joined_at=0, alive_since=0)


def clear_sessions(ts):
    for name in state["sessions"].values():
        if name:
            end_session(name, ts)
    state["sessions"] = {}


def process_line(message, ts):
    """Update the stored summary from one game log line."""
    if not GAME_LINE.match(message):
        return
    body = GAME_LINE.sub("", message).strip()
    sessions = state["sessions"]

    if match := re.match(r"Valheim version: l-(\S+)", body):
        state["version"] = match.group(1)
        state["ready_at"] = 0
        clear_sessions(ts)
    elif body == "Game server connected":
        state["ready_at"] = ts
        add_event(ts, "server", "Server", "Server started and ready")
    elif body == "Shutting down":
        state["ready_at"] = 0
        clear_sessions(ts)
        add_event(ts, "server", "Server", "Server stopped")
    elif match := re.match(r"Got connection SteamID (\d+)", body):
        sessions[match.group(1)] = None
    elif match := re.match(r"Peer (\S+) has wrong password", body):
        sessions.pop(match.group(1), None)
        add_event(ts, "player", "Failed", "Someone tried a wrong password")
    elif match := re.match(r"Got character ZDOID from (.+) : (-?\d+):(\d+)$", body):
        name = match.group(1)
        if name in IGNORED_PLAYERS:
            return
        if name not in sessions.values():
            waiting = [steam for steam, known in sessions.items() if known is None]
            if waiting:
                sessions[waiting[-1]] = name
            record = player(name)
            record.update(joined_at=ts, session_deaths=0, alive_since=ts, sessions=record["sessions"] + 1)
            record["first_seen"] = record["first_seen"] or ts
            add_event(ts, "player", "Joined", f"{name} joined", name=name)
        record = player(name)
        record.update(online=True, last_seen=ts)
        if match.group(2) == "0":
            record["deaths"] += 1
            record["session_deaths"] += 1
            life = record["life_bank"] + max(0, ts - (record["alive_since"] or ts))
            record.update(longest_life=max(record["longest_life"], life), life_bank=0, alive_since=ts, streak_days=0)
            record["worst_session"] = max(record["worst_session"], record["session_deaths"])
            death_id = state["next_death"]
            state["next_death"] += 1
            state["deaths"].append({"id": death_id, "name": name, "ts": ts, "number": record["deaths"]})
            del state["deaths"][:-MAX_DEATHS]
            add_event(ts, "death", "Death", f"{name} died", name=name, death_id=death_id)
    elif match := re.match(r"Closing socket (\d+)", body):
        steam = match.group(1)
        if steam in sessions:
            name = sessions.pop(steam)
            if name:
                end_session(name, ts)
                add_event(ts, "player", "Left", f"{name} left", name=name)
    elif match := re.match(r"Time [\d.]+, day:(\d+)\s+nextm:([\d.]+)", body):
        # Sleeping skips to morning, and this line reveals the real day length.
        morning = float(match.group(2))
        length = morning / (int(match.group(1)) + 1.15)
        if 300 <= length <= 7200:
            state["day_length"] = round(length)
        state["world_time"] = max(state["world_time"], morning)
    elif match := re.match(r"Random event set:(\S+)", body):
        add_event(ts, "raid", "Raid", f"Raid started: {match.group(1)}", raid=match.group(1))


def set_verdict(death_id, cause):
    """Record the cause of death that players chose. Returns False if the death is unknown."""
    global state_dirty
    with state_lock:
        for death in state["deaths"]:
            if death["id"] == death_id:
                state["verdicts"].setdefault(death_key(death), {})["cause"] = cause
                state_dirty = True
                return True
    return False


def advance_world(seconds):
    """Keep game time moving between saves. It stops when nobody is connected."""
    global state_dirty
    with state_lock:
        if not any(state["sessions"].values()):
            return
        state["world_time"] += seconds
        update_world_day()
        state_dirty = True


def update_world_day():
    """Credit online players with a survived day when the world day changes."""
    day = int(state["world_time"] / state["day_length"])
    known = state["world_day"]
    state["world_day"] = day if known is None else max(known, day)
    if known is not None and day > known:
        for name in state["sessions"].values():
            if name:
                record = player(name)
                record["streak_days"] += 1
                record["best_streak"] = max(record["best_streak"], record["streak_days"])


def parse_world_save(data):
    """Return game time and the boss keys from a world .db2 file."""
    _version, net_time, length = struct.unpack_from("<idi", data)
    zones = gzip.decompress(data[16:16 + length])
    keys = {match.decode() for match in re.findall(rb"defeated_[a-z]+", zones)}
    return net_time, keys


def read_world_save():
    """Pick up game time and boss kills whenever the game writes a new save."""
    global state_dirty
    number = latest_save()[0]
    with state_lock:
        if number is None or number == state["save_number"]:
            return
    net_time, keys = parse_world_save((world_dir() / f"_main.{number}.db2").read_bytes())
    now = time.time()
    with state_lock:
        state["save_number"] = number
        state["world_time"] = net_time
        update_world_day()
        for key, boss in BOSSES:
            if key in keys and key not in state["bosses"]:
                state["bosses"][key] = now
                add_event(now, "boss", "Boss", f"{boss} defeated", boss=boss)
        state_dirty = True


def journal_field(value):
    if isinstance(value, list):
        return bytes(value).decode("utf-8", "replace")
    return value or ""


def follow_journal():
    """Keep the summary current, resuming from the last line already read."""
    global state_dirty
    while True:
        command = ["journalctl", "-u", UNIT, "-o", "json", "-f", "--no-pager"]
        if state["cursor"]:
            command.append(f"--after-cursor={state['cursor']}")
        else:
            command += ["-n", "all"]
        process = subprocess.Popen(command, stdout=subprocess.PIPE, text=True, errors="replace")
        for raw in process.stdout:
            try:
                entry = json.loads(raw)
            except ValueError:
                continue
            ts = int(entry.get("__REALTIME_TIMESTAMP", 0)) / 1_000_000
            with state_lock:
                process_line(journal_field(entry.get("MESSAGE")), ts)
                state["cursor"] = entry.get("__CURSOR")
                state_dirty = True
        process.wait()
        if process.returncode:
            # A cursor from a vacuumed journal makes journalctl fail.
            with state_lock:
                state["cursor"] = None
        time.sleep(5)


def background_work():
    global cpu_percent
    previous = read_cpu()
    try:
        read_world_save()
    except (OSError, ValueError, EOFError, struct.error) as error:
        print(f"Could not read the world save: {type(error).__name__}", flush=True)
    while True:
        time.sleep(15)
        current = read_cpu()
        total = current[0] - previous[0]
        if total > 0:
            cpu_percent = 100 * (1 - (current[1] - previous[1]) / total)
        previous = current
        advance_world(15)
        try:
            read_world_save()
        except (OSError, ValueError, EOFError, struct.error) as error:
            print(f"Could not read the world save: {type(error).__name__}", flush=True)
        try:
            save_state()
        except OSError as error:
            print(f"Could not save state: {error}", flush=True)


def read_cpu():
    fields = [int(value) for value in Path("/proc/stat").read_text().splitlines()[0].split()[1:]]
    return sum(fields), fields[3] + fields[4]


def read_memory():
    values = {}
    for line in Path("/proc/meminfo").read_text().splitlines():
        key, value = line.split(":", 1)
        values[key] = int(value.split()[0]) * 1024
    return values["MemTotal"] - values["MemAvailable"], values["MemTotal"]


def unit_properties(unit, *names):
    result = subprocess.run(
        ["systemctl", "show", unit, "--timestamp=unix", "--no-pager"]
        + [f"--property={name}" for name in names],
        capture_output=True,
        text=True,
        timeout=10,
        check=False,
    )
    return dict(line.split("=", 1) for line in result.stdout.splitlines() if "=" in line)


def unix_time(value):
    return float(value[1:]) if value and value.startswith("@") else 0


def world_dir():
    return WORLDS_DIR / WORLD_NAME


def latest_save():
    """Return the number and time of the newest complete save."""
    newest = (None, 0)
    try:
        for path in world_dir().glob("_main.*.ok"):
            number = int(path.name.split(".")[1])
            if newest[0] is None or number > newest[0]:
                newest = (number, path.stat().st_mtime)
    except (OSError, ValueError):
        pass
    return newest


def world_size():
    try:
        return sum(path.stat().st_size for path in world_dir().iterdir() if path.is_file())
    except OSError:
        return 0


def status_payload():
    game = unit_properties(UNIT, "ActiveState", "ActiveEnterTimestamp")
    backup = unit_properties(BACKUP_UNIT, "ExecMainExitTimestamp", "Result")
    used, total = read_memory()
    active_since = unix_time(game.get("ActiveEnterTimestamp"))
    with state_lock:
        ready = state["ready_at"] >= active_since > 0
        now = time.time()
        players = []
        for name, details in state["players"].items():
            played = details["played"]
            life = details["life_bank"]
            if details["online"] and details["joined_at"]:
                played += max(0, now - details["joined_at"])
            if details["online"] and details["alive_since"]:
                life += max(0, now - details["alive_since"])
            players.append({
                **details, "name": name, "played": played, "current_life": life,
                "longest_life": max(details["longest_life"], life),
            })
        deaths = []
        tally = {}
        causes_by_player = {}
        week = {"deaths": {}, "causes": {}}
        for death in reversed(state["deaths"]):
            verdict = state["verdicts"].get(death_key(death), {})
            cause = verdict.get("cause")
            recent = now - death["ts"] < WEEK_SECONDS
            if recent:
                week["deaths"][death["name"]] = week["deaths"].get(death["name"], 0) + 1
            if cause:
                tally[cause] = tally.get(cause, 0) + 1
                mine = causes_by_player.setdefault(death["name"], {})
                mine[cause] = mine.get(cause, 0) + 1
                if recent:
                    week["causes"][cause] = week["causes"].get(cause, 0) + 1
            if len(deaths) < 30:
                deaths.append({**death, "cause": verdict.get("cause")})
        for entry in players:
            entry["causes"] = causes_by_player.get(entry["name"], {})
        total_deaths = sum(details["deaths"] for details in state["players"].values())
        events = list(reversed(sorted(state["events"], key=lambda item: item["ts"])[-60:]))
        bosses = [{"key": key, "name": boss, "ts": state["bosses"].get(key, 0)} for key, boss in BOSSES]
        world_day = state["world_day"]
        version = state["version"]
    if game.get("ActiveState") != "active":
        server_state = "offline"
    else:
        server_state = "online" if ready else "starting"
    players.sort(key=lambda item: (not item["online"], -item["deaths"], item["name"].lower()))
    return {
        "state": server_state,
        "active_since": active_since,
        "version": version,
        "cpu": round(cpu_percent),
        "memory_used": used,
        "memory_total": total,
        "players": players,
        "events": events,
        "deaths": deaths,
        "total_deaths": total_deaths,
        "cause_tally": tally,
        "bosses": bosses,
        "week": week,
        "world_day": world_day,
        "causes": CAUSES,
        "world": WORLD_NAME,
        "seed": WORLD_SEED,
        "game_port": GAME_PORT,
        "last_save": latest_save()[1],
        "world_size": world_size(),
        "last_backup": unix_time(backup.get("ExecMainExitTimestamp")),
        "backup_ok": backup.get("Result", "success") == "success",
        "now": time.time(),
        "edition": edition,
    }


def clean_line(line):
    line = STEAM_ID.sub("<hidden>", line)
    if SERVER_PASSWORD:
        line = re.sub(rf"(?<![\w]){re.escape(SERVER_PASSWORD)}(?![\w])", "<hidden>", line)
    return line


def is_noise(line):
    return not GAME_LINE.match(line) or bool(NOISE.search(line))


def read_logs(*selection):
    result = subprocess.run(
        ["journalctl", "-u", UNIT, "-o", "cat", "--no-pager", *selection],
        capture_output=True,
        text=True,
        errors="replace",
        timeout=30,
        check=False,
    )
    return result.stdout.splitlines()


def logs_payload(query):
    search = query.get("q", [""])[0].lower()
    include_noise = query.get("noise", ["0"])[0] == "1"
    lines = []
    for line in read_logs("-n", "5000"):
        noise = is_noise(line)
        if noise and not include_noise:
            continue
        line = clean_line(line)
        if search and search not in line.lower():
            continue
        lines.append({"text": line, "noise": noise})
    return {"lines": lines[-500:]}


def build_world_archive():
    """Archive the newest save, retrying if the game saves during the copy."""
    for _ in range(3):
        number, _saved = latest_save()
        if number is None:
            return None
        archive = tempfile.NamedTemporaryFile(prefix="world-", suffix=".tar.gz")
        try:
            with tarfile.open(fileobj=archive, mode="w:gz", compresslevel=6) as tar:
                tar.add(world_dir(), arcname=WORLD_NAME)
        except OSError:
            archive.close()
            time.sleep(5)
            continue
        if latest_save()[0] == number:
            archive.seek(0)
            return archive
        archive.close()
        time.sleep(5)
    return None


class Handler(BaseHTTPRequestHandler):
    server_version = "ValheimDashboard"
    sys_version = ""

    def log_message(self, *_args):
        pass

    def send_bytes(self, body, content_type, status=200, filename=None):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        if filename:
            self.send_header("Content-Disposition", f'attachment; filename="{filename}"')
        self.end_headers()
        self.wfile.write(body)

    def send_json(self, payload, status=200):
        self.send_bytes(json.dumps(payload).encode(), "application/json", status)

    def send_world(self):
        if not download_lock.acquire(blocking=False):
            self.send_json({"error": "Another download is being prepared. Try again in a minute."}, 429)
            return
        try:
            archive = build_world_archive()
            if archive is None:
                self.send_json({"error": "No complete save is available yet. Try again in a minute."}, 503)
                return
            with archive:
                archive.seek(0, os.SEEK_END)
                size = archive.tell()
                archive.seek(0)
                stamp = time.strftime("%Y-%m-%d-%H%M", time.localtime(latest_save()[1]))
                self.send_response(200)
                self.send_header("Content-Type", "application/gzip")
                self.send_header("Content-Length", str(size))
                self.send_header("Cache-Control", "no-store")
                self.send_header(
                    "Content-Disposition", f'attachment; filename="{WORLD_NAME}-{stamp}.tar.gz"'
                )
                self.end_headers()
                while chunk := archive.read(1024 * 1024):
                    self.wfile.write(chunk)
        finally:
            download_lock.release()

    def do_POST(self):
        path = urlparse(self.path).path
        if path == "/api/map":
            self.post_map()
            return
        if path == "/api/edition":
            self.post_edition()
            return
        if path != "/api/verdict":
            self.send_json({"error": "Not found"}, 404)
            return
        # Requiring JSON stops other websites from posting here with a plain form.
        length = int(self.headers.get("Content-Length") or 0)
        if self.headers.get("Content-Type") != "application/json" or not 0 < length <= 1024:
            self.send_json({"error": "Send a small JSON body."}, 400)
            return
        try:
            body = json.loads(self.rfile.read(length))
            death_id, cause = body["id"], body["cause"]
        except (ValueError, KeyError, TypeError):
            self.send_json({"error": "Send an id and a cause."}, 400)
            return
        if cause not in CAUSES or not isinstance(death_id, int):
            self.send_json({"error": "That is not a known cause of death."}, 400)
            return
        if not set_verdict(death_id, cause):
            self.send_json({"error": "That death is not on record."}, 404)
            return
        self.send_json({"ok": True})

    def post_map(self):
        length = int(self.headers.get("Content-Length") or 0)
        if self.headers.get("Content-Type") != "application/json" or not 0 < length <= MAP_MAX_BODY:
            self.send_json({"error": "Send a JSON body under 256 KB."}, 400)
            return
        try:
            body = json.loads(self.rfile.read(length))
        except ValueError:
            self.send_json({"error": "That was not JSON."}, 400)
            return
        status, payload = change_map(body)
        self.send_json(payload, status)

    def post_edition(self):
        supplied = self.headers.get("Authorization", "").removeprefix("Bearer ")
        if not EDITOR_TOKEN or not hmac.compare_digest(supplied.encode(), EDITOR_TOKEN.encode()):
            self.send_json({"error": "Only the editor can publish."}, 403)
            return
        length = int(self.headers.get("Content-Length") or 0)
        if self.headers.get("Content-Type") != "application/json" or not 0 < length <= EDITION_MAX_BODY:
            self.send_json({"error": "Send a JSON edition under 32 KB."}, 400)
            return
        try:
            published = publish_edition(json.loads(self.rfile.read(length)))
        except ValueError:
            self.send_json({"error": "The edition is missing a section or has an empty one."}, 400)
            return
        self.send_json({"ok": True, "number": published["number"]})

    def do_GET(self):
        url = urlparse(self.path)
        try:
            if url.path == "/":
                self.send_bytes(INDEX_FILE.read_bytes(), "text/html; charset=utf-8")
            elif url.path == "/map":
                self.send_bytes(MAP_PAGE.read_bytes(), "text/html; charset=utf-8")
            elif url.path == "/atlas.js":
                self.send_bytes(ATLAS_SCRIPT.read_bytes(), "text/javascript; charset=utf-8")
            elif url.path == "/api/map":
                self.send_json(map_payload(parse_qs(url.query)))
            elif url.path == "/api/status":
                self.send_json(status_payload())
            elif url.path == "/api/digest":
                self.send_bytes(digest_text().encode(), "text/plain; charset=utf-8")
            elif url.path == "/api/logs":
                self.send_json(logs_payload(parse_qs(url.query)))
            elif (match := re.fullmatch(r"/art/([a-z]+)\.jpg", url.path)) and match.group(1) in ART_NAMES:
                path = ART_DIR / f"{match.group(1)}.jpg"
                if path.is_file():
                    self.send_bytes(path.read_bytes(), "image/jpeg")
                else:
                    self.send_json({"error": "Not found"}, 404)
            elif url.path == "/api/password":
                self.send_json({"password": SERVER_PASSWORD})
            elif url.path == "/download/world":
                self.send_world()
            elif url.path == "/download/logs":
                lines = [clean_line(line) for line in read_logs("--since", "-24h")]
                self.send_bytes(
                    "\n".join(lines).encode(), "text/plain; charset=utf-8", filename=f"{WORLD_NAME}-logs.txt"
                )
            else:
                self.send_json({"error": "Not found"}, 404)
        except (BrokenPipeError, ConnectionResetError):
            pass


def main():
    load_state()
    load_atlas()
    load_edition()
    threading.Thread(target=follow_journal, daemon=True).start()
    threading.Thread(target=background_work, daemon=True).start()
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main()

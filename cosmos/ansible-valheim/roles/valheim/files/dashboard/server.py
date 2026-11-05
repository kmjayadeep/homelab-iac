#!/usr/bin/env python3
"""Small read-only status page for one Valheim dedicated server."""

import json
import os
import re
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
STATE_FILE = STATE_DIR / "state.json"
INDEX_FILE = Path(__file__).with_name("index.html")
UNIT = "valheim"
BACKUP_UNIT = "backup-valheim.service"
MAX_EVENTS = 200

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
state = {"cursor": None, "players": {}, "sessions": {}, "events": [], "version": "", "ready_at": 0}
state_dirty = False
cpu_percent = 0.0


def load_state():
    try:
        loaded = json.loads(STATE_FILE.read_text())
    except (OSError, ValueError):
        return
    state.update(loaded)


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


def add_event(ts, kind, label, text):
    state["events"].append({"ts": ts, "kind": kind, "label": label, "text": text})
    del state["events"][:-MAX_EVENTS]


def player(name):
    return state["players"].setdefault(name, {"deaths": 0, "online": False, "last_seen": 0})


def clear_sessions(ts):
    for name in state["sessions"].values():
        if name:
            player(name).update(online=False, last_seen=ts)
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
        if name not in sessions.values():
            waiting = [steam for steam, known in sessions.items() if known is None]
            if waiting:
                sessions[waiting[-1]] = name
            add_event(ts, "player", "Joined", f"{name} joined")
        record = player(name)
        record.update(online=True, last_seen=ts)
        if match.group(2) == "0":
            record["deaths"] += 1
            add_event(ts, "death", "Death", f"{name} died (death {record['deaths']})")
    elif match := re.match(r"Closing socket (\d+)", body):
        steam = match.group(1)
        if steam in sessions:
            name = sessions.pop(steam)
            if name:
                player(name).update(online=False, last_seen=ts)
                add_event(ts, "player", "Left", f"{name} left")
    elif match := re.match(r"Random event set:(\S+)", body):
        add_event(ts, "raid", "Raid", f"Raid started: {match.group(1)}")


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
    while True:
        time.sleep(15)
        current = read_cpu()
        total = current[0] - previous[0]
        if total > 0:
            cpu_percent = 100 * (1 - (current[1] - previous[1]) / total)
        previous = current
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
        players = [{"name": name, **details} for name, details in state["players"].items()]
        events = list(reversed(state["events"][-60:]))
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
        "world": WORLD_NAME,
        "seed": WORLD_SEED,
        "game_port": GAME_PORT,
        "last_save": latest_save()[1],
        "world_size": world_size(),
        "last_backup": unix_time(backup.get("ExecMainExitTimestamp")),
        "backup_ok": backup.get("Result", "success") == "success",
        "now": time.time(),
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

    def do_GET(self):
        url = urlparse(self.path)
        try:
            if url.path == "/":
                self.send_bytes(INDEX_FILE.read_bytes(), "text/html; charset=utf-8")
            elif url.path == "/api/status":
                self.send_json(status_payload())
            elif url.path == "/api/logs":
                self.send_json(logs_payload(parse_qs(url.query)))
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
    threading.Thread(target=follow_journal, daemon=True).start()
    threading.Thread(target=background_work, daemon=True).start()
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main()

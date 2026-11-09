#!/usr/bin/env python3
"""Compare the Valheim nomap atlas and real builds with the world save, without spoilers."""
import argparse
import collections
import glob
import json
import math
import os
import re
import shutil
import struct
import sys
import tarfile
import tempfile
import urllib.request
import zlib

DEFAULT_HOST = "valheim-nomap.cosmos.cboxlab.com"
SEA_LEVEL = 30.0
SENSITIVE_RADIUS = 300.0

TRADERS = {"Vendor_BlackForest": "haldor", "Hildir_camp": "hildir", "BogWitch_Camp": "bog_witch"}
BOSSES = {
    "Eikthyrnir": "boss1_eikthyr",
    "GDKing": "boss2_elder",
    "Bonemass": "boss3_bonemass",
    "Dragonqueen": "boss4_moder",
    "GoblinKing": "boss5_yagluth",
    "Mistlands_DvergrBossEntrance1": "boss6_queen",
    "FaderLocation": "boss7_fader",
}
BUILDS = {
    "piece_workbench": "workbench",
    "forge": "forge",
    "smelter": "smelter",
    "charcoal_kiln": "kiln",
    "guard_stone": "ward",
    "bed": "bed",
    "piece_bed02": "bed",
    "hearth": "hearth",
}
COMPASS = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]


def stable_hash(text):
    a = b = 5381
    i = 0
    while i < len(text):
        a = (((a << 5) + a) ^ ord(text[i])) & 0xFFFFFFFF
        if i == len(text) - 1:
            break
        b = (((b << 5) + b) ^ ord(text[i + 1])) & 0xFFFFFFFF
        i += 2
    value = (a + b * 1566083941) & 0xFFFFFFFF
    return value - (1 << 32) if value >= 1 << 31 else value


def packed(text):
    return struct.pack("<i", stable_hash(text))


def die(message):
    sys.exit(f"map_guide: {message}")


def fetch(host, workdir):
    with urllib.request.urlopen(f"http://{host}:8000/api/map", timeout=30) as reply:
        atlas = json.load(reply)
    archive = os.path.join(workdir, "world.tar.gz")
    with urllib.request.urlopen(f"http://{host}:8000/download/world", timeout=180) as reply:
        name = reply.headers.get_filename() or "unknown"
        with open(archive, "wb") as out:
            shutil.copyfileobj(reply, out)
    extracted = os.path.join(workdir, "world")
    os.mkdir(extracted)
    with tarfile.open(archive) as tar:
        tar.extractall(extracted, filter="data")
    return atlas, extracted, name


def latest_main(root):
    found = {}
    for path in glob.glob(os.path.join(root, "**", "_main.*.db2"), recursive=True):
        number = int(re.search(r"_main\.(\d+)\.db2$", path).group(1))
        if os.path.exists(path[:-3] + "ok"):
            found[number] = path
    if not found:
        die("no complete _main.*.db2 in the save; the save format may have changed")
    raw = open(found[max(found)], "rb").read()
    start = raw.find(b"\x1f\x8b\x08")
    if start < 0:
        die("no compressed block in the main save; the save format may have changed")
    return zlib.decompressobj(31).decompress(raw[start:])


def latest_chunks(root):
    chosen = {}
    for path in glob.glob(os.path.join(root, "**", "*.chunk"), recursive=True):
        match = re.match(r"(.+)__(\d+)_(\d+)\.chunk$", os.path.basename(path))
        if match:
            key, version = (match[1], match[2]), int(match[3])
            if key not in chosen or version > chosen[key][0]:
                chosen[key] = (version, path)
    return [open(path, "rb").read() for _, path in chosen.values()]


def record(data, offset):
    """Read one location record: name hash, x, y, z, generated flag."""
    if offset < 0 or offset + 17 > len(data):
        return None
    name, x, y, z, generated = struct.unpack_from("<ifffB", data, offset)
    if generated > 1 or x != x or y != y or z != z:
        return None
    if abs(x) > 11000 or abs(z) > 11000 or not -100 < y < 3000:
        return None
    return name, x, y, z, generated


def read_locations(data):
    for match in re.finditer(re.escape(packed("StartTemple")), data):
        first = match.start()
        if not record(data, first):
            continue
        while record(data, first - 17):
            first -= 17
        end = match.start()
        while record(data, end):
            end += 17
        if (end - first) / 17 >= 1000:
            return [record(data, offset) for offset in range(first, end, 17)]
    die("location table not found; the save format may have changed")


def read_builds(chunks, spawn):
    portal_hash = packed("portal_wood")
    tag_hash = packed("tag")
    portals, builds = [], []
    for data in chunks:
        offsets = [m.start() for m in re.finditer(re.escape(portal_hash), data)]
        for index, offset in enumerate(offsets):
            if offset < 12:
                continue
            x, y, z = struct.unpack_from("<fff", data, offset - 12)
            limit = offsets[index + 1] - 12 if index + 1 < len(offsets) else offset + 400
            found = data.find(tag_hash, offset, limit)
            tag = None
            if found >= 0:
                length = data[found + 4]
                tag = data[found + 5 : found + 5 + length].decode("utf-8", "replace")
            portals.append({"tag": tag or "(untagged)", "x": x - spawn[0], "z": z - spawn[1], "y": y})
        for prefab, label in BUILDS.items():
            for match in re.finditer(re.escape(packed(prefab)), data):
                if match.start() >= 12:
                    x, _, z = struct.unpack_from("<fff", data, match.start() - 12)
                    if abs(x) < 11000 and abs(z) < 11000:
                        builds.append((label, x - spawn[0], z - spawn[1]))
    return portals, builds


def compass(east, north):
    angle = math.degrees(math.atan2(east, north)) % 360
    return COMPASS[int((angle + 11.25) // 22.5) % 16]


def turn_between(a, b):
    angle = math.degrees(math.atan2(a[0], a[1]) - math.atan2(b[0], b[1]))
    return abs((angle + 180) % 360 - 180)


def build_sites(locations, spawn):
    names = {stable_hash(n): label for n, label in {**TRADERS, **BOSSES}.items()}
    sites = []
    for name, x, y, z, generated in locations:
        if name in names:
            sites.append({"name": names[name], "x": x - spawn[0], "z": z - spawn[1], "y": y, "generated": bool(generated)})
    return sites


def nearest(site, places):
    return min(places, key=lambda p: math.hypot(site["x"] - p["x"], site["z"] - p["z"]))


def distance(a, b):
    return math.hypot(a["x"] - b["x"], a["z"] - b["z"])


def world_keys(data):
    keys = sorted({m.decode() for m in re.findall(rb"(?:defeated_|killed|Hildir)[A-Za-z0-9_]{2,30}", data)})
    return keys


def far_end(portals):
    return max(portals, key=lambda p: math.hypot(p["x"], p["z"]))


def report(atlas, snapshot, locations, data, portals, builds, sites, reveal):
    print(f"snapshot: {snapshot}")
    print(f"locations: {len(locations)}  portals: {len(portals)}  builds: {len(builds)}")
    print(f"world keys: {', '.join(world_keys(data)) or 'none'}")

    build_places = [{"tag": label, "x": x, "z": z} for label, x, z in builds]
    all_places = portals + build_places
    pairs = collections.Counter(p["tag"] for p in portals)

    print("\nsites, nearest instance of each:")
    best = {}
    for site in sites:
        gap = distance(site, nearest(site, all_places))
        if site["name"] not in best or gap < best[site["name"]][0]:
            best[site["name"]] = (gap, site)
    for gap, site in sorted(best.values(), key=lambda row: row[0]):
        place = nearest(site, all_places)
        portal = nearest(site, portals)
        where = f"  at x={site['x']:.0f} z={site['z']:.0f}" if reveal else ""
        print(
            f"  {site['name']}: {gap:.0f} m from {place['tag']}; nearest portal {portal['tag']} {distance(site, portal):.0f} m;"
            f" generated: {'yes' if site['generated'] else 'no'}{where}"
        )

    traders = [site for site in sites if site["name"] in TRADERS.values()]
    pins = {
        item["label"].lower(): item
        for item in atlas["items"]
        if item.get("kind") == "pin" and item.get("icon") == "portal" and item.get("label")
    }
    print("\nportals (true position from spawn, then how the atlas draws it):")
    groups = collections.defaultdict(list)
    for portal in portals:
        groups[portal["tag"]].append(portal)
    for tag, members in sorted(groups.items()):
        end = far_end(members)
        true_distance = math.hypot(end["x"], end["z"])
        sensitive = any(distance(end, trader) <= SENSITIVE_RADIUS for trader in traders)
        line = f"  {tag}: {true_distance:.0f} m"
        if not sensitive or reveal:
            line += f" {compass(end['x'], end['z'])}"
        else:
            line += " (direction withheld: near a trader)"
        if reveal:
            line += f" at x={end['x']:.0f} z={end['z']:.0f}"
        line += f"; paired: {'yes' if pairs[tag] > 1 else 'no'}"
        pin = pins.get(tag.lower())
        if pin and true_distance < 100:
            line += "; pinned on the atlas, but only its spawn end exists, so the pin can't be compared"
        elif pin:
            east, north = pin["x"], -pin["y"]
            drawn = math.hypot(east, north)
            line += f"; drawn {drawn:.0f} m {compass(east, north)}, {drawn / max(true_distance, 1):.1f}x too far"
            if not sensitive or reveal:
                line += f", {turn_between((east, north), (end['x'], end['z'])):.0f} deg off"
            else:
                line += ", direction check withheld"
        else:
            line += "; not on the atlas"
        print(line)

    drawn_far = 0.0
    for item in atlas["items"]:
        if item.get("kind") == "stroke":
            points = item.get("points") or item.get("pts") or []
        else:
            points = [[item.get("x", 0), item.get("y", 0)]]
        for point in points:
            drawn_far = max(drawn_far, math.hypot(point[0], point[1]))
    explored = max((math.hypot(row[1], row[3]) for row in locations if row[4]), default=0.0)
    print(f"\natlas reaches {drawn_far:.0f} m from spawn; generated world reaches about {explored:.0f} m")


def hint(chunks, portals, sites, tag, target, spawn, reveal):
    starts = [p for p in portals if p["tag"].lower() == tag.lower()]
    if not starts:
        die(f"no portal tagged {tag!r}")
    start = far_end(starts)
    wanted = [s for s in sites if s["name"] in TRADERS.values()] if target is None else [s for s in sites if s["name"] == target]
    if not wanted:
        die(f"no site named {target!r}")
    site = min(wanted, key=lambda s: distance(start, s))
    length = max(distance(start, site), 1.0)
    east, north = (site["x"] - start["x"]) / length, (site["z"] - start["z"]) / length
    print(f"portal {start['tag']}: paired {'yes' if len(starts) > 1 else 'no'}")
    print(f"target {site['name']}: {length:.0f} m, generated {'yes' if site['generated'] else 'no'}")
    print(f"height: portal {start['y']:.0f} m, site {site['y']:.0f} m, sea level {SEA_LEVEL:.0f} m")
    from_spawn = math.hypot(start["x"], start["z"])
    if from_spawn > 1:
        along = east * start["x"] / from_spawn + north * start["z"] / from_spawn
        word = "away from spawn" if along > 0.5 else "toward spawn" if along < -0.5 else "sideways to spawn"
        print(f"relative to spawn: {word}")
    if reveal:
        print(f"compass from portal: {compass(east, north)}")

    world = (start["x"] + spawn[0], start["z"] + spawn[1])
    low_x, high_x = sorted((world[0], world[0] + east * length))
    low_z, high_z = sorted((world[1], world[1] + north * length))
    buckets = collections.defaultdict(list)
    for data in chunks:
        for offset in range(0, len(data) - 12):
            x = struct.unpack_from("<f", data, offset)[0]
            if not low_x - 60 < x < high_x + 60:
                continue
            z = struct.unpack_from("<f", data, offset + 8)[0]
            if not low_z - 60 < z < high_z + 60:
                continue
            y = struct.unpack_from("<f", data, offset + 4)[0]
            if not 15 < y < 150:
                continue
            along = (x - world[0]) * east + (z - world[1]) * north
            across = abs(-(x - world[0]) * north + (z - world[1]) * east)
            if -20 <= along <= length + 20 and across <= 40:
                buckets[int(along // 25) * 25].append(y)
    print("object heights along the way (m from portal: median, share below sea level):")
    for step in sorted(buckets):
        values = sorted(buckets[step])
        below = sum(y < SEA_LEVEL for y in values) / len(values)
        print(f"  {step:>5}: {values[len(values) // 2]:.0f} m, {below:.0%} below ({len(values)} objects)")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default=DEFAULT_HOST)
    parser.add_argument("--hint", metavar="PORTAL")
    parser.add_argument("--target", metavar="NAME", help="site for --hint; default is the nearest trader")
    parser.add_argument("--reveal", action="store_true", help="include coordinates and withheld directions")
    args = parser.parse_args()

    workdir = tempfile.mkdtemp(prefix="valheim-map-guide-")
    try:
        atlas, root, snapshot = fetch(args.host, workdir)
        data = latest_main(root)
        locations = read_locations(data)
        temples = [row for row in locations if row[0] == stable_hash("StartTemple")]
        if len(temples) != 1:
            die("expected exactly one spawn location; the save format may have changed")
        spawn = (temples[0][1], temples[0][3])
        chunks = latest_chunks(root)
        portals, builds = read_builds(chunks, spawn)
        if not portals:
            die("no portals found; the save format may have changed")
        sites = build_sites(locations, spawn)
        if args.hint:
            hint(chunks, portals, sites, args.hint, args.target, spawn, args.reveal)
        else:
            report(atlas, snapshot, locations, data, portals, builds, sites, args.reveal)
    finally:
        shutil.rmtree(workdir, ignore_errors=True)


if __name__ == "__main__":
    main()

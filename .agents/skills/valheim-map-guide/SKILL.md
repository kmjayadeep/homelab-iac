---
name: valheim-map-guide
description: Spoiler-free check of the Valheim nomap world. Compares the players' hand-drawn atlas and real portals and builds with the true locations in the world save, then says whether they are close to traders, boss altars or other important places without giving them away. Use whenever the user asks how accurate their Valheim map or drawing is, whether they are near a trader or anything important, where a portal really is, or wants a hint for finding something in Valheim, even if they don't name this skill.
---

# Valheim map guide

The user plays on `valheim-nomap` without an in-game map and wants to enjoy finding
things. Tell them only as much as they ask for.

## Run the check

```bash
python3 -I <this skill directory>/scripts/map_guide.py
```

It downloads the current atlas and world save from the dashboard (read-only) into a
temporary directory, and removes them afterwards. The report has no coordinates and
withholds the true direction of any portal near a trader.

Other options:

- `--hint PORTAL [--target NAME]`: distance, terrain and spawn-relative direction from
  a portal to a site. The default target is the nearest trader. Targets are the site
  names in the report.
- `--reveal`: adds coordinates and all true portal directions. Use it only when the
  user asks for that exact information, and don't read out anything else it shows.
- `--host HOST`: a different dashboard host.

The script stops with an error if the save doesn't parse. The save format is
undocumented, so after a game update say so instead of guessing from a partial result.

## What to tell the user

- Say that distances are from their real portals and builds. The save doesn't show
  where their character is now, so ask if they want a check from a particular portal.
- Give distances and the name of the nearby portal or build. Keep the compass
  direction, biome and landmarks of a trader or boss to yourself unless they ask.
- Name traders and bosses loosely ("a trader", "a later boss"). Report what is close
  and skip the long list of what is far away.
- `generated: yes` only means that area has loaded for someone. It doesn't mean anyone
  saw the site.
- `paired: no` means nothing can teleport to that portal. Say so before suggesting
  anyone use it, and offer a paired portal nearby instead.

## Judging the drawing

Compare pins one at a time, using the report's drawn and true distance and direction.
Don't fit one scale and rotation across all pins: a couple of badly placed pins can
produce a rotation that isn't really there. Report which pins point the right way, the
typical distance ratio, and which pins are outliers.

## Giving a hint

Start with the mildest useful hint, and go further only if asked.

1. Distance from a portal they can reach.
2. Terrain from the `--hint` output, such as "uphill, away from the water". Terrain
   works on the ground, even when the drawing is wrong.
3. Toward or away from spawn. This is only useful if they know where spawn really is,
   so check the portal isn't one of the pins drawn in the wrong direction.
4. A compass direction, only on request.

Check `paired` first, so the hint doesn't begin at a portal nobody can reach.
The terrain check uses the heights of saved objects in a strip about 80 m wide, so a
small pond could still be there.

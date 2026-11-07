# Valheim Vartha

Valheim Vartha (വാർത്ത) is the comic newspaper that `valheim-nomap` serves on
port 8000: a front page made from live server data, a shared hand-drawn atlas,
and editions written by an AI editor twice a day. The code is in
`roles/valheim/files/dashboard/`: `server.py` (Python standard library only),
`index.html` (the newspaper), `map.html` (the atlas), and `atlas.js` (drawing
code that both pages share).

Deploy it without restarting the game:

```bash
ansible-playbook playbooks/dashboard.yml --limit valheim-nomap
```

## How an edition is made

```
CronJob vartha-editor (homelab-k8s, namespace kagent, 04:00 and 16:00 Europe/Zurich)
  1. GET  /api/digest            plain-text fact sheet from server.py
  2. A2A  agent vartha-editor    Claude Opus 5.5 through LiteLLM, returns JSON
  3. clean the English sections  keeps only a short list of Malayalam words
  4. POST /api/edition           Bearer token from Vault apps/valheim-vartha/editor
```

The agent, its system prompt, and the CronJob script live in homelab-k8s under
`clusters/titania/apps/kagent/` (`agent-vartha-editor.yaml`,
`vartha-editor.yaml`). Run one edition by hand with
`kubectl -n kagent create job --from=cronjob/vartha-editor manual-edition`.
Game events and player names go to Anthropic with every edition.

- **`/api/digest`** gives the model facts, not raw logs. `digest_text()`
  works out every number in advance (deaths per player with causes and times,
  minutes from joining to dying, killers and their victims, atlas pins in
  metres east and north), and marks with `[NEW]` everything since the last
  edition. It also lists `ART_NAMES` so the editor can pick a cartoon. A model
  is good at the voice and bad at counting, so keep new facts in the digest
  rather than asking the model to work them out.
- **`POST /api/edition`** compares the token with `hmac.compare_digest` and
  rejects an edition with any section missing or empty (`EDITION_TEXT`,
  `EDITION_PARTS`, `EDITION_LISTS`, and the optional `malayalam` object). It
  writes `/var/lib/valheim-dashboard/edition.json` and keeps the last 60 under
  `editions/NNNNN.json`. The host gets the token as
  `valheim_dashboard_editor_token` from `vault.yml`. The same value is in
  `pass homelab/valheim/vartha-editor-token` and in Vault.
- **The page uses an edition** only while it is less than 36 hours old and no
  death has happened since it was written (`freshEdition` and `drawLead` in
  `index.html`). Otherwise the built-in templates write the lead, so the
  newest death always reaches the front page. The editor writes the lead (in
  Malayalam when it is present), the pull quote, caption, editorial, letters,
  Wanted poster, stars, ad, forecast, proverb, ചരമം notices, cartoon choice
  and caption, and the back page (sport, TV, matrimonials). The masthead,
  leaderboard, coroner's desk, bosses, awards, atlas, and wire always come
  from live data.
- **No news, no edition.** The CronJob skips publishing when the digest has
  nothing new.

### Why Claude Opus

The local model (Ornith, through LiteLLM's `sensitive` model) was tried first
on 2026-11-07. It made up deaths and moved them between players, and a second
self-check pass made things worse. DeepSeek (`frontier`) was accurate, and
Opus also writes natural newspaper Malayalam, so Opus is the editor. The
system prompt's fact rules (never move a death or pin between players, the
Wanted poster names the deadliest killer, a letter is signed by a player only
about their own death) each fix a mistake an earlier edition made.

Opus through LiteLLM accepts only `temperature: 1`, so the `claude-opus`
ModelConfig sets no temperature.

## The atlas

Players draw a shared map at `/map`. It is stored in
`/var/lib/valheim-dashboard/map.json`, which the backup includes. The newspaper
shows a small copy of it.

- **Coordinates** are world metres from the spawn stones: `x` grows east and
  `y` grows south, so north is `-y`. The digest prints `-y` as N.
- **Items** are `pin` (with an `icon` from `MAP_PINS`), `text`, and `stroke`.
  A stroke has a `color` from `MAP_COLORS` and a `style` from `MAP_STYLES`:
  `line` (any colour, width in metres), `path` (dashed brown), `river` (blue),
  `border` (dotted), or `area` (a closed biome outline, filled and labelled
  with the biome's name). Strokes saved before styles existed have no `style`
  and draw as `line`.
- **`POST /api/map`** takes `add`, `delete`, or `move` (`id`, `dx`, `dy`,
  `by`). A move keeps the item's original `ts`, so the digest does not report
  it as new, and records `moved_by`. Every change raises `rev`, and clients
  poll `/api/map?since=<rev>`.
- **Hit testing** (`Atlas.hit`) ranks pins and names over lines, and lines over
  areas. An area counts only along its edge unless `inside` is set: the Move
  tool and a tap set it, the eraser does not, so sweeping the eraser cannot
  wipe out a biome.

## Working on it

- **Preview locally.** Run `server.py` against a copy of the live data with
  `DASHBOARD_PORT`, `VALHEIM_WORLD_NAME`, `VALHEIM_WORLDS_DIR`, and
  `STATE_DIRECTORY` set. Get the data with `curl …:8000/api/map` and store its
  items in the `map.json` shape `{"schema": 1, "rev": …, "items": {id: item}}`.
  Check the page at desktop width and at 390 px.
- **Git worktrees.** Other sessions share this checkout, so work in a
  worktree. A git-crypt worktree needs the key before checkout:
  `git worktree add --no-checkout …`, then copy `.git/git-crypt/keys/default` to
  `$(git -C <worktree> rev-parse --git-dir)/git-crypt/keys/default`, then
  `git checkout`. To deploy from a worktree, set
  `ANSIBLE_VAULT_PASSWORD_FILE` to the main checkout's `.ansible_vault_pass`.
- **kagent and Flux.** kagent owns a Secret named after each agent, so the
  token's ExternalSecret writes `vartha-editor-token` instead. The `kagent`
  Kustomization waits for every object to become healthy, so one broken object
  holds back the whole app. If Flux applied an old revision, run
  `flux reconcile kustomization kagent -n kagent --with-source`.
- **Art.** The death and cartoon pictures are not in this repository. Copy them
  to `/var/lib/valheim-dashboard/art/<name>.jpg`, owned by `valheim`, using the
  names in `ART_NAMES`.

## Ideas not done yet

- Rename a pin or a name in place (now it has to be erased and drawn again).
- A troll picture for `ART_NAMES`, since a troll is the leading killer.
- A Malayalam proofread of the template phrases that have not been checked.
- On phones, the Price and Outlook boxes are different heights, and CPU sits
  alone on the last row of the server stats.

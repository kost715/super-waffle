# PMC standalone project workflow

## Active direction

- 27 Oct 2026: the user's Override GDD (docs/standalone/OVERRIDE_GDD_STATE_MACHINE_RU.md)
  replaces fixed company sides: players and their bots start as civilians and get a
  combat side dynamically. Decisions and open points:
  docs/standalone/STATE_MACHINE_DECISIONS_RU.md (WEST and EAST are allies; the side
  table is set once and never changed at runtime). S2 0.2.0 is the research stand
  for it. Where the F2 notes below conflict with Override, Override wins until the
  F2 documents are rewritten after S2 game results.

- Work on the standalone Arma 3 project, without a mandatory LifeSim dependency.
  Read docs/standalone/DEVELOPMENT_DIRECTION_RU.md, ROADMAP_RU.md and
  FACTIONS_AND_SETUP_RU.md before implementing new features.
- Exactly two player companies, blue/WEST and red/EAST, up to 16 human players
  total. Blue PMC, government army and police share WEST. Blue/red and government/red
  initially remain neutral. Government supports blue if the companies go to war.
  Green/RESISTANCE is the common enemy from the start. Do not reintroduce a third PMC.
- Host selects one base per company from four blue and four red candidates: eight
  separate locations, only two instantiated bases. Actual sites, owner appointment,
  initial assets and the final persistence backend still require implementation/design.
- The next implementation stage is the startup configuration and two-company
  campaign described in the roadmap. Save/restore of base choices is a proposed
  implementation detail; do not silently relocate bases on restart.
- standalone/ contains S1 0.1.0 alpha 1, a historical technical foundation with
  1/2/3-company test missions. Read standalone/README.md first. Its sources and release
  ZIPs remain unchanged and do not implement F2. Do not claim otherwise. Functional
  changes need a new release version and reviewable sources/builds/reports.
- docs/standalone/ui-preview/ is a browser mockup, not an Arma interface. Embedded
  previews may block JavaScript; downloaded HTML is the interactive demonstration.

## Ownership and engineering

- Keep company roles, treasury, assets and NPC personnel separate. Check membership,
  authority, ownership and transaction identity on the server for every mutation.
- Player-company clocks advance only with at least one real company member online.
  Subcontracts are computed without physical units; one NPC has one assignment.
- Design for twelve followers per player, potentially 192 across sixteen players;
  this is an unverified load target, not demonstrated performance.
- One combat side per company is now compatible with the two-company/government/green
  model. Native AI targeting, locality and combat still need real multiplayer tests.
  Do not solve faction behavior by forcing targets or treating uniforms as ownership.
- Root docs describe the current plan; old proposed numeric settings are not automatic
  defaults for the independent project. Keep confirmed rules separate from proposals.
- Use standalone/tools/ and standalone/tests/ for the independent project. Its package
  build must not include archive/ or original-mod resources. Do not treat legacy tests
  as standalone proof. Run checks appropriate to the changed files.

## Reports and review

- For each development stage provide a Russian report: what changed, why, actual
  checks, remaining limitations, and delivered files/version.
- The user sends our files to Claude for independent review, then tests in Arma.
  Supply a concrete reviewable result without repeatedly asking permission. Do not
  claim independent review or game validation unless those results were supplied.
- Keep modeled engine/RPC/UI boundaries visible in reports. Syntax/browser checks
  do not validate native AI, roads, terrain, locality or real networked Arma behavior.

## Retired material

- archive/ is explicitly retired and not an active code path. Read archive/README.md.
- archive/lifesim-pmc-unused/ preserves every previously tracked file from commit
  35f7ee6 byte for byte, including received baseline 0.6.3 and both GitHub audits.
  archive/PRESERVATION.json records the original/new paths and SHA-256 hashes.
- Archived README, AGENTS, plans, tests and version labels describe their historical
  project only. Do not use them to override the current standalone direction.
- archive/standalone-planning-v1-unused/ preserves the outdated 1–3-company concept
  and PDF. Do not silently replace historical ZIP/PDF payloads. Add new versions.
- Preserve received files and authorship/licenses. Code/assets from referenced mods
  are not authorized dependencies merely because their design inspired this project.

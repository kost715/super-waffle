# LifeSim PMC project workflow

- Use the existing checkout. Read BASELINE.json and the latest README/changelog before editing; the user selected 0.6.3 alpha 1 as the starting point for future features. Earlier 0.6.1 documents are historical snapshots.
- Preserve the user's received archives under baselines/. Do not silently replace the baseline with earlier code or overwrite its archived payload. Use a new release version for functional changes.
- At each development stage provide a Russian report: what changed, why, checks actually performed, remaining limitations, and the version/files delivered.
- The user will send our files to Claude for independent review before testing in Arma. Supply reviewable source and a ready build with relevant change/test notes when implementing a feature. Do not claim independent review or an in-game pass unless the user has supplied those results. This workflow does not require asking again for permission to do already authorized work.
- Keep implemented features separate from the agreed future design. Follow docs/PMC_PC_DESIGN_RU.md and the development plan while accounting for the newer baseline.
- Automatic SQF/browser checks do not validate real Arma AI, locality, roads, assets or multiplayer. Identify mocked engine/transport boundaries in reports.
- Read docs/BASELINE_0.6.3_REVIEW_RU.md for current findings. The old full regression suite still needs adaptation to owner-targeted state delivery and changed 0.6.3 rules. The limited review runner is tools/check_baseline_063.py; passing it is not passing the old full suite.
- Never change production logic merely to make an outdated fixture pass. Keep the original LifeSim files immutable and avoid replacing its global phone or payout behavior.

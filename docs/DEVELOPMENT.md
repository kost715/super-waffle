# Development

Use the existing checkout. Do not create a worktree unless the user requests one.
No services, credentials or extra packages are required for the Python build and
archive/contract tests. Python 3.10+ and Node.js 18+ are sufficient for those checks.

```sh
python3 tools/build.py
python3 -m unittest discover -s tests -v
```

SQF syntax and executable transaction checks use SQF-VM from
https://github.com/SQFvm/runtime/releases/tag/v2026.04.03-ed9f5f5 .
Linux asset: `sqfvm_linux_x64_gcc.zip`.
Verify SHA-256 before unpacking or running:
`bb4e3bb415305d2ef2c4cdb75e98f442baea3a4575887c6570a11435a780615b`.
Do not disable download/TLS verification. The binary is a development dependency,
not included in the mod and not needed to run it in Arma 3.

In this cloud snapshot it is installed at
`/workspace/tools/sqfvm/sqfvm_linux_x64_gcc/sqfvm`.

```sh
python3 tools/check_sqf.py --vm /workspace/tools/sqfvm/sqfvm_linux_x64_gcc/sqfvm \
  --lifesim /workspace/scratch/lifesim/unpacked
```

The native function source is loaded from the separately supplied LifeSim tree.
The SQF-VM fixture supplies compatibility shims for unsupported operators,
including hashmap `getOrDefault`, `toArray`, `values` and iteration, and mocks
engine/network/UI commands and world-side effects. It adapts compiled opcodes;
it does not remove application checks. Monetary and ownership assertions execute the addon's SQF plus
native money, licence, business and claim functions. These checks demonstrate
script behavior under fixtures; they do not demonstrate Arma networking, ACE
interaction, rendering, real profile saves or live-map correctness.

Required game dependencies: Arma 3 supporting the LifeSim build, LifeSim 0.10.1,
CBA_A3 and the ACE components required by LifeSim. The optional RU beta 3 variant
registers the same `als_main` patch; use one LifeSim variant at a time.

No mod signing key is bundled. Dedicated servers that require signatures must
sign the reviewed PBO with their own approved mod key before installation.

Optional browser regression checks use Playwright and system Chromium against
the actual, separately supplied original and RU beta 3 `ui/licenses.html`:

```sh
python3 tools/check_license_ui.py --original /path/to/original/ui/licenses.html \
  --russian /path/to/ru-beta3/ui/licenses.html
python3 tools/check_phone_ui.py --original /path/to/original/ui/phone.html \
  --russian /path/to/ru-beta3/ui/phone.html
python3 tools/check_desktop_ui.py
python3 tools/check_quest_ui.py --original /path/to/original/ui/phone.html \
  --russian /path/to/ru-beta3/ui/phone.html
python3 tools/check_contracts_ui.py --original /path/to/original/ui/phone.html \
  --russian /path/to/ru-beta3/ui/phone.html \
  --states reports/contract-phone-states.json
python3 tools/check_native_phone_ui.py --original /path/to/original/ui/phone.html \
  --russian /path/to/ru-beta3/ui/phone.html \
  --states-original reports/native-phone-states-original.json \
  --states-russian reports/native-phone-states-ru.json
```

These check that the legacy licence screen hides only the PMC entry, while its
native purchase protocol is unchanged. Phone scenarios cover app registration,
licence/base prerequisites and confirmation, Cyrillic naming, draft/focus retention,
local and server commands, permissions, layout, and all original phone apps.
The phone test executes the same ASCII-escaped script shipped inside the PBO.

Desktop scenarios load the addon's own HTML, inject that same controller, and
check navigation, shared commands, Cyrillic input, confirmations, notifications,
keyboard/window closing and layout. Server fixtures cover migration from a saved
phone-era base, spawning/idempotence, physical and native ownership authorization,
shared phone/desktop state, partial reconstruction, sale and ownership cleanup.
Additional adapters supply VM object creation, flat-world placement, model bounds
and physics/transform calls. The test-only CfgVehicles declarations contain
no game models. The actual floor/wall/roof ray tests in terminalFindSpot, asset
appearance, in-game actions, camera and CEF integration need Arma 3 validation.

Quest fixtures execute the old test and all ten new contract scenarios together
with original coopAccept, coopTick, the saved native coopEnd delegate, company
routing and wallets. New contractEnd pays the founder through the native wallet
and delegates ordinary jobs without changing their payout. Native flatSpot
is replaced by a fixture landscape; the real bounded randomized site search
still runs. AI creation is a VM object, and skill/behaviour/path/rating and death
event delivery are fixtures. The VM retains nil-valued object keys rather than
deleting them: the getVariable adapter restores Arma's default-after-removal
semantics. Actor authorization, instance identity, death checks and payout
decisions remain application code. The legacy fixture covers solo/group/company pay,
replays, failed creation, outsider kills, cancellation, deadlines, missing targets,
empty crews, interrupted saves and an isolated corrupt journal.

New fixtures cover successful execution of every contract, five rating profiles,
level 3/4 gates, site planning with native registry fixtures, owner-only payout
despite company jobsTo, receipt replays, 599 vs 600 seconds, optional attacks,
mine creation/neutralisation, driver death, protected-person death, checkpoint order,
respawn, simultaneous team death, selected reinforced garrisons, native generator leasing/restoration,
XP persistence and isolation of a corrupt metadata key. Equipment, geometry,
clocks, mineActive, engine groups and network calls are VM adapters. Live road
driving, AI response, VIP locality, building access and ACE mine handling need Arma.

Six states from actual addon phoneSync are saved to
`reports/contract-phone-states.json`: low/high rank catalogues, rendezvous far,
ready nearby, active 600-second guard and completed receipt/XP. The contract
browser check uses these states on both supplied native pages and the desktop;
it does not construct a separate mock catalogue. JS uses the same ASCII conversion
as the packaged payload.

The native-action check needs two SQF runs first. After the original run copy
`reports/native-phone-states.json` to `reports/native-phone-states-original.json`;
after the RU run copy it to `reports/native-phone-states-ru.json`. Each contains
four states generated by the corresponding native phonePush, including a live
legacy PMC mirror and a new government-guard mirror captured from real addon
scenarios. The browser check
defines A3API before page load to disable native preview fixtures, presses real
native buttons, checks their raw messages, and verifies replacement of busy
buttons by the second native state. The fixture supplies server-published mirrors;
it records RPC calls instead of running a real network/server economy.

Phone integration replaces only JSDialog handler ID 0, the first handler added
by the supported LifeSim 0.10.1 phoneOpen. A single callback explicitly dispatches
both native and PMC packets. The original ALS_fnc_phoneMsg variable and all other
control handlers remain intact. This assumption must be revisited when porting
the addon to a different upstream phoneOpen implementation.


## 0.6.0 regression scope

The fixture now models group membership and directed side relations explicitly.
It checks positive combat ratings, HandleRating protection, relation reference
counts and changing the native outlaw player's side without moving that player.
These adapters verify requested engine operations; they cannot prove engine AI
recognition, aim or fire behaviour. Game validation is required.

Test-only 3CB/RHS classes have metadata and matching magazine names but no models.
They exercise actual production asset discovery and exclusion of launchers/GLs.
The production addon has no hard 3CB patch dependency and includes no mod assets.

The contract fixture checks stable 3/2 boards, consumption, the 600-second boundary,
rejected raw/expired tickets, both native base owners with war off, real selected
base planning, replacement/cleanup and original registry restoration. Native
warBases is represented by a recording delegate in this narrow wrapper probe;
its live spawns/capture/supply and interoperability still require Arma.

In addition to the six catalogue/guard snapshots, two actual phoneSync snapshots
of sequential patrol progress are saved as reports/patrol-phone-states.json.
check_contracts_ui.py reads this adjacent file and checks the base selector,
renewal timer and checkpoint progress on both native phone variants and desktop.

## 0.6.1 compatibility scope

Use the supplied 0.13.0 PBO alongside 0.10.1 and RU beta 3; never overwrite the
inputs. Run check_sqf.py sequentially per target and copy the generated states
and report files to a separate target directory before starting the next run.
The contract UI checker expects patrol-phone-states.json beside its input.
When a native page exposes i18n, the --russian target selects its built-in ru
language. Passing the same 0.13.0 HTML to both page arguments tests EN and RU.

The final matrix is 467 SQF assertions per native target. Fixtures verify six
visible board slots, individual settlement/refill, stable unconsumed tickets,
expiry/replay safety, the base exclusion circle (including snapped roads and
cached sites for different founders), and use of the native resolved Gangs pool.
The populated Rivals test checks original mark/hire commands and reproduces
malformed-row rendering failure before exercising the non-mutating adapter.
A user-specific Rivals cause still requires the actual save/runtime or RPT.
PhoneOpen is byte-identical between the supplied 0.10.1 and 0.13.0 versions;
its JSDialog handler-0 integration still applies. No dependency installation,
background services, credentials or environment draft changes were needed.

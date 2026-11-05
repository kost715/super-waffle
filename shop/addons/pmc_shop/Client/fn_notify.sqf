// [string key, arguments] -> nothing. Server -> client: a message about the player's
// request, shown on the laptop (or as a hint when it is closed).
params [["_key", "", [""]], ["_args", [], [[]]]];
private _text = format ([localize _key] + _args);
// A refusal also ends the wait for an upgrade.
if (!isNil "PMCS_ui" && {PMCS_ui getOrDefault ["techBusy", false]}) then {PMCS_ui set ["techBusy", false]; ["body"] call PMCS_fnc_uiTech};
if (!isNil "PMCS_ui" && {(PMCS_ui get "view") == "browser"}) then {["toast", [_text]] call PMCS_fnc_ui} else {hint _text};

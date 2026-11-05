// [string key, arguments] -> nothing. Server -> client: a message about the player's
// request, shown on the laptop (or as a hint when it is closed).
params [["_key", "", [""]], ["_args", [], [[]]]];
private _text = format ([localize _key] + _args);
if (!isNil "PMCS_ui" && {(PMCS_ui get "view") == "browser"}) then {["toast", [_text]] call PMCS_fnc_ui} else {hint _text};

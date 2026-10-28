// [state] -> nothing. Server -> client: balances and histories for the open ATM.
params [["_state", [], [[]]]];
if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}} || {isNil "PMCB_ui"}) exitWith {};
PMCB_ui set ["state", _state];
PMCB_ui set ["busy", false];
private _screen = PMCB_ui getOrDefault ["screen", ""];
// A finished operation starts the next one from a clean screen.
if (_screen == "loading") then {PMCB_ui set ["screen", "main"]};
if (_screen in ["withdraw", "deposit"]) then {["open", [_screen]] call PMCB_fnc_ui} else {["draw"] call PMCB_fnc_ui};

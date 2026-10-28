// [key, args] -> nothing. Server -> client (or local): localized bank message,
// also shown in the ATM window when it is open.
params [["_key", "", [""]], ["_args", [], [[]]]];
if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}} || {_key == ""}) exitWith {};
private _text = format ([localize _key] + _args);
hint _text;
systemChat _text;
if (!isNil "PMCB_ui") then {
    PMCB_ui set ["busy", false];
    PMCB_ui set ["message", _text];
    ["draw"] call PMCB_fnc_ui;
};

// [entries] -> nothing. Server -> Zeus: the whole journal, newest first. Shown in
// the open ATM window, or in a window of its own when asked from the Zeus module.
params [["_entries", [], [[]]]];
if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {};
if (isNil "PMCB_ui" || {!dialog}) then {
    PMCB_ui = createHashMapFromArray [["atm", objNull], ["screen", "zeus"], ["state", []], ["log", _entries], ["busy", false]];
    createDialog "PMCB_RscATM";
} else {
    PMCB_ui set ["log", _entries];
    PMCB_ui set ["screen", "zeus"];
    ["draw"] call PMCB_fnc_ui;
};

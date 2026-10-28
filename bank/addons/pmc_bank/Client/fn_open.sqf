// [ATM] -> nothing. Client. Opens the ATM window and asks the server for balances.
params [["_atm", objNull, [objNull]]];
if (!hasInterface || {isNull _atm} || {dialog}) exitWith {};
PMCB_ui = createHashMapFromArray [["atm", _atm], ["screen", "loading"], ["state", []], ["log", []], ["busy", false]];
createDialog "PMCB_RscATM";
[player, _atm] remoteExecCall ["PMCB_fnc_requestState", 2];

disableSerialization;
params [["_computer", objNull, [objNull]]];
if (!hasInterface || {isNull _computer} || {player distance _computer > 4.5} || {!alive player}) exitWith {false};
if (!isNull (uiNamespace getVariable ["PMCS_console",displayNull])) exitWith {false};
uiNamespace setVariable ["PMCS_computer",_computer];
uiNamespace setVariable ["PMCS_pending",[]];
uiNamespace setVariable ["PMCS_localNotice",""];
createDialog "PMCS_Console"

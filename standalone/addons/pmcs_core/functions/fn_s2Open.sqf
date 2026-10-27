disableSerialization;
if (!hasInterface || {!isNull (uiNamespace getVariable ["PMCS2_console", displayNull])}) exitWith {false};
createDialog "PMCS_S2Console";
[player, "status", ""] remoteExecCall ["PMCS_fnc_s2Request", 2];
true

// [unit, terminal, mode] -> true when the object is a laptop of that mode ("shop" or
// "admin") and the unit stands by it (CBA PMCS_useDistance, 4 m).
params [["_unit", objNull, [objNull]], ["_terminal", objNull, [objNull]], ["_mode", "", [""]]];
!isNull _terminal && {_terminal in PMCS_terminals} && {(_terminal getVariable ["PMCS_mode", ""]) == _mode}
    && {_unit distance _terminal <= (missionNamespace getVariable ["PMCS_useDistance", 4]) + 1}

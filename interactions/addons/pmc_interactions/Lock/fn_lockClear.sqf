// [box, unit to tell, message] -> nothing. Server: the box is open for good (until a Zeus
// locks it again); every machine unlocks its inventory and drops the lock's actions.
params ["_box", "_unit", "_message"];
_box setVariable ["PMCI_lockCode", ""];
_box setVariable ["PMCI_lock", []];
[_box, []] remoteExecCall ["PMCI_fnc_lockApply", 0, _box];
[_message] remoteExecCall ["PMCI_fnc_lockNotify", _unit];

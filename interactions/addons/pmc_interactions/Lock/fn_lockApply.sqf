// [box, lock] -> nothing. Every machine, remote-executed by the server (players joining
// later get the last call for the box): keeps the lock players see, [type, difficulty,
// key, code length] or [] when open, and locks or unlocks the inventory. Players get the
// lock's ACE actions on the box.
params [["_box", objNull, [objNull]], ["_lock", [], [[]]]];
// Only the server sets locks (a client could otherwise open boxes for everyone).
if (isNull _box || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {};
_box setVariable ["PMCI_lock", _lock];
_box lockInventory (_lock isNotEqualTo []);
if (hasInterface) then {[_box] call PMCI_fnc_lockActions};

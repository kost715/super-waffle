// Who commands a running operation: its founder (who is paid for it). Only
// while the founder is offline may the crew's current leader cancel or ready
// it, so native leader hand-over cannot take a contract away from its owner.
params ["_uid", "_job", "_crew"];
private _founder = _job getOrDefault ["alspmcFounder", ""];
if (_founder == "") exitWith {(_crew getOrDefault ["leader", ""]) == _uid};
_uid == _founder || {isNull ([_founder] call ALS_fnc_findPlayer) && {(_crew getOrDefault ["leader", ""]) == _uid}}

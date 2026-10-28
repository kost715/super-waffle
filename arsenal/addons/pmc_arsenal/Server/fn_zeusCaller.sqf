// [unit] -> network ID of the requesting machine, or -1 unless the request comes from
// that unit's player and the player is a Zeus. Server.
params [["_unit", objNull, [objNull]]];
private _owner = call PMCA_fnc_requestOwner;
if (isNull _unit || {isRemoteExecuted && {owner _unit != _owner}} || {isNull getAssignedCuratorLogic _unit}) exitWith {-1};
_owner

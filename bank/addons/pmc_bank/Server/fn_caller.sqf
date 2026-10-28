// [unit, mustBeAlive] -> network ID of the requesting machine, or -1 when the
// request does not come from that unit's player. Server.
params [["_unit", objNull, [objNull]], ["_alive", true, [true]]];
private _owner = call PMCB_fnc_requestOwner;
if (isNull _unit || {_alive && {!alive _unit}} || {isRemoteExecuted && {owner _unit != _owner}} || {getPlayerUID _unit == ""}) exitWith {-1};
_owner

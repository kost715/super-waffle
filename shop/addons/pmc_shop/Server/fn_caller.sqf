// [unit] -> network ID of the requesting machine, or -1 when the request does not come
// from that unit's (living) player. Server.
params [["_unit", objNull, [objNull]]];
private _owner = call PMCS_fnc_requestOwner;
if (isNull _unit || {!alive _unit} || {isRemoteExecuted && {owner _unit != _owner}} || {getPlayerUID _unit == ""}) exitWith {-1};
_owner

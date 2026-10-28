// Eden module "Arsenal storage": every object synchronised with it opens the
// arsenal of the storage named in the module.
params [["_logic", objNull, [objNull]], "", ["_activated", true]];
if (!isServer || {!_activated}) exitWith {};
private _id = _logic getVariable ["StorageID", ""];
if !(_id isEqualType "" && {_id != ""}) exitWith {diag_log text "[PMCA] ERROR: arsenal storage module without a storage ID"};
{
    if !(_x isKindOf "Logic" || {_x isKindOf "CAManBase"}) then {[_x, _id] call PMCA_fnc_registerStorage};
} forEach synchronizedObjects _logic;

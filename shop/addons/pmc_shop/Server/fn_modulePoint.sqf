// Eden module "Delivery point": boxes synchronised with it receive what is bought at the
// laptops of the same point ID.
params [["_logic", objNull, [objNull]], "", ["_activated", true]];
if (!isServer || {!_activated}) exitWith {};
private _id = _logic getVariable ["PointID", "base"];
if !(_id isEqualType "" && {_id != ""}) exitWith {diag_log text "[PMCS] ERROR: delivery point module without a point ID"};
{
    if !(_x isKindOf "Logic" || {_x isKindOf "CAManBase"}) then {[_x, _id] call PMCS_fnc_registerPoint};
} forEach synchronizedObjects _logic;

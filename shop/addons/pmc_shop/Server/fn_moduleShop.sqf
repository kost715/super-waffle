// Eden module "ION market laptop": every object synchronised with it becomes a shop
// laptop; goods go to the delivery point named in the module.
params [["_logic", objNull, [objNull]], "", ["_activated", true]];
if (!isServer || {!_activated}) exitWith {};
private _point = _logic getVariable ["PointID", "base"];
{
    if !(_x isKindOf "Logic" || {_x isKindOf "CAManBase"}) then {[_x, "shop", _point] call PMCS_fnc_registerTerminal};
} forEach synchronizedObjects _logic;

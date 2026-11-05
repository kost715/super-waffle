// Eden module "Market management laptop": every object synchronised with it becomes the
// laptop where a Zeus manages this mission's market.
params [["_logic", objNull, [objNull]], "", ["_activated", true]];
if (!isServer || {!_activated}) exitWith {};
{
    if !(_x isKindOf "Logic" || {_x isKindOf "CAManBase"}) then {[_x, "admin", ""] call PMCS_fnc_registerTerminal};
} forEach synchronizedObjects _logic;

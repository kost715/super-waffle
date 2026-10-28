// Eden module "ATM": every object synchronised with it becomes an ATM.
params [["_logic", objNull, [objNull]], "", ["_activated", true]];
if (!isServer || {!_activated}) exitWith {};
{
    if !(_x isKindOf "Logic" || {_x isKindOf "CAManBase"}) then {[_x] call PMCB_fnc_registerAtm};
} forEach synchronizedObjects _logic;

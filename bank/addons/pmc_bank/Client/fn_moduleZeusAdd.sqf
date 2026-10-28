// Zeus module "Add to the group's account": asks for the amount.
params [["_logic", objNull, [objNull]], "", ["_activated", true]];
if (!local _logic || {!_activated}) exitWith {};
deleteVehicle _logic;
PMCB_amountSign = 1;
createDialog "PMCB_RscAmount";

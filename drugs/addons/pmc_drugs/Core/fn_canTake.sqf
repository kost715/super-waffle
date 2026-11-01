// [unit, item class] -> true when the unit can inject itself that drug: alive, carrying one.
params ["_unit", ["_item", "PMCD_Stim1f"]];
alive _unit && {_item in (items _unit)}

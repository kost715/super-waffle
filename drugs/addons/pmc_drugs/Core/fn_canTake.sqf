// [unit] -> true when the unit can inject itself a Stim1f: alive, carrying one.
params ["_unit"];
alive _unit && {"PMCD_Stim1f" in (items _unit)}

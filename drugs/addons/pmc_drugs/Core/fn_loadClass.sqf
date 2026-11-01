// [load kg] -> the load column of the Stim1f tables: 0 for 20 kg, 1 for 40 kg, 2 for 70 kg.
// A load counts as the nearest of the three: up to 30 kg, up to 55 kg, more (CBA settings).
params ["_kg"];
if (_kg <= (missionNamespace getVariable ["PMCD_loadLight", 30])) exitWith {0};
[1, 2] select (_kg > (missionNamespace getVariable ["PMCD_loadHeavy", 55]))

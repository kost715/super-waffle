// [load kg] -> the load column of the Stim1f tables: 0 for 20 kg, 1 for 40 kg, 2 for 70 kg.
// A load counts as the nearest of the three: up to 30 kg, up to 55 kg, more.
params ["_kg"];
if (_kg <= 30) exitWith {0};
[1, 2] select (_kg > 55)

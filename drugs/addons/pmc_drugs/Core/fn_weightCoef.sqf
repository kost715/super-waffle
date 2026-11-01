// [load kg] -> the Stim1f weight coefficient wc (CBA settings, defaults of the spec):
//   x = (clamp(load, min, max) - min) / (max - min)
//   wc = 1 + (exp(a x) - 1) / (exp(a) - 1) x k
// At a = 2, k = 1, 5-80 kg: 5 kg 1.000, 20 kg 1.077, 40 kg 1.242, 70 kg 1.729, 80 kg 2.000.
params ["_kg"];
private _min = missionNamespace getVariable ["PMCD_stimWeightMin", 5];
private _max = (missionNamespace getVariable ["PMCD_stimWeightMax", 80]) max (_min + 1);
private _a = (missionNamespace getVariable ["PMCD_stimBevelA", 2]) max 0.01;
private _x = (((_kg max _min) min _max) - _min) / (_max - _min);
1 + (exp (_a * _x) - 1) / (exp _a - 1) * (missionNamespace getVariable ["PMCD_stimBevelK", 1])

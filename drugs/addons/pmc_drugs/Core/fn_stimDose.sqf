// [dose number (1 = first of this body), load column] -> [active phase s, muscle damage]
// of a Stim1f dose (CBA settings; defaults of the spec). The phase lasts 14 / 12 / 10 min at
// 20 / 40 / 70 kg; the damage (spread over the phase, PMCD_fnc_step) depends on the dose
// number and the load:
//   dose    20 kg  40 kg  70 kg
//   1       0.15   0.20   0.25
//   2       0.25   0.30   0.35
//   3       0.20   0.25   0.30
//   4, 5+   0.15   0.20   0.25
params ["_dose", "_class"];
private _row = ((_dose max 1) min 4) - 1;
private _kg = ["20", "40", "70"] select _class;
private _default = ([[0.15, 0.2, 0.25], [0.25, 0.3, 0.35], [0.2, 0.25, 0.3], [0.15, 0.2, 0.25]] select _row) select _class;
[60 * (missionNamespace getVariable ["PMCD_stimTime" + _kg, [14, 12, 10] select _class]),
    missionNamespace getVariable [format ["PMCD_stimDamage%1_%2", _row + 1, _kg], _default]]

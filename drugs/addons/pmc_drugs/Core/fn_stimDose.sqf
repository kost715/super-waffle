// [dose number (1 = first of this body), load column] -> [active phase s, muscle damage]
// of a Stim1f dose. The phase lasts 14 / 12 / 10 min at 20 / 40 / 70 kg; the damage
// (spread over the phase, PMCD_fnc_step) depends on the dose number and the load:
//   dose    20 kg  40 kg  70 kg
//   1       0.15   0.20   0.25
//   2       0.25   0.30   0.35
//   3       0.20   0.25   0.30
//   4, 5+   0.15   0.20   0.25
params ["_dose", "_class"];
private _row = [[0.15, 0.2, 0.25], [0.25, 0.3, 0.35], [0.2, 0.25, 0.3], [0.15, 0.2, 0.25]] select (((_dose max 1) min 4) - 1);
[[840, 720, 600] select _class, _row select _class]

// [unit, names] -> nothing. Where the unit is local: takes the pulse effects of Stim1f doses
// that ended out of the unit's ACE Medical medications (and tells the other machines).
params ["_unit", "_names"];
private _medications = _unit getVariable ["ace_medical_medications", []];
private _left = _medications select {!((_x select 0) in _names)};
if (count _left != count _medications) then {_unit setVariable ["ace_medical_medications", _left, true]};

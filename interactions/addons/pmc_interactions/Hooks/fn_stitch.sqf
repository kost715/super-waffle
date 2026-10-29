// Stands in for ACE's stitching: [medic, patient, body part, treatment, item user, used
// item, create litter]. ACE stitches during its bar (surgicalKitProgress); after the game
// the mod stitches every bandaged wound on the part at once with ACE's own stitchWound.
// As in ACE, when sutures are consumed each further wound takes one, and stitching stops
// when none are left.
params ["_medic", "_patient", "_bodyPart"];
_bodyPart = toLower _bodyPart;
private _wounds = count ((_patient getVariable ["ace_medical_bandagedWounds", createHashMap]) getOrDefault [_bodyPart, []]);
for "_i" from 1 to _wounds do {
    if !([_patient, _bodyPart] call ace_medical_treatment_fnc_stitchWound) exitWith {};
    if (_i < _wounds && {(missionNamespace getVariable ["ace_medical_treatment_consumeSurgicalKit", 0]) == 2}
        && {isNull (([_medic, _patient, ["ACE_suture"]] call ace_medical_treatment_fnc_useItem) param [0, objNull])}) exitWith {};
};

// Stands in for ACE's stitching: [medic, patient, body part, treatment, item user, used
// item, create litter]. ACE stitches during its bar (surgicalKitProgress); after the game
// the mod stitches as many wounds as the game had stitches (PMCI_fnc_stitchCount) with
// ACE's own stitchWound, last entry first like ACE. An entry of more wounds than are left
// to stitch is split: that many are stitched, the rest stay bandaged. As in ACE, when
// sutures are consumed each further entry takes one, and stitching stops when none are left.
params ["_medic", "_patient", "_bodyPart"];
_bodyPart = toLower _bodyPart;
private _left = [_patient, _bodyPart] call PMCI_fnc_stitchCount;
private _first = true;
while {_left > 0} do {
    private _wounds = (_patient getVariable ["ace_medical_bandagedWounds", createHashMap]) getOrDefault [_bodyPart, []];
    if (_wounds isEqualTo []) exitWith {};
    if (!_first && {(missionNamespace getVariable ["ace_medical_treatment_consumeSurgicalKit", 0]) == 2}
        && {isNull (([_medic, _patient, ["ACE_suture"]] call ace_medical_treatment_fnc_useItem) param [0, objNull])}) exitWith {};
    _first = false;
    private _entry = _wounds select (count _wounds - 1);
    private _count = (ceil (_entry select 1)) max 1;
    private _piece = [];
    if (_count > _left) then {
        _piece = +_entry;
        _piece set [1, _left];
        _entry set [1, (_entry select 1) - _left];
        _wounds pushBack _piece;
    };
    if !([_patient, _bodyPart, _piece] call ace_medical_treatment_fnc_stitchWound) exitWith {};
    _left = _left - (_count min _left);
};

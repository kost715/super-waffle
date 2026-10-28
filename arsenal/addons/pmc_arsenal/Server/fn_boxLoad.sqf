// [object] -> nothing. Server. Puts the saved ordinary inventory back into an
// arsenal object once, after mission objects (and their Eden inventory) are set up.
params [["_object", objNull, [objNull]]];
if (isNull _object || {_object getVariable ["PMCA_boxLoaded", false]}) exitWith {};
_object setVariable ["PMCA_boxLoaded", true];
private _key = _object getVariable ["PMCA_boxKey", ""];
if (_key in PMCA_boxes) then {[_object, PMCA_boxes get _key] call PMCA_fnc_boxRestore};

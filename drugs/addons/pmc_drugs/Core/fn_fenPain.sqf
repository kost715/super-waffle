// ["ace_medical_injured" event: unit, pain level of the new wounds] -> nothing. Fentropil
// raises the tolerance to new pain, it is no painkiller: the pain a new wound brings is cut
// by 0.15 f (CBA, at f = 1), the pain already there stays.
// ACE Medical's own handler of the same event sets pain = max(pain, level x
// painCoefficient). CBA hands every handler the same array, so when this one runs first,
// lowering the level here is enough. When ACE's ran first and the wound set the pain, it is
// set again to the cut level (never below the pain of the last second).
params ["_unit", "_level"];
if (_unit isNotEqualTo ACE_player || {!local _unit}) exitWith {};
private _f = missionNamespace getVariable ["PMCD_fenF", 0];
if (_f <= 0) exitWith {};
private _cut = _level * (1 - (missionNamespace getVariable ["PMCD_fenPain", 0.15]) * _f);
_this set [1, _cut];
private _coef = missionNamespace getVariable ["ace_medical_painCoefficient", 1];
private _full = 0 max (_level * _coef) min 1;
private _pain = _unit getVariable ["ace_medical_pain", 0];
private _state = [_unit] call PMCD_fnc_state;
private _seen = _state getOrDefault ["painSeen", 0];
if (abs (_pain - _full) < 0.0001 && {_full > _seen}) then {
    _unit setVariable ["ace_medical_pain", 0 max (_seen max (_cut * _coef)) min 1];
};

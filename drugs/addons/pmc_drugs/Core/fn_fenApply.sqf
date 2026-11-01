// [state, f, seconds, work now W] -> nothing. Client, per second, for the player's unit:
// the Fentropil layers that act on ACE Advanced Fatigue itself, at effect level f
// (PMCD_fnc_fenLevel; 0 once no Fentropil is in the body). CBA values are at f = 1.
//  - Pathway powers: ACE's AE1, AE2 and AN pathway powers (and the AE sum, so ACE's own
//    ratios stay as they were) x (1 + 0.05 f). ACE's base values are kept and given back
//    at the end. When ACE writes its own values meanwhile (a new body, a changed
//    performance setting), they become the base. peakPower and wattsPerATP are untouched.
//  - AE2 recovery: ACE's AE2 regeneration this second (as its main loop counts it) x 0.1 f
//    added to the AE2 reserve.
//  - Animation speed x (1 + 0.05 f) (CBA switch): the mod's id in ACE's animation
//    exclusions keeps ACE from resetting it; set again every second (ACE Medical resets it
//    after a treatment); at the end the id goes and the speed is back to 1.
params ["_state", "_f", "_dt", "_work"];
private _names = ["ace_advanced_fatigue_ae1PathwayPower", "ace_advanced_fatigue_ae2PathwayPower", "ace_advanced_fatigue_anPathwayPower",
    "ace_advanced_fatigue_aePathwayPower"];
private _base = _state get "fenBase";
if (_f > 0) then {
    private _boost = 1 + (missionNamespace getVariable ["PMCD_fenPower", 0.05]) * _f;
    private _prev = _state getOrDefault ["fenBoost", 1];
    if (isNil "_base") then {_base = _names apply {missionNamespace getVariable [_x, 0]}; _prev = 1};
    {
        private _now = missionNamespace getVariable [_x, 0];
        if (abs (_now - (_base select _forEachIndex) * _prev) > 0.001) then {_base set [_forEachIndex, _now]};
        missionNamespace setVariable [_x, (_base select _forEachIndex) * _boost];
    } forEach _names;
    _state set ["fenBase", _base];
    _state set ["fenBoost", _boost];
} else {
    if (!isNil "_base") then {
        private _prev = _state getOrDefault ["fenBoost", 1];
        {
            private _now = missionNamespace getVariable [_x, 0];
            if (abs (_now - (_base select _forEachIndex) * _prev) <= 0.001) then {missionNamespace setVariable [_x, _base select _forEachIndex]};
        } forEach _names;
        _state deleteAt "fenBase";
        _state set ["fenBoost", 1];
    };
};
// AE2 recovery as ACE's main loop counts it: oxygen x recoveryFactor x 5.83 x the share of
// the AE2 pathway left unused by the work now.
if (_f > 0) then {
    private _ae1PP = missionNamespace getVariable ["ace_advanced_fatigue_ae1PathwayPower", 0];
    private _ae2PP = missionNamespace getVariable ["ace_advanced_fatigue_ae2PathwayPower", 0];
    if (_ae1PP <= 0 || {_ae2PP <= 0}) exitWith {};
    private _oxygen = if (missionNamespace getVariable ["ace_medical_enabled", false] && {missionNamespace getVariable ["ace_medical_vitals_simulateSpo2", false]}) then {
        (ACE_player getVariable ["ace_medical_spo2", 97]) / 100
    } else {
        1 - 0.131 * (missionNamespace getVariable ["ace_advanced_fatigue_respiratoryRate", 0]) ^ 2
    };
    private _muscleFactor = sqrt (1 - (missionNamespace getVariable ["ace_advanced_fatigue_muscleDamage", 0]));
    private _ae1Power = _work min (_ae1PP * sqrt ((missionNamespace getVariable ["ace_advanced_fatigue_ae1Reserve", 4000000]) / 4000000) * _oxygen * _muscleFactor);
    private _ae2Power = (_work - _ae1Power) min (_ae2PP * sqrt (ace_advanced_fatigue_ae2Reserve / 84000) * _oxygen * _muscleFactor);
    private _regen = _oxygen * (missionNamespace getVariable ["ace_advanced_fatigue_recoveryFactor", 1]) * 5.83 * (_ae2PP - _ae2Power) / _ae2PP;
    private _extra = 0 max (_regen * (missionNamespace getVariable ["PMCD_fenRegen", 0.1]) * _f * _dt);
    ace_advanced_fatigue_ae2Reserve = (ace_advanced_fatigue_ae2Reserve + _extra) min 84000;
    _state set ["fenRegen", _extra / (_dt max 0.001)];
};
// Animation speed.
private _exclusions = missionNamespace getVariable ["ace_advanced_fatigue_setAnimExclusions", []];
if (_f > 0 && {missionNamespace getVariable ["PMCD_fenAnimOn", true]}) then {
    if !("PMCD_fen" in _exclusions) then {_exclusions pushBack "PMCD_fen"; ace_advanced_fatigue_setAnimExclusions = _exclusions};
    ACE_player setAnimSpeedCoef (1 + (missionNamespace getVariable ["PMCD_fenAnim", 0.05]) * _f);
    _state set ["fenAnim", true];
} else {
    if (_state getOrDefault ["fenAnim", false]) then {
        private _at = _exclusions find "PMCD_fen";
        if (_at >= 0) then {_exclusions deleteAt _at};
        ace_advanced_fatigue_setAnimExclusions = _exclusions;
        ACE_player setAnimSpeedCoef 1;
        _state set ["fenAnim", false];
    };
};

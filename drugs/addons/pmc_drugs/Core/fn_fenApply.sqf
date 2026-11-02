// [state, g] -> nothing. Client, per second, for the player's unit: the Fentropil layers
// that act on ACE Advanced Fatigue itself, at strength g (PMCD_fnc_fenLevel; 0 once no
// Fentropil is in the body). CBA values are at g = 1 (C = 1).
//  - Pathway powers: ACE's AE1, AE2 and AN pathway powers (and the AE sum, so ACE's own
//    ratios stay as they were) x (1 + 0.05 g). ACE's base values are kept and given back
//    at the end. When ACE writes its own values meanwhile (a new body, a changed
//    performance setting), they become the base. peakPower and wattsPerATP are untouched.
//  - Animation speed x (1 + 0.05 g) (CBA switch): the mod's id in ACE's animation
//    exclusions keeps ACE from resetting it; set again every second (ACE Medical resets it
//    after a treatment); at the end the id goes and the speed is back to 1.
params ["_state", "_g"];
private _names = ["ace_advanced_fatigue_ae1PathwayPower", "ace_advanced_fatigue_ae2PathwayPower", "ace_advanced_fatigue_anPathwayPower",
    "ace_advanced_fatigue_aePathwayPower"];
private _base = _state get "fenBase";
if (_g > 0) then {
    private _boost = 1 + (missionNamespace getVariable ["PMCD_fenPower", 0.05]) * _g;
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
// Animation speed.
private _exclusions = missionNamespace getVariable ["ace_advanced_fatigue_setAnimExclusions", []];
if (_g > 0 && {missionNamespace getVariable ["PMCD_fenAnimOn", true]}) then {
    if !("PMCD_fen" in _exclusions) then {_exclusions pushBack "PMCD_fen"; ace_advanced_fatigue_setAnimExclusions = _exclusions};
    ACE_player setAnimSpeedCoef (1 + (missionNamespace getVariable ["PMCD_fenAnim", 0.05]) * _g);
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

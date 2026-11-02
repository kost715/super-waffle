// Per second, client: runs the drug state of the player's unit (PMCD_fnc_step) and hands
// the result to ACE: muscle damage and the AE2 reserve to Advanced Fatigue; the pulse
// effect of every Stim1f dose that ended is taken out of ACE Medical. Fentropil's layers on
// ACE (PMCD_fnc_fenApply) and its crisper picture follow its strength now; meldonium and
// the AE2 recovery support follow. Then the icons and the
// debug panel; with the panel on, each second's debt also goes to the RPT.
if (!hasInterface || {isNull ACE_player} || {!alive ACE_player} || {isNil "ace_advanced_fatigue_ae2Reserve"}) exitWith {
    // A dead body leaves nothing behind: no grain, and ACE may set the animation speed again.
    PMCD_fenG = 0;
    [0] call PMCD_fnc_fenVisual;
    private _exclusions = missionNamespace getVariable ["ace_advanced_fatigue_setAnimExclusions", []];
    private _at = _exclusions find "PMCD_fen";
    if (_at >= 0) then {_exclusions deleteAt _at};
    call PMCD_fnc_hud;
};
private _now = CBA_missionTime;
private _dt = ((_now - (missionNamespace getVariable ["PMCD_lastTick", _now])) max 0) min 5;
PMCD_lastTick = _now;
// The second just passed counts with the drugs that worked at its start.
private _state = [ACE_player] call PMCD_fnc_state;
private _effects = [_state, _now - _dt] call PMCD_fnc_effects;
private _work = [ACE_player] call PMCD_fnc_currentWork;
([_state, _dt, _effects, [ACE_player] call PMCD_fnc_unitLoad, _work, ace_advanced_fatigue_ae2Reserve,
    missionNamespace getVariable ["ace_advanced_fatigue_anWattsPerATP", 0], missionNamespace getVariable ["ace_advanced_fatigue_recoveryFactor", 1]]
    call PMCD_fnc_step) params ["_muscle", "_ae2", "_ended"];
if (_muscle > 0) then {ace_advanced_fatigue_muscleDamage = ((missionNamespace getVariable ["ace_advanced_fatigue_muscleDamage", 0]) + _muscle) min 1};
ace_advanced_fatigue_ae2Reserve = _ae2;
if (_ended isNotEqualTo []) then {[ACE_player, _ended] call PMCD_fnc_pulseEnd};
// Fentropil: doses fully worn off leave the body; the layers follow the level now.
private _span = 60 * ((missionNamespace getVariable ["PMCD_fenRise", 20]) + (missionNamespace getVariable ["PMCD_fenPlateau", 50])
    + (missionNamespace getVariable ["PMCD_fenFall", 60]));
_state set ["fenDoses", (_state get "fenDoses") select {_now - _x < _span}];
PMCD_fenG = ([_state, _now] call PMCD_fnc_fenLevel) select 1;
[_state, PMCD_fenG] call PMCD_fnc_fenApply;
[PMCD_fenG] call PMCD_fnc_fenVisual;
// Meldonium takes back part of ACE's own muscle damage and acidosis growth; both drugs
// support AE2 recovery.
private _meld = ([_state, _now] call PMCD_fnc_meldLevel) select 0;
if (_meld) then {[_state, _dt, _work] call PMCD_fnc_meldApply} else {_state set ["meldBack", [0, 0]]};
[_state, PMCD_fenG, _meld, _dt] call PMCD_fnc_regenBoost;
_state set ["painSeen", ACE_player getVariable ["ace_medical_pain", 0]];
if (missionNamespace getVariable ["PMCD_debugOn", false] && {_effects findIf {(_x select 1) == "dec"} >= 0}) then {
    (_state get "lastWork") params ["_workNow", "_nominal", "_savings", "_rate"];
    diag_log text format ["[STIM DEBT] work_now=%1, nominal=%2, savings=%3, rate=%4 mmol/s", _workNow toFixed 1, _nominal toFixed 1, _savings toFixed 1, _rate toFixed 2];
};
call PMCD_fnc_hud;

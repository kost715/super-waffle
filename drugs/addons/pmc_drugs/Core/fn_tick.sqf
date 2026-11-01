// Per second, client: runs the drug state of the player's unit (PMCD_fnc_step) and hands
// the result to ACE Advanced Fatigue (muscle damage, the AE2 reserve), then refreshes the
// icons and the debug panel.
if (!hasInterface || {isNull ACE_player} || {!alive ACE_player} || {isNil "ace_advanced_fatigue_ae2Reserve"}) exitWith {call PMCD_fnc_hud};
private _now = CBA_missionTime;
private _dt = ((_now - (missionNamespace getVariable ["PMCD_lastTick", _now])) max 0) min 5;
PMCD_lastTick = _now;
// The second just passed counts with the drugs that worked at its start.
private _state = [ACE_player] call PMCD_fnc_state;
([_state, _dt, [_state, _now - _dt] call PMCD_fnc_effects, [ACE_player] call PMCD_fnc_unitLoad, ace_advanced_fatigue_ae2Reserve,
    missionNamespace getVariable ["ace_advanced_fatigue_anWattsPerATP", 0], missionNamespace getVariable ["ace_advanced_fatigue_recoveryFactor", 1]]
    call PMCD_fnc_step) params ["_muscle", "_ae2"];
if (_muscle > 0) then {ace_advanced_fatigue_muscleDamage = ((missionNamespace getVariable ["ace_advanced_fatigue_muscleDamage", 0]) + _muscle) min 1};
ace_advanced_fatigue_ae2Reserve = _ae2;
call PMCD_fnc_hud;

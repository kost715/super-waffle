// Per second, client: runs the drug state of the player's unit (PMCD_fnc_step) and hands
// the result to ACE Advanced Fatigue: muscle damage and the AN reserve.
if (!hasInterface || {isNull ACE_player} || {!alive ACE_player} || {isNil "ace_advanced_fatigue_anReserve"}) exitWith {};
private _now = CBA_missionTime;
private _dt = ((_now - (missionNamespace getVariable ["PMCD_lastTick", _now])) max 0) min 5;
PMCD_lastTick = _now;
// The second just passed counts with the drugs that worked at its start.
private _from = _now - _dt;
private _state = [ACE_player] call PMCD_fnc_state;
([_state, _dt, _from, [_state, _from] call PMCD_fnc_effects, ace_advanced_fatigue_anReserve,
    missionNamespace getVariable ["ace_advanced_fatigue_anWattsPerATP", 0], missionNamespace getVariable ["PMCD_debtPaybackFloor", 0.4]]
    call PMCD_fnc_step) params ["_muscle", "_anReserve"];
if (_muscle > 0) then {ace_advanced_fatigue_muscleDamage = ((missionNamespace getVariable ["ace_advanced_fatigue_muscleDamage", 0]) + _muscle) min 1};
ace_advanced_fatigue_anReserve = _anReserve;

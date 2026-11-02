// [state, Fentropil strength g, meldonium acting, seconds] -> nothing. Client: the AE2
// recovery support of Fentropil (0.1 x g, CBA) and meldonium (0.12, CBA), added up. A
// steady support: the share of what ACE would regenerate standing still (oxygen x
// recoveryFactor x 5.83 mmol/s), whatever the player does now; a heavy load eats it anyway.
params ["_state", "_g", "_meld", "_dt"];
private _share = (missionNamespace getVariable ["PMCD_fenRegen", 0.1]) * _g;
if (_meld) then {_share = _share + (missionNamespace getVariable ["PMCD_meldRegen", 0.12])};
if (_share <= 0) exitWith {_state set ["regen", 0]};
private _oxygen = [] call PMCD_fnc_oxygen;
private _perSecond = _oxygen * (missionNamespace getVariable ["ace_advanced_fatigue_recoveryFactor", 1]) * 5.83 * _share;
ace_advanced_fatigue_ae2Reserve = (ace_advanced_fatigue_ae2Reserve + _perSecond * _dt) min 84000;
_state set ["regen", _perSecond];

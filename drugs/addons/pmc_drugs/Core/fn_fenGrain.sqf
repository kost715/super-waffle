// [f] -> nothing. Client: Fentropil shows itself as film grain, the mod's own FilmGrain
// post-process (priority 2500, above the game's 2000), so the player's settings are not
// changed. Sharpness: base (each player's CBA setting, 1.25) x (1 + 0.5 f); intensity:
// CBA (0.12) x f. Off under night vision or thermal and once Fentropil is gone.
params ["_f"];
private _effect = missionNamespace getVariable ["PMCD_fenGrain", -1];
if (_f <= 0 || {currentVisionMode ACE_player != 0}) exitWith {
    if (_effect != -1) then {ppEffectDestroy _effect; PMCD_fenGrain = -1};
};
if (_effect == -1) then {
    _effect = ppEffectCreate ["FilmGrain", 2500];
    _effect ppEffectEnable true;
    PMCD_fenGrain = _effect;
};
PMCD_fenGrainValues = [(missionNamespace getVariable ["PMCD_fenGrainIntensity", 0.12]) * _f,
    (missionNamespace getVariable ["PMCD_fenGrainBase", 1.25]) * (1 + 0.5 * _f), 1, 0.1, 1, false];
_effect ppEffectAdjust PMCD_fenGrainValues;
_effect ppEffectCommit 1;

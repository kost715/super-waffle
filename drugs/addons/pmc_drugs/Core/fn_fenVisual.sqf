// [g] -> nothing. Client: Fentropil makes the picture crisper. Arma has no script command
// to raise the game's own sharpen filter (video options can only be read), so the mod uses
// its own ColorCorrections post-process on top of the player's picture: contrast x (1 + 0.08
// g) and saturation x (1 + 0.05 g) (each player's CBA settings). It multiplies what the
// player's settings render, so it is relative to them. Off under night vision or thermal
// and once Fentropil is gone. A taken priority makes ppEffectCreate fail (-1): the next
// free one is used.
params ["_g"];
private _effect = missionNamespace getVariable ["PMCD_fenVisual", -1];
if (_g <= 0 || {currentVisionMode ACE_player != 0}) exitWith {
    if (_effect != -1) then {ppEffectDestroy _effect; PMCD_fenVisual = -1};
};
if (_effect == -1) then {
    private _priority = 1580;
    _effect = ppEffectCreate ["ColorCorrections", _priority];
    while {_effect == -1 && {_priority < 1630}} do {
        _priority = _priority + 1;
        _effect = ppEffectCreate ["ColorCorrections", _priority];
    };
    if (_effect == -1) exitWith {};
    _effect ppEffectEnable true;
    PMCD_fenVisual = _effect;
    PMCD_fenVisualPriority = _priority;
};
if (_effect == -1) exitWith {};
PMCD_fenVisualValues = [1, 1 + (missionNamespace getVariable ["PMCD_fenContrast", 0.08]) * _g, 0, [0, 0, 0, 0],
    [1, 1, 1, 1 + (missionNamespace getVariable ["PMCD_fenSaturation", 0.05]) * _g], [0.299, 0.587, 0.114, 0]];
_effect ppEffectAdjust PMCD_fenVisualValues;
_effect ppEffectCommit 1;

// [action, key, modifiers] -> true if the key is one set for the action ("press" or
// "fix"). Modifiers [shift, ctrl, alt] must match when given; a key going up gives none,
// so letting go counts whatever modifiers changed meanwhile. Numpad Enter counts as Enter.
params ["_action", "_key", ["_modifiers", []]];
(([_action] call PMCI_fnc_keysOf) findIf {
    _x params ["_dik", ["_needed", [false, false, false]]];
    (_dik == _key || {_dik == 28 && {_key == 156}}) && {_modifiers isEqualTo [] || {_needed isEqualTo _modifiers}}
}) >= 0

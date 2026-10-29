// [action] -> the keys set for "press" or "fix" in CBA's controls: [[DIK, [shift, ctrl,
// alt]], ...]. The defaults (Space, Enter) when CBA has no such keybind; [] when the
// player removed the key (then only the buttons on the board work).
params ["_action"];
private _default = [[[57, [false, false, false]]], [[28, [false, false, false]]]] select (_action == "fix");
if (isNil "CBA_fnc_getKeybind") exitWith {_default};
private _entry = ["PMC Interactions", "pmci_" + _action] call CBA_fnc_getKeybind;
if (isNil "_entry") exitWith {_default};
(_entry param [8, []]) select {(_x param [0, -1]) > 0}

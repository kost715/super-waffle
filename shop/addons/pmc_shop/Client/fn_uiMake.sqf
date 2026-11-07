// [class, [x, y, w, h], parent group, region, text, font height, text colour, background]
// -> the control. Client. Positions and font heights are fractions of the laptop screen
// (PMCS_ui "screen"), so the layout scales with any monitor. Inside a group, positions
// are still given on the screen; the group's own origin is taken off. The control is
// kept under the region's name so that part of the screen can be rebuilt.
params ["_class", "_rect", ["_parent", controlNull], ["_region", "page"], ["_text", ""], ["_font", 0.022], ["_fg", ""], ["_bg", ""]];
(PMCS_ui get "screen") params ["_sx", "_sy", "_sw", "_sh"];
_rect params ["_fx", "_fy", "_fw", "_fh"];
private _display = PMCS_ui get "display";
// A button's hover colour is fixed by its class: light and accent backgrounds get theirs.
if (_class == "PMCS_Button" && {_bg isNotEqualTo ""}) then {
    private _rgb = [[_bg] call PMCS_fnc_uiColor, _bg] select (_bg isEqualType []);
    _rgb params ["_r", "_g", "_b"];
    if (0.3 * _r + 0.59 * _g + 0.11 * _b > 0.75) exitWith {_class = "PMCS_ButtonLight"};
    if (_r > 0.6 && {_g < 0.6}) then {_class = "PMCS_ButtonAccent"};
};
private _ctrl = if (isNull _parent) then {_display ctrlCreate [_class, -1]} else {_display ctrlCreate [_class, -1, _parent]};
private _pos = if (isNull _parent) then {[_sx + _fx * _sw, _sy + _fy * _sh, _fw * _sw, _fh * _sh]} else {
    (_parent getVariable ["PMCS_origin", [0, 0]]) params ["_ox", "_oy"];
    [(_fx - _ox) * _sw, (_fy - _oy) * _sh, _fw * _sw, _fh * _sh]
};
_ctrl ctrlSetPosition _pos;
_ctrl ctrlCommit 0;
if (_class in ["PMCS_Group", "PMCS_GroupWide"]) then {_ctrl setVariable ["PMCS_origin", [_fx, _fy]]};
if (_class == "PMCS_Struct") then {
    _ctrl ctrlSetStructuredText parseText format ["<t size='%1'>%2</t>", _font * _sh / 0.03, _text];
} else {
    _ctrl ctrlSetFontHeight (_font * _sh);
    if (_text != "") then {_ctrl ctrlSetText _text};
};
if (_fg isNotEqualTo "") then {_ctrl ctrlSetTextColor ([[_fg] call PMCS_fnc_uiColor, _fg] select (_fg isEqualType []))};
if (_bg isNotEqualTo "") then {_ctrl ctrlSetBackgroundColor ([[_bg] call PMCS_fnc_uiColor, _bg] select (_bg isEqualType []))};
private _regions = PMCS_ui get "regions";
if !(_region in _regions) then {_regions set [_region, []]};
(_regions get _region) pushBack _ctrl;
_ctrl

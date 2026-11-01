#include "..\ui_defines.hpp"
// Client, every second (PMCD_fnc_tick): the drug icons and the debug panel. The muscle icon
// shows ACE's muscle damage by colour (PMCD_fnc_hudColor), the "tired" icon a debt above
// 500 mmol; both sit on a light plate so even the black icon shows. Hidden while dead, in
// the Zeus interface or when switched off (CBA, per player); placed by the player's own
// CBA settings (share of the screen). The debug panel (PMCD_fnc_debug) shows everything.
if (!hasInterface) exitWith {};
private _player = missionNamespace getVariable ["ACE_player", objNull];
private _show = missionNamespace getVariable ["PMCD_hudShow", true] && {!isNull _player} && {alive _player} && {isNull findDisplay 312}
    && {!isNil "ace_advanced_fatigue_muscleDamage"};
private _display = uiNamespace getVariable ["PMCD_hudDisplay", displayNull];
if (_show) then {
    if (isNull _display) then {
        "PMCD_hud" cutRsc ["PMCD_RscHud", "PLAIN", 0, false];
        _display = uiNamespace getVariable ["PMCD_hudDisplay", displayNull];
    };
    private _color = [ace_advanced_fatigue_muscleDamage] call PMCD_fnc_hudColor;
    private _state = _player getVariable "PMCD_state";
    private _tired = !isNil "_state" && {(_state get "debt") > 500};
    private _h = safezoneH * (missionNamespace getVariable ["PMCD_hudSize", 0.045]);
    private _w = _h / pixelH * pixelW;
    private _x0 = safezoneX + safezoneW * (missionNamespace getVariable ["PMCD_hudX", 0.94]);
    private _y0 = safezoneY + safezoneH * (missionNamespace getVariable ["PMCD_hudY", 0.82]);
    {
        _x params ["_plate", "_icon", "_visible", "_slot", "_tint"];
        {
            private _ctrl = _display displayCtrl _x;
            _ctrl ctrlSetPosition [_x0 - _slot * _w * 1.15, _y0, _w, _h];
            _ctrl ctrlCommit 0;
            _ctrl ctrlShow _visible;
        } forEach [_plate, _icon];
        if (_visible) then {(_display displayCtrl _icon) ctrlSetTextColor _tint};
    } forEach [
        [PMCD_IDC_MUSCLE_PLATE, PMCD_IDC_MUSCLE, _color isNotEqualTo [], 0, _color],
        [PMCD_IDC_TIRED_PLATE, PMCD_IDC_TIRED, _tired, [0, 1] select (_color isNotEqualTo []), [1, 1, 1, 0.95]]
    ];
} else {
    if (!isNull _display) then {"PMCD_hud" cutText ["", "PLAIN"]};
};
private _panel = uiNamespace getVariable ["PMCD_debugDisplay", displayNull];
if (missionNamespace getVariable ["PMCD_debugOn", false]) then {
    if (isNull _panel) then {
        "PMCD_debug" cutRsc ["PMCD_RscDebug", "PLAIN", 0, true];
        _panel = uiNamespace getVariable ["PMCD_debugDisplay", displayNull];
    };
    (_panel displayCtrl PMCD_IDC_DEBUG) ctrlSetStructuredText parseText (call PMCD_fnc_debugText);
} else {
    if (!isNull _panel) then {"PMCD_debug" cutText ["", "PLAIN"]};
};

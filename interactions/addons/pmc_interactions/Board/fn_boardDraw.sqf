#include "..\ui_defines.hpp"
// Client: shows the running game. The scene layers take their pictures from
// PMCI_fnc_boardLook; one gauge (zone, fill, marker) serves the medical games; the wheel
// uses five click areas over the nut pictures.
if (isNil "PMCI_board") exitWith {};
private _display = uiNamespace getVariable ["PMCI_display", displayNull];
if (isNull _display) exitWith {};
private _game = PMCI_board get "game";
private _state = PMCI_board get "state";
private _group = _display displayCtrl PMCI_IDC_SCENE;
private _ctrl = {
    private _found = _display displayCtrl _this;
    if (isNull _found) then {_found = _group controlsGroupCtrl _this};
    _found
};
private _gauge = [PMCI_IDC_GAUGE, PMCI_IDC_BAND, PMCI_IDC_FILL, PMCI_IDC_FRAME, PMCI_IDC_MARKER];
private _wheel = [PMCI_IDC_NUT0, PMCI_IDC_NUT1, PMCI_IDC_NUT2, PMCI_IDC_NUT3, PMCI_IDC_NUT4, PMCI_IDC_SWAP];
private _visible = switch (_game) do {
    case "cpr": {(_gauge - [PMCI_IDC_MARKER]) + [PMCI_IDC_HOLD]};
    case "tourniquet": {_gauge + [PMCI_IDC_HOLD, PMCI_IDC_FIX]};
    case "bandage": {_gauge + [PMCI_IDC_HOLD]};
    case "wheel": {if ((_state get "phase") == "swap") then {_wheel} else {_wheel - [PMCI_IDC_SWAP]}};
    default {[]};
};
{(_x call _ctrl) ctrlShow (_x in _visible)} forEach (_gauge + _wheel + [PMCI_IDC_HOLD, PMCI_IDC_FIX]);
// Pictures: only layers whose picture changed are touched.
private _hint = (PMCI_board get "ease") > 1.3;
private _look = [_game, _state, PMCI_board get "depth", _hint] call PMCI_fnc_boardLook;
private _shown = PMCI_board getOrDefault ["look", []];
{
    if !(_x isEqualTo (_shown param [_forEachIndex, "?"])) then {
        private _layer = ([PMCI_IDC_SCENE_PIC, PMCI_IDC_HANDS, PMCI_IDC_BEAT, PMCI_IDC_WINDLASS, PMCI_IDC_GAUZE, PMCI_IDC_WHEEL,
            PMCI_IDC_NUTPIC0, PMCI_IDC_NUTPIC1, PMCI_IDC_NUTPIC2, PMCI_IDC_NUTPIC3, PMCI_IDC_NUTPIC4] select _forEachIndex) call _ctrl;
        _layer ctrlSetText _x;
        _layer ctrlShow (_x != "");
    };
} forEach _look;
PMCI_board set ["look", _look];
// Place a horizontal span [from, to] (0..1 of the gauge) on one of the gauge controls.
private _span = {
    params ["_idc", "_from", "_to", ["_inset", 0]];
    _from = 0 max (_from min 1);
    _to = _from max (_to min 1);
    (_idc call _ctrl) ctrlSetPosition [safezoneX + safezoneW * (PMCI_GAUGE_X + PMCI_GAUGE_W * _from), safezoneY + safezoneH * (PMCI_GAUGE_Y + _inset),
        safezoneW * PMCI_GAUGE_W * (_to - _from), safezoneH * (PMCI_GAUGE_H - 2 * _inset)];
    (_idc call _ctrl) ctrlCommit 0;
};
(PMCI_IDC_TITLE call _ctrl) ctrlSetText (localize ("STR_PMCI_GAME_" + _game));
(PMCI_IDC_TEXT call _ctrl) ctrlSetStructuredText parseText localize ("STR_PMCI_HELP_" + _game);
private _status = "";
private _time = 0;
switch (_game) do {
    case "cpr": {
        // Fill shows how deep the last compression went; the heart keeps 110 per minute.
        [PMCI_IDC_BAND, 0.75, 1] call _span;
        [PMCI_IDC_FILL, 0, PMCI_board get "depth", 0.0125] call _span;
        _status = format [localize "STR_PMCI_STATUS_CPR", _state get "good", round (_state get "expected"), round ((_state get "quality") * 100)];
        _time = (_state get "t") / (_state get "duration");
    };
    case "tourniquet": {
        [PMCI_IDC_BAND, _state get "low", _state get "high"] call _span;
        [PMCI_IDC_FILL, 0, _state get "p", 0.0125] call _span;
        [PMCI_IDC_MARKER, (_state get "p") - 0.014, (_state get "p") + 0.014] call _span;
        _status = format [localize "STR_PMCI_STATUS_TOURNIQUET", round ((_state get "p") * 100), (_state get "allowed") - (_state get "slips")];
        _time = (_state get "t") / (_state get "limit");
    };
    case "bandage": {
        private _half = (_state get "width") / 2;
        [PMCI_IDC_BAND, (_state get "center") - _half, (_state get "center") + _half] call _span;
        [PMCI_IDC_FILL, 0, _state get "progress", 0.0175] call _span;
        [PMCI_IDC_MARKER, (_state get "needle") - 0.014, (_state get "needle") + 0.014] call _span;
        _status = format [localize "STR_PMCI_STATUS_BANDAGE", round ((_state get "progress") * 100), round ((_state get "quality") * 100)];
        _time = (_state get "t") / (_state get "limit");
    };
    case "wheel": {
        private _phase = _state get "phase";
        private _busy = (_state get "t") < (_state get "busyUntil");
        {
            (_x call _ctrl) ctrlEnable (!_busy && {_phase in ["loosen", "tighten"]} && {!(_forEachIndex in (_state get "done"))});
        } forEach [PMCI_IDC_NUT0, PMCI_IDC_NUT1, PMCI_IDC_NUT2, PMCI_IDC_NUT3, PMCI_IDC_NUT4];
        (PMCI_IDC_SWAP call _ctrl) ctrlEnable (!_busy && {_phase == "swap"});
        _status = format [localize "STR_PMCI_STATUS_WHEEL", localize ("STR_PMCI_WHEEL_" + _phase), _state get "mistakes"];
        _time = if (_busy) then {1 - ((_state get "busyUntil") - (_state get "t")) / ((_state get "nutTime") max (_state get "swapTime"))} else {0};
    };
};
(PMCI_IDC_STATUS call _ctrl) ctrlSetStructuredText parseText _status;
(PMCI_IDC_TIME call _ctrl) progressSetPosition (0 max (_time min 1));

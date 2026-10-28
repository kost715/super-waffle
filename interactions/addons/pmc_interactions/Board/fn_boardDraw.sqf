#include "..\ui_defines.hpp"
// Client: shows the running game. One gauge (zone, fill, marker) serves the medical
// games; the wheel uses five nut buttons around a hub.
if (isNil "PMCI_board") exitWith {};
private _display = uiNamespace getVariable ["PMCI_display", displayNull];
if (isNull _display) exitWith {};
private _game = PMCI_board get "game";
private _state = PMCI_board get "state";
private _ctrl = {_display displayCtrl _this};
private _gauge = [PMCI_IDC_GAUGE, PMCI_IDC_BAND, PMCI_IDC_FILL, PMCI_IDC_MARKER];
private _wheel = [PMCI_IDC_HUB, PMCI_IDC_NUT0, PMCI_IDC_NUT1, PMCI_IDC_NUT2, PMCI_IDC_NUT3, PMCI_IDC_NUT4, PMCI_IDC_SWAP];
private _visible = switch (_game) do {
    case "cpr": {_gauge + [PMCI_IDC_BEAT, PMCI_IDC_HOLD]};
    case "tourniquet": {_gauge + [PMCI_IDC_HOLD, PMCI_IDC_FIX]};
    case "bandage": {_gauge + [PMCI_IDC_HOLD]};
    case "wheel": {_wheel};
    default {[]};
};
{(_x call _ctrl) ctrlShow (_x in _visible)} forEach (_gauge + _wheel + [PMCI_IDC_BEAT, PMCI_IDC_HOLD, PMCI_IDC_FIX]);
// Place a horizontal span [from, to] (0..1 of the gauge) on one of the gauge controls.
private _span = {
    params ["_idc", "_from", "_to", ["_inset", 0]];
    _from = 0 max (_from min 1);
    _to = _from max (_to min 1);
    (_idc call _ctrl) ctrlSetPosition [safezoneX + safezoneW * (PMCI_GAUGE_X + PMCI_GAUGE_W * _from), safezoneY + safezoneH * (PMCI_GAUGE_Y + _inset),
        safezoneW * PMCI_GAUGE_W * (_to - _from), safezoneH * (PMCI_GAUGE_H - 2 * _inset)];
    (_idc call _ctrl) ctrlCommit 0;
};
(PMCI_IDC_TITLE call _ctrl) ctrlSetText (" " + localize ("STR_PMCI_GAME_" + _game));
(PMCI_IDC_TEXT call _ctrl) ctrlSetStructuredText parseText localize ("STR_PMCI_HELP_" + _game);
private _status = "";
private _time = 0;
switch (_game) do {
    case "cpr": {
        // Fill shows how deep the last compression went; the beat light keeps 110 per minute.
        [PMCI_IDC_BAND, 0.75, 1] call _span;
        [PMCI_IDC_FILL, 0, PMCI_board get "depth", 0.012] call _span;
        [PMCI_IDC_MARKER, 0, 0] call _span;
        private _beat = ((_state get "t") * 110 / 60) % 1 < 0.2;
        (PMCI_IDC_BEAT call _ctrl) ctrlSetBackgroundColor ([[0.2, 0.2, 0.2, 1], [0.9, 0.25, 0.2, 1]] select _beat);
        _status = format [localize "STR_PMCI_STATUS_CPR", _state get "good", round (_state get "expected"), round ((_state get "quality") * 100)];
        _time = (_state get "t") / (_state get "duration");
    };
    case "tourniquet": {
        [PMCI_IDC_BAND, _state get "low", _state get "high"] call _span;
        [PMCI_IDC_FILL, 0, _state get "p", 0.012] call _span;
        [PMCI_IDC_MARKER, (_state get "p") - 0.004, (_state get "p") + 0.004] call _span;
        _status = format [localize "STR_PMCI_STATUS_TOURNIQUET", round ((_state get "p") * 100), (_state get "allowed") - (_state get "slips")];
        _time = (_state get "t") / (_state get "limit");
    };
    case "bandage": {
        private _half = (_state get "width") / 2;
        [PMCI_IDC_BAND, (_state get "center") - _half, (_state get "center") + _half] call _span;
        [PMCI_IDC_FILL, 0, _state get "progress", 0.02] call _span;
        [PMCI_IDC_MARKER, (_state get "needle") - 0.005, (_state get "needle") + 0.005] call _span;
        _status = format [localize "STR_PMCI_STATUS_BANDAGE", round ((_state get "progress") * 100), round ((_state get "quality") * 100)];
        _time = (_state get "t") / (_state get "limit");
    };
    case "wheel": {
        private _phase = _state get "phase";
        private _busy = (_state get "t") < (_state get "busyUntil");
        private _next = ((_state get "start") + 2 * (_state get "step")) % 5;
        private _hint = (PMCI_board get "ease") > 1.3;
        {
            private _index = _forEachIndex;
            private _button = _x call _ctrl;
            private _done = _index in (_state get "done");
            private _color = switch (true) do {
                case (_done): {[0.25, 0.55, 0.3, 1]};
                case (_hint && {_phase in ["loosen", "tighten"]} && {(_state get "step") > 0} && {_index == _next}): {[0.75, 0.6, 0.2, 1]};
                default {[0.35, 0.35, 0.38, 1]};
            };
            _button ctrlSetBackgroundColor _color;
            _button ctrlEnable (!_busy && {_phase in ["loosen", "tighten"]} && {!_done});
        } forEach [PMCI_IDC_NUT0, PMCI_IDC_NUT1, PMCI_IDC_NUT2, PMCI_IDC_NUT3, PMCI_IDC_NUT4];
        (PMCI_IDC_SWAP call _ctrl) ctrlEnable (!_busy && {_phase == "swap"});
        _status = format [localize "STR_PMCI_STATUS_WHEEL", localize ("STR_PMCI_WHEEL_" + _phase), _state get "mistakes"];
        _time = if (_busy) then {1 - ((_state get "busyUntil") - (_state get "t")) / ((_state get "nutTime") max (_state get "swapTime"))} else {0};
    };
};
(PMCI_IDC_STATUS call _ctrl) ctrlSetStructuredText parseText _status;
(PMCI_IDC_TIME call _ctrl) progressSetPosition (0 max (_time min 1));

#include "..\ui_defines.hpp"
// Client: shows the running game. The scene layers take their pictures from
// PMCI_fnc_boardLook and their moving positions and opacity from PMCI_fnc_boardMarks; one
// gauge (zone, fill, marker) serves the medical games; the wheel uses five click areas
// over the nut pictures, the abrasion one area over the whole scene.
if (isNil "PMCI_board") exitWith {};
private _display = uiNamespace getVariable ["PMCI_display", displayNull];
if (isNull _display) exitWith {};
private _game = PMCI_board get "game";
private _state = PMCI_board get "state";
(PMCI_board getOrDefault ["wound", ["", 0]]) params ["_type"];
private _group = _display displayCtrl PMCI_IDC_SCENE;
private _ctrl = {
    private _found = _display displayCtrl _this;
    if (isNull _found) then {_found = _group controlsGroupCtrl _this};
    _found
};
private _gauge = [PMCI_IDC_GAUGE, PMCI_IDC_BAND, PMCI_IDC_FILL, PMCI_IDC_FRAME, PMCI_IDC_MARKER];
private _progressOnly = [PMCI_IDC_GAUGE, PMCI_IDC_FILL, PMCI_IDC_FRAME];
private _wheel = [PMCI_IDC_NUT0, PMCI_IDC_NUT1, PMCI_IDC_NUT2, PMCI_IDC_NUT3, PMCI_IDC_NUT4, PMCI_IDC_SWAP];
private _visible = switch (_game) do {
    case "cpr": {(_gauge - [PMCI_IDC_MARKER]) + [PMCI_IDC_HOLD]};
    case "tourniquet": {_gauge + [PMCI_IDC_HOLD, PMCI_IDC_FIX]};
    case "bandage": {_gauge + [PMCI_IDC_HOLD]};
    case "pressure": {_gauge + [PMCI_IDC_HOLD]};
    case "edges": {_progressOnly + [PMCI_IDC_HOLD]};
    case "clean": {_progressOnly + [PMCI_IDC_SCRUB] + ([[], [PMCI_IDC_HOLD]] select ((_state get "phase") == "cover"))};
    case "iv": {_progressOnly + [PMCI_IDC_SCRUB]};
    case "suture": {_progressOnly + [PMCI_IDC_SCRUB]};
    case "splint": {_gauge + [PMCI_IDC_SCRUB]};
    case "weld": {_progressOnly + [PMCI_IDC_SCRUB]};
    case "diagnose": {if ((_state get "phase") == "fix") then {_gauge + [PMCI_IDC_HOLD]} else {_wheel - [PMCI_IDC_SWAP]}};
    case "track": {_gauge + [PMCI_IDC_HOLD]};
    case "wheel": {if ((_state get "phase") == "swap") then {_wheel} else {_wheel - [PMCI_IDC_SWAP]}};
    default {[]};
};
{(_x call _ctrl) ctrlShow (_x in _visible)} forEach (_gauge + _wheel + [PMCI_IDC_HOLD, PMCI_IDC_FIX, PMCI_IDC_SCRUB]);
// Pictures: only layers whose picture changed are touched.
private _hint = (PMCI_board get "ease") > 1.3;
private _scrubbing = PMCI_board getOrDefault ["scrubbing", false];
private _look = [_game, _state, PMCI_board get "depth", _hint, _type, _scrubbing] call PMCI_fnc_boardLook;
private _shown = PMCI_board getOrDefault ["look", []];
{
    if !(_x isEqualTo (_shown param [_forEachIndex, "?"])) then {
        private _layer = (PMCI_IDC_LAYER + _forEachIndex) call _ctrl;
        _layer ctrlSetText _x;
        _layer ctrlShow (_x != "");
    };
} forEach _look;
PMCI_board set ["look", _look];
// Moving and fading layers, in scene pixels on the scene rectangle.
(PMCI_board getOrDefault ["scene", [0, 0, 1, 1]]) params ["_x0", "_y0", "_w", "_h"];
{
    _x params ["_index", "_rect", "_alpha"];
    private _layer = (PMCI_IDC_LAYER + _index) call _ctrl;
    if (count _rect == 4) then {
        _rect params ["_px", "_py", "_pw", "_ph"];
        _layer ctrlSetPosition [_x0 + _w * _px / 1024, _y0 + _h * _py / 512, _w * _pw / 1024, _h * _ph / 512];
        _layer ctrlCommit 0;
    };
    _layer ctrlSetTextColor [1, 1, 1, _alpha];
} forEach ([_game, _state, [[], PMCI_board getOrDefault ["mouse", []]] select _scrubbing] call PMCI_fnc_boardMarks);
// Place a horizontal span [from, to] (0..1 of the gauge) on one of the gauge controls.
private _span = {
    params ["_idc", "_from", "_to", ["_inset", 0]];
    _from = 0 max (_from min 1);
    _to = _from max (_to min 1);
    (_idc call _ctrl) ctrlSetPosition [safezoneX + safezoneW * (PMCI_GAUGE_X + PMCI_GAUGE_W * _from), safezoneY + safezoneH * (PMCI_GAUGE_Y + _inset),
        safezoneW * PMCI_GAUGE_W * (_to - _from), safezoneH * (PMCI_GAUGE_H - 2 * _inset)];
    (_idc call _ctrl) ctrlCommit 0;
};
private _title = localize ("STR_PMCI_GAME_" + _game);
private _part = PMCI_board getOrDefault ["part", ""];
private _subject = switch (true) do {
    case (_type != ""): {"STR_PMCI_WOUND_" + _type};
    case (_part != ""): {"STR_PMCI_PART_" + _part};
    default {""};
};
if (_subject != "") then {
    private _name = localize _subject;
    if (_name != "") then {_title = _title + " — " + _name};
};
(PMCI_IDC_TITLE call _ctrl) ctrlSetText _title;
(PMCI_IDC_TEXT call _ctrl) ctrlSetStructuredText parseText localize ("STR_PMCI_HELP_" + _game);
private _status = "";
private _time = 0;
switch (_game) do {
    case "cpr": {
        // Fill shows how deep the last compression went; the heart keeps 110 per minute.
        [PMCI_IDC_BAND, 0.75, 1] call _span;
        [PMCI_IDC_FILL, 0, PMCI_board get "depth", 0.0125] call _span;
        _status = format [localize "STR_PMCI_STATUS_CPR", _state get "good", round (_state get "expected"), round ((_state get "quality") * 100)];
        private _ribs = PMCI_board getOrDefault ["ribs", 0];
        if (_ribs > 0) then {
            private _fresh = ((_state get "t") - (PMCI_board getOrDefault ["crackAt", -10])) < 3;
            _status = _status + format ["  <t color='%1'>%2</t>", ["#ff9a7a", "#ff4a3a"] select _fresh,
                format [localize (["STR_PMCI_STATUS_RIBS", "STR_PMCI_STATUS_RIB_CRACK"] select _fresh), _ribs]];
        };
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
    case "pressure": {
        [PMCI_IDC_BAND, _state get "low", _state get "high"] call _span;
        [PMCI_IDC_FILL, 0, _state get "progress", 0.0175] call _span;
        [PMCI_IDC_MARKER, (_state get "needle") - 0.014, (_state get "needle") + 0.014] call _span;
        _status = format [localize "STR_PMCI_STATUS_PRESSURE", round ((_state get "progress") * 100), round ((_state get "quality") * 100)];
        _time = (_state get "t") / (_state get "limit");
    };
    case "edges": {
        private _count = count (_state get "stretches");
        [PMCI_IDC_FILL, 0, count (_state get "closed") / _count, 0.0125] call _span;
        _status = format [localize "STR_PMCI_STATUS_EDGES", count (_state get "closed"), _count, (_state get "allowed") - (_state get "misses")];
        _time = (_state get "t") / (_state get "limit");
    };
    case "clean": {
        private _sum = 0;
        {_sum = _sum + _x} forEach (_state get "dirt");
        private _cleaned = 1 - _sum / (1 max count (_state get "dirt"));
        if ((_state get "phase") == "cover") then {
            [PMCI_IDC_FILL, 0, _state get "covered", 0.0125] call _span;
            _status = localize "STR_PMCI_STATUS_COVER";
        } else {
            [PMCI_IDC_FILL, 0, _cleaned, 0.0125] call _span;
            _status = format [localize "STR_PMCI_STATUS_CLEAN", round (_cleaned * 100)];
        };
        _time = (_state get "t") / (_state get "limit");
    };
    case "iv": {
        [PMCI_IDC_FILL, 0, _state get "depth", 0.0125] call _span;
        _status = format [localize "STR_PMCI_STATUS_IV", round ((_state get "depth") * 100), (_state get "allowed") - (_state get "misses")];
        _time = (_state get "t") / (_state get "limit");
    };
    case "suture": {
        [PMCI_IDC_FILL, 0, _state get "covered", 0.0125] call _span;
        _status = format [localize "STR_PMCI_STATUS_SUTURE", floor ((_state get "next") / 2), count (_state get "points") / 2,
            round (((_state get "good") / ((_state get "covered") max 0.001)) * 100)];
        _time = (_state get "t") / (_state get "limit");
    };
    case "splint": {
        // The gauge is the angle, -45 to 45 degrees; the zone is the tolerance around straight.
        private _tolerance = (_state get "tolerance") / 90;
        [PMCI_IDC_BAND, 0.5 - _tolerance, 0.5 + _tolerance] call _span;
        [PMCI_IDC_FILL, 0, (_state get "aligned") / (_state get "hold"), 0.0175] call _span;
        private _at = 0.5 + (_state get "angle") / 90;
        [PMCI_IDC_MARKER, _at - 0.014, _at + 0.014] call _span;
        _status = format [localize "STR_PMCI_STATUS_SPLINT", round (_state get "angle"), round ((_state get "aligned") / (_state get "hold") * 100)];
        _time = (_state get "t") / (_state get "limit");
    };
    case "diagnose": {
        private _busy = (_state get "t") < (_state get "busyUntil");
        if ((_state get "phase") == "fix") then {
            [PMCI_IDC_BAND, _state get "low", _state get "high"] call _span;
            [PMCI_IDC_FILL, 0, _state get "progress", 0.0175] call _span;
            [PMCI_IDC_MARKER, (_state get "needle") - 0.014, (_state get "needle") + 0.014] call _span;
            _status = format [localize "STR_PMCI_STATUS_FIX", round ((_state get "progress") * 100), _state get "mistakes"];
        } else {
            {
                (_x call _ctrl) ctrlEnable (!_busy && {!(_forEachIndex in (_state get "tested"))});
            } forEach [PMCI_IDC_NUT0, PMCI_IDC_NUT1, PMCI_IDC_NUT2, PMCI_IDC_NUT3, PMCI_IDC_NUT4];
            _status = format [localize "STR_PMCI_STATUS_DIAGNOSE", count (_state get "tested"), _state get "parts", _state get "mistakes"];
        };
        _time = (_state get "t") / (_state get "limit");
    };
    case "weld": {
        [PMCI_IDC_FILL, 0, _state get "covered", 0.0125] call _span;
        _status = format [localize "STR_PMCI_STATUS_WELD", round ((_state get "covered") * 100), round ((_state get "heat") * 100),
            round (((_state get "good") / ((_state get "covered") max 0.001)) * 100)];
        _time = (_state get "t") / (_state get "limit");
    };
    case "track": {
        if ((_state get "phase") == "align") then {
            // The gauge is the link's swing; the zone is where the holes line up.
            private _swing = 2 * (_state get "swing");
            [PMCI_IDC_BAND, 0.5 - (_state get "tolerance") / _swing, 0.5 + (_state get "tolerance") / _swing] call _span;
            [PMCI_IDC_FILL, 0, 0, 0.0175] call _span;
            private _at = 0.5 + (_state get "offset") / _swing;
            [PMCI_IDC_MARKER, _at - 0.014, _at + 0.014] call _span;
            _status = format [localize "STR_PMCI_STATUS_ALIGN", (_state get "allowed") - (_state get "misses")];
        } else {
            [PMCI_IDC_BAND, _state get "low", _state get "high"] call _span;
            [PMCI_IDC_FILL, 0, (_state get "done") / (_state get "hits"), 0.0175] call _span;
            [PMCI_IDC_MARKER, (_state get "power") - 0.014, (_state get "power") + 0.014] call _span;
            _status = format [localize "STR_PMCI_STATUS_PIN", _state get "done", _state get "hits", (_state get "allowed") - (_state get "misses")];
        };
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

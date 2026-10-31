// [game, state, mouse] -> [[layer, rectangle, opacity, (angle)], ...]: the scene layers that
// move, fade or turn with the game. Pure. A rectangle is [x, y, w, h] in scene pixels
// (1024 x 512); [] keeps the layer where PMCI_fnc_boardLayout put it. An angle (degrees,
// clockwise) turns the picture about its centre. Layers as in PMCI_fnc_boardLook.
//   mouse: [x, y] in scene pixels while scrubbing, [] otherwise
// The wound line of the cut and laceration scenes runs from x 232 to 792 at y 256.
params ["_game", "_state", ["_mouse", []]];
private _marks = [];
switch (_game) do {
    case "pressure": {
        // Blood seeps out from under the hand while the pressure is too low.
        private _low = _state get "low";
        _marks pushBack [12, [], 0 max (((_low - (_state get "needle")) / _low * 1.5) min 1)];
    };
    case "edges": {
        private _closed = _state get "closed";
        {
            _x params ["_from", "_to"];
            if (_forEachIndex in _closed) then {
                private _centre = 232 + 560 * (_from + _to) / 2;
                _marks pushBack [15 + _forEachIndex, [_centre - 36, 150, 72, 212], 1];
            } else {
                _marks pushBack [15 + _forEachIndex, [232 + 560 * _from, 196, 560 * (_to - _from), 120], 1];
            };
        } forEach (_state get "stretches");
        _marks pushBack [31, [232 + 560 * (_state get "pos") - 20, 150, 40, 212], 1];
    };
    case "clean": {
        private _dirt = _state get "dirt";
        {
            _x params ["_x0", "_y0", "_r"];
            _marks pushBack [23 + _forEachIndex, [_x0 - _r * 1.25, _y0 - _r * 1.25, _r * 2.5, _r * 2.5], _dirt select _forEachIndex];
        } forEach (_state get "spots");
        if ((_state get "phase") == "cover") then {_marks pushBack [13, [], 0.25 + 0.75 * (_state get "covered")]};
        if (count _mouse == 2) then {_marks pushBack [14, [(_mouse select 0) - 48, (_mouse select 1) - 48, 96, 96], 1]};
    };
    case "iv": {
        // The needle's tip is at (20, 236) of its 256 x 256 picture.
        (_state get "tip") params ["_tx", "_ty"];
        _marks pushBack [14, [_tx - 20, _ty - 236, 256, 256], 1];
        (_state get "lastMiss") params [["_bx", -1], ["_by", -1]];
        if (_bx >= 0) then {_marks pushBack [13, [_bx - 48, _by - 48, 96, 96], 0.9]};
    };
    case "suture": {
        private _points = _state get "points";
        for "_k" from 0 to floor ((_state get "next") / 2) - 1 do {
            private _cx = (((_points select (2 * _k)) select 0) + ((_points select (2 * _k + 1)) select 0)) / 2;
            _marks pushBack [[15 + _k, _k - 2] select (_k > 7), [_cx - 24, 200, 48, 112], 1];
        };
        if ((_state get "next") < count _points) then {
            (_points select (_state get "next")) params ["_px", "_py"];
            _marks pushBack [31, [_px - 20, _py - 20, 40, 40], 1];
        };
        for "_k" from 1 to 8 do {
            if ((_state get "next") + _k < count _points) then {
                (_points select ((_state get "next") + _k)) params ["_px", "_py"];
                _marks pushBack [22 + _k, [_px - 14, _py - 14, 28, 28], 0.45];
            };
        };
        // The needle's point is at (12, 116) of its 128 x 128 picture, drawn at 1.5 times.
        (_state get "mouse") params ["_mx", "_my"];
        _marks pushBack [14, [_mx - 18, _my - 174, 192, 192], 1];
    };
    case "splint": {
        // The broken part turns smoothly about the break at (512, 256), the centre of its picture.
        _marks pushBack [12, [0, -256, 1024, 1024], 1, _state get "angle"];
    };
    case "diagnose": {
        {
            _x params ["_sx", "_sy"];
            _marks pushBack [6 + _forEachIndex, [_sx - 24, _sy - 92, 48, 48], 1];
        } forEach (_state get "spots");
    };
    case "weld": {
        private _seam = _state get "seam";
        private _lengths = _state get "lengths";
        private _total = _state get "total";
        private _at = {
            private _d = _this * _total;
            private _i = _lengths findIf {_x >= _d};
            if (_i < 0) then {_i = count _lengths - 1};
            private _start = if (_i > 0) then {_lengths select (_i - 1)} else {0};
            (_seam select _i) params ["_ax", "_ay"];
            (_seam select (_i + 1)) params ["_bx", "_by"];
            private _u = (_d - _start) / (((_lengths select _i) - _start) max 1e-6);
            [_ax + _u * (_bx - _ax), _ay + _u * (_by - _ay)]
        };
        // Sixteen equal pieces along the seam, each laid when the bead passes its end: a
        // square picture across the piece's chord, turned along it (the bead runs through
        // the middle of the picture, so sharp corners and arcs stay on the line).
        private _covered = _state get "covered";
        private _size = _total / 16;
        for "_k" from 0 to 15 do {
            if (_covered >= (_k + 1) / 16) then {
                ((_k / 16) call _at) params ["_x0", "_y0"];
                (((_k + 1) / 16) call _at) params ["_x1", "_y1"];
                _marks pushBack [15 + _k, [(_x0 + _x1) / 2 - _size / 2, (_y0 + _y1) / 2 - _size / 2, _size, _size], 1, (_y1 - _y0) atan2 (_x1 - _x0)];
            };
        };
        // The torch's flame is at (24, 232) of its 256 x 256 picture.
        (_state get "mouse") params ["_mx", "_my"];
        _marks pushBack [14, [_mx - 24, _my - 232, 256, 256], 1];
    };
    case "track": {
        // The loose link swings across the gap at x 512; the pin goes in from the right.
        _marks pushBack [11, [384, 128 + (_state get "offset"), 256, 256], 1];
        private _driven = (_state get "done") / (_state get "hits");
        _marks pushBack [13, [600 - 110 * _driven, 224, 256, 64], 1];
    };
    case "lockpick": {
        // Plug and picks turn about the keyhole at (512, 300). A pick's picture points up
        // from its centre; the one under strain shakes, the inactive one of two is dimmed, and
        // they are gone for a moment when one breaks.
        private _turn = (_state get "turn") * 90;
        _marks pushBack [11, [400, 188, 224, 224], 1, _turn];
        private _broken = ((_state get "t") - (_state get "brokeAt")) < 0.6;
        private _two = count (_state get "sweets") > 1;
        {
            private _shake = [0, 2.5 * sin ((_state get "t") * 4000)] select ((_state get "strained") == _forEachIndex);
            private _alpha = switch (true) do {
                case (_broken): {0};
                case (_two && {(_state get "active") != _forEachIndex}): {0.55};
                default {1};
            };
            _marks pushBack [[14, 13] select _forEachIndex, [288, 76, 448, 448], _alpha, 90 - _x + _turn + _shake];
        } forEach (_state get "angles");
    };
    case "safe": {
        // The dial (centre (400, 256)) turns so the number set is under the mark at its top;
        // the lamp of the listening device glows with the signal.
        _marks pushBack [5, [224, 80, 352, 352], 1, (_state get "dial") * 3.6];
        _marks pushBack [13, [808, 120, 64, 64], 0.15 + 0.85 * (_state get "signal")];
    };
};
_marks

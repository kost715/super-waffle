// [game, state, mouse] -> [[layer, rectangle, opacity], ...]: the scene layers that move or
// fade with the game. Pure. A rectangle is [x, y, w, h] in scene pixels (1024 x 512);
// [] keeps the layer where PMCI_fnc_boardLayout put it. Layers as in PMCI_fnc_boardLook.
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
};
_marks

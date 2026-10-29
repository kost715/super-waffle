// [game, state, depth, hint] -> [scene, hands, beat, windlass, gauze, wheel, nut 0-4]:
// the picture each layer of the board shows now, "" for a hidden layer. Pure.
//   depth: 0-1, how far the CPR hands are pushed down (PMCI_board "depth")
//   hint: show which nut comes next (easy difficulty)
params ["_game", "_state", ["_depth", 0], ["_hint", false]];
private _look = ["", "", "", "", "", "", "", "", "", "", ""];
switch (_game) do {
    case "cpr": {
        _look set [0, "cpr_scene"];
        _look set [1, ["cpr_hands_up", "cpr_hands_down"] select (_depth > 0.5)];
        // The heart lights for the first fifth of every beat at 110 per minute.
        private _beats = (_state get "t") * 110 / 60;
        _look set [2, ["cpr_beat_off", "cpr_beat_on"] select ((_beats - floor _beats) < 0.2)];
    };
    case "tourniquet": {
        _look set [0, "tq_scene"];
        // Eight frames turn the windlass half a turn as the pressure goes from 0 to full.
        _look set [3, format ["tq_windlass_%1", 0 max (floor ((_state get "p") * 8) min 7)]];
    };
    case "bandage": {
        _look set [0, "bandage_scene"];
        private _stage = 0 max (ceil ((_state get "progress") * 4) min 4);
        if (_stage > 0) then {_look set [4, format ["bandage_gauze_%1", _stage]]};
    };
    case "wheel": {
        private _phase = _state get "phase";
        private _done = _state get "done";
        private _next = ((_state get "start") + 2 * (_state get "step")) % 5;
        private _showNext = _hint && {_phase in ["loosen", "tighten"]} && {(_state get "step") > 0};
        _look set [5, ["wheel_old", "wheel_new"] select (_phase in ["tighten", "done"])];
        for "_i" from 0 to 4 do {
            _look set [6 + _i, switch (true) do {
                case (_phase == "swap"): {"wheel_nut_loose"};
                case (_phase == "done"): {"wheel_nut_tight"};
                case (_i in _done): {["wheel_nut_loose", "wheel_nut_done"] select (_phase == "tighten")};
                case (_showNext && {_i == _next}): {"wheel_nut_next"};
                default {["wheel_nut_tight", "wheel_nut_loose"] select (_phase == "tighten")};
            }];
        };
    };
};
_look apply {if (_x == "") then {""} else {format ["\pmc_interactions\data\%1_ca.paa", _x]}}

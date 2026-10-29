// [game, state, depth, hint, wound type, scrubbing] -> 32 pictures, one per scene layer
// (IDC PMCI_IDC_LAYER + index), "" for a hidden layer. Pure.
//   0 scene, 1 CPR hands, 2 heart, 3 windlass, 4 gauze, 5 wheel, 6-10 nuts,
//   11 pressing hand, 12 blood seeping, 13 dressing pad, 14 swab, 15-22 wound stretches,
//   23-30 dirt spots, 31 runner along the wound
//   The later games reuse them: 11 track link, 12 splinted limb, 13 IV bruise / track pin,
//   14 the tool at the mouse (swab, IV needle, suture needle, welding torch),
//   6-10 diagnosis lights, 15-22 stitches / weld bead, 31 next stitch point
//   depth: 0-1, how far the CPR hands are pushed down (PMCI_board "depth")
//   hint: show which nut comes next (easy difficulty)
//   wound type: ACE wound class of a bandaged wound ("" if unknown)
//   scrubbing: the mouse is held on an abrasion
params ["_game", "_state", ["_depth", 0], ["_hint", false], ["_type", ""], ["_scrubbing", false]];
private _look = [];
for "_i" from 1 to 32 do {_look pushBack ""};
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
        _look set [0, switch (_type) do {case "VelocityWound": {"wound_velocity"}; case "PunctureWound": {"wound_puncture"}; default {"bandage_scene"}}];
        private _stage = 0 max (ceil ((_state get "progress") * 4) min 4);
        if (_stage > 0) then {_look set [4, format ["bandage_gauze_%1", _stage]]};
    };
    case "pressure": {
        _look set [0, ["wound_avulsion", "wound_crush"] select (_type == "Crush")];
        _look set [11, ["pressure_hand_light", "pressure_hand_firm"] select ((_state get "needle") >= (_state get "low"))];
        _look set [12, "pressure_seep"];
    };
    case "edges": {
        _look set [0, ["wound_cut", "wound_laceration"] select (_type == "Laceration")];
        private _closed = _state get "closed";
        {_look set [15 + _forEachIndex, ["edges_target", "edges_strip"] select (_forEachIndex in _closed)]} forEach (_state get "stretches");
        _look set [31, "edges_runner"];
    };
    case "clean": {
        _look set [0, "wound_abrasion"];
        {_look set [23 + _forEachIndex, format ["dirt_%1", _forEachIndex % 3 + 1]]} forEach (_state get "spots");
        if ((_state get "phase") == "cover") then {_look set [13, "abrasion_pad"]};
        if (_scrubbing) then {_look set [14, "abrasion_swab"]};
    };
    case "iv": {
        _look set [0, "iv_scene"];
        _look set [14, "iv_needle"];
        if ((_state get "lastMiss") isNotEqualTo []) then {_look set [13, "iv_bruise"]};
    };
    case "suture": {
        _look set [0, "wound_cut"];
        for "_k" from 0 to floor ((_state get "next") / 2) - 1 do {_look set [15 + _k, "suture_stitch"]};
        if ((_state get "status") == "running") then {_look set [31, "suture_point"]};
        // The points after the next one, faint: the way the needle goes.
        for "_k" from 1 to 8 do {
            if ((_state get "next") + _k < count (_state get "points")) then {_look set [22 + _k, "suture_point"]};
        };
        _look set [14, "suture_needle"];
    };
    case "splint": {
        _look set [0, "splint_scene"];
        // Seven frames of the broken part, -30 to 30 degrees in steps of 10.
        _look set [12, format ["splint_limb_%1", 0 max ((round ((_state get "angle") / 10) + 3) min 6)]];
    };
    case "diagnose": {
        _look set [0, "repair_engine"];
        private _fix = (_state get "phase") == "fix";
        {
            _look set [6 + _x, switch (true) do {
                case (_x != (_state get "faulty")): {"diag_ok"};
                case (_fix): {"diag_bad"};
                default {""};
            }];
        } forEach (_state get "tested");
    };
    case "weld": {
        _look set [0, "weld_scene"];
        for "_k" from 0 to 7 do {if ((_state get "covered") > _k / 8) then {_look set [15 + _k, "weld_bead"]}};
        _look set [14, "weld_torch"];
    };
    case "track": {
        _look set [0, "track_scene"];
        _look set [11, "track_link"];
        _look set [13, "track_pin"];
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

// [game, ACE callback args, "medical"|"repair"] -> nothing. Client. Starts a hands-on
// game in place of the rest of ACE's progress bar (repairs pass the game already chosen
// for the part, PMCI_fnc_repairGame). Difficulty comes from the CBA
// setting; a trained medic or engineer gets a 20% easier game. A bandage looks at the
// wound ACE will treat on that body part and picks the game for its type; a bigger wound
// makes a longer game.
params ["_action", "_args", "_kind"];
if (!isNil "PMCI_board") then {[false] call PMCI_fnc_finish};
_args params ["_unit", "_target", "_part", "_class"];
private _ease = [1.35, 1, 0.75] select ((missionNamespace getVariable ["PMCI_difficulty", 1]) min 2 max 0);
private _trained = switch (_kind) do {
    case "medical": {!isNil "ace_medical_treatment_fnc_isMedic" && {[_unit, 1] call ace_medical_treatment_fnc_isMedic}};
    default {!isNil "ace_repair_fnc_isEngineer" && {[_unit, 1] call ace_repair_fnc_isEngineer}};
};
if (_trained) then {_ease = _ease * 1.2};
private _game = _action;
private _wound = ["", 0];
if (_action == "bandage") then {
    private _open = _target getVariable ["ace_medical_openWounds", createHashMap];
    if !(_open isEqualType createHashMap) then {_open = createHashMap};
    _wound = [_open getOrDefault [toLower _part, []], missionNamespace getVariable ["ace_medical_damage_woundClassNames", []]] call PMCI_fnc_woundOf;
    _game = [_wound select 0] call PMCI_fnc_woundGame;
};
_wound params ["_type", "_size"];
private _state = switch (_game) do {
    case "cpr": {["init", nil, [missionNamespace getVariable ["PMCI_cprDuration", 15], 0.05 * _ease, missionNamespace getVariable ["PMCI_cprMinQuality", 0.5]]] call PMCI_fnc_cprModel};
    case "tourniquet": {
        private _half = 0.09 * _ease;
        ["init", nil, [0.71 - _half, 0.71 + _half, 0.32, missionNamespace getVariable ["PMCI_tourniquetLimit", 25], [1, 2] select (_ease > 1)]] call PMCI_fnc_tourniquetModel
    };
    case "bandage": {
        private _width = 0.22 * _ease * (switch (_class) do {case "QuikClot": {1.3}; case "ElasticBandage": {1.1}; case "PackingBandage": {0.85}; default {1}});
        if (_type == "PunctureWound") then {_width = _width * 0.85};
        ["init", nil, [_width min 0.6, missionNamespace getVariable ["PMCI_bandageLimit", 30], [5, 6, 8] select _size, 0.25]] call PMCI_fnc_bandageModel
    };
    case "pressure": {
        // An avulsion bleeds harder than a crush: a faster, stronger pulse.
        private _half = 0.1 * _ease;
        private _pulse = [[80, 0.07], [100, 0.1]] select (_type == "Avulsion");
        ["init", nil, [0.68 - _half, (0.68 + _half) min 0.97, [4, 6, 8] select _size, missionNamespace getVariable ["PMCI_pressureLimit", 30],
            _pulse select 0, (_pulse select 1) / _ease]] call PMCI_fnc_pressureModel
    };
    case "edges": {
        // Equal stretches along a cut; a laceration has more, of uneven width, and a faster marker.
        private _lacerated = _type == "Laceration";
        private _count = ([[3, 4, 5], [5, 6, 7]] select _lacerated) select _size;
        private _slot = 0.84 / _count;
        private _stretches = [];
        for "_i" from 0 to _count - 1 do {
            private _width = (_slot * 0.6 * _ease * ([1, [1, 0.65, 0.9, 0.55, 0.8, 0.7, 0.95] select _i] select _lacerated)) min (_slot * 0.95);
            private _centre = 0.08 + _slot * (_i + 0.5);
            _stretches pushBack [_centre - _width / 2, _centre + _width / 2];
        };
        ["init", nil, [_stretches, ([0.3, 0.42] select _lacerated) / _ease, missionNamespace getVariable ["PMCI_edgesLimit", 30], round (3 * _ease)]] call PMCI_fnc_edgesModel
    };
    case "clean": {
        // Dirt spots on the scraped area of the abrasion scene (scene pixels).
        private _spots = [[372, 208, 52], [528, 196, 52], [672, 222, 52], [330, 304, 52], [480, 292, 52], [622, 318, 52], [740, 296, 52], [430, 352, 52]];
        ["init", nil, [_spots select [0, [4, 6, 8] select _size], _ease / 450, missionNamespace getVariable ["PMCI_cleanLimit", 40], 1.5]] call PMCI_fnc_cleanModel
    };
    case "wheel": {["init", nil, [missionNamespace getVariable ["PMCI_nutTime", 0.8], missionNamespace getVariable ["PMCI_swapTime", 3]]] call PMCI_fnc_wheelModel};
    case "iv": {
        // The vein drawn on the IV scene (scene pixels).
        ["init", nil, [[300, 262, 760, 238], 9 * _ease, 2.5, missionNamespace getVariable ["PMCI_ivLimit", 30], round (2 * _ease), 6 / _ease]] call PMCI_fnc_ivModel
    };
    case "suture": {
        // One stitch per bandaged wound and two more, 3 to 8, across the cut of the wound scene
        // (x 232-792, y 256): the needle goes in above the line and out below it, and the
        // points make the zigzag the needle is led along.
        private _bandaged = (_target getVariable ["ace_medical_bandagedWounds", createHashMap]);
        if !(_bandaged isEqualType createHashMap) then {_bandaged = createHashMap};
        private _stitches = 3 max ((2 + count (_bandaged getOrDefault [toLower _part, []])) min 8);
        private _points = [];
        for "_k" from 0 to _stitches - 1 do {
            private _cx = 232 + 560 * (_k + 0.5) / _stitches;
            _points append [[_cx - 6, 230], [_cx + 6, 282]];
        };
        ["init", nil, [_points, 14 * _ease, 20, 140 * _ease, missionNamespace getVariable ["PMCI_sutureLimit", 40]]] call PMCI_fnc_sutureModel
    };
    case "splint": {
        ["init", nil, [(20 + random 12) * selectRandom [-1, 1], 4 * _ease, 2.5, missionNamespace getVariable ["PMCI_splintLimit", 30], 5 / _ease, 0.25]] call PMCI_fnc_splintModel
    };
    case "diagnose": {
        // Five parts of the engine bay scene (scene pixels); one of them is faulty.
        private _half = 0.1 * _ease;
        private _state = ["init", nil, [5, floor random 5, 1.5, 4, missionNamespace getVariable ["PMCI_diagnoseLimit", 40], 0.65 - _half, (0.65 + _half) min 0.97]] call PMCI_fnc_diagnoseModel;
        _state set ["spots", [[230, 190], [420, 330], [560, 170], [720, 320], [860, 200]]];
        _state
    };
    case "weld": {
        // The crack drawn on the hull plate scene (scene pixels).
        ["init", nil, [[[200, 262], [330, 250], [460, 268], [590, 248], [720, 264], [824, 252]], 14 * _ease, 35 / _ease, 160 * _ease,
            missionNamespace getVariable ["PMCI_weldLimit", 40], 0.6 / _ease]] call PMCI_fnc_weldModel
    };
    case "track": {
        private _half = 0.08 * _ease;
        ["init", nil, [40, 6 * _ease, 0.5 / _ease, 4, 0.78 - _half, (0.78 + _half) min 0.98, 1.1 / _ease,
            missionNamespace getVariable ["PMCI_trackLimit", 30], round (3 * _ease)]] call PMCI_fnc_trackModel
    };
};
PMCI_board = createHashMapFromArray [["game", _game], ["action", _action], ["wound", _wound], ["args", _args], ["kind", _kind], ["state", _state],
    ["ease", _ease], ["last", diag_tickTime], ["depth", 0], ["handler", -1]];
if (_kind == "repair" && {_game in ["diagnose", "weld"]}) then {PMCI_board set ["part", [_target, _part] call PMCI_fnc_partOf]};
// A treatment started from ACE's medical menu reopens the menu right after it (setting
// "open after treatment"), which closes this board. Hold that back; PMCI_fnc_finish
// reopens the menu when the game ends.
if (_kind == "medical" && {!isNil "ace_medical_gui_pendingReopen"} && {ace_medical_gui_pendingReopen}) then {
    ace_medical_gui_pendingReopen = false;
    PMCI_board set ["reopenMenu", true];
};
createDialog "PMCI_RscBoard";
PMCI_board set ["handler", [{call PMCI_fnc_boardTick}, 0] call CBA_fnc_addPerFrameHandler];

// [game, ACE callback args, "medical"|"repair"|"lock"] -> nothing. Client. Starts a hands-on
// game in place of the rest of ACE's progress bar (repairs pass the game already chosen
// for the part, PMCI_fnc_repairGame), or the hacking game of a locked box (args
// [unit, box, "", ""], PMCI_fnc_lockHack). Difficulty comes from the CBA
// setting; a trained medic or engineer gets a 20% easier game. A bandage looks at the
// wound ACE will treat on that body part and picks the game for its type; a bigger wound
// makes a longer game.
params ["_action", "_args", "_kind"];
if (!isNil "PMCI_board") then {[false] call PMCI_fnc_finish};
_args params ["_unit", "_target", "_part", "_class"];
// A lock's difficulty is the one its Zeus chose, the same for everyone.
private _lock = [[], _target getVariable ["PMCI_lock", []]] select (_kind == "lock");
private _level = if (_kind == "lock") then {_lock param [1, 1]} else {missionNamespace getVariable ["PMCI_difficulty", 1]};
_level = _level min 2 max 0;
private _ease = [1.35, 1, 0.75] select _level;
private _trained = switch (_kind) do {
    case "medical": {!isNil "ace_medical_treatment_fnc_isMedic" && {[_unit, 1] call ace_medical_treatment_fnc_isMedic}};
    case "lock": {false};
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
// A balance setting (normal difficulty); _ease scales it for easy, hard and trained players.
private _set = {params ["_name", "_default"]; missionNamespace getVariable ["PMCI_" + _name, _default]};
// Wound size scales the length of a game: a minor wound 5/6, a large one 8/6 of the setting.
private _sized = [5 / 6, 1, 8 / 6] select _size;
private _state = switch (_game) do {
    case "cpr": {
        ["init", nil, [["cprDuration", 15] call _set, (["cprTolerance", 0.05] call _set) * _ease, ["cprMinQuality", 0.5] call _set]] call PMCI_fnc_cprModel
    };
    case "tourniquet": {
        private _half = (["tqZone", 0.18] call _set) / 2 * _ease;
        ["init", nil, [(0.71 - _half) max 0.05, (0.71 + _half) min 0.97, ["tqSpeed", 0.32] call _set, ["tourniquetLimit", 25] call _set,
            (["tqSlips", 1] call _set) + ([0, 1] select (_ease > 1))]] call PMCI_fnc_tourniquetModel
    };
    case "bandage": {
        private _width = (["bandageZone", 0.22] call _set) * _ease * (switch (_class) do {case "QuikClot": {1.3}; case "ElasticBandage": {1.1}; case "PackingBandage": {0.85}; default {1}});
        if (_type == "PunctureWound") then {_width = _width * 0.85};
        ["init", nil, [_width min 0.6, ["bandageLimit", 30] call _set, (["bandageFill", 6] call _set) * _sized, ["bandageDrift", 0.25] call _set]] call PMCI_fnc_bandageModel
    };
    case "pressure": {
        // An avulsion bleeds harder than a crush: a faster, stronger pulse.
        private _half = (["pressureZone", 0.2] call _set) / 2 * _ease;
        private _pulse = [[80, 0.07], [100, 0.1]] select (_type == "Avulsion");
        ["init", nil, [(0.68 - _half) max 0.05, (0.68 + _half) min 0.97, (["pressureHold", 6] call _set) * ([2 / 3, 1, 4 / 3] select _size),
            ["pressureLimit", 30] call _set, _pulse select 0, (_pulse select 1) * (["pressurePulse", 1] call _set) / _ease]] call PMCI_fnc_pressureModel
    };
    case "edges": {
        // Equal stretches along a cut; a laceration has more, of uneven width, and a faster marker.
        private _lacerated = _type == "Laceration";
        private _count = ([[3, 4, 5], [5, 6, 7]] select _lacerated) select _size;
        private _slot = 0.84 / _count;
        private _stretches = [];
        for "_i" from 0 to _count - 1 do {
            private _width = (_slot * (["edgesWidth", 0.6] call _set) * _ease * ([1, [1, 0.65, 0.9, 0.55, 0.8, 0.7, 0.95] select _i] select _lacerated)) min (_slot * 0.95);
            private _centre = 0.08 + _slot * (_i + 0.5);
            _stretches pushBack [_centre - _width / 2, _centre + _width / 2];
        };
        ["init", nil, [_stretches, ([0.3, 0.42] select _lacerated) * (["edgesSpeed", 1] call _set) / _ease, ["edgesLimit", 30] call _set,
            round ((["edgesMisses", 3] call _set) * _ease)]] call PMCI_fnc_edgesModel
    };
    case "clean": {
        // Dirt spots on the scraped area of the abrasion scene (scene pixels).
        private _spots = [[372, 208, 52], [528, 196, 52], [672, 222, 52], [330, 304, 52], [480, 292, 52], [622, 318, 52], [740, 296, 52], [430, 352, 52]];
        ["init", nil, [_spots select [0, [4, 6, 8] select _size], _ease / (["cleanScrub", 450] call _set), ["cleanLimit", 40] call _set,
            ["cleanCover", 1.5] call _set]] call PMCI_fnc_cleanModel
    };
    case "wheel": {["init", nil, [["nutTime", 0.8] call _set, ["swapTime", 3] call _set, _class == "RemoveWheel"]] call PMCI_fnc_wheelModel};
    case "iv": {
        // The vein drawn on the IV scene (scene pixels).
        ["init", nil, [[300, 262, 760, 238], (["ivTolerance", 9] call _set) * _ease, ["ivInsert", 2.5] call _set, ["ivLimit", 30] call _set,
            round ((["ivMisses", 2] call _set) * _ease), (["ivTremor", 6] call _set) / _ease]] call PMCI_fnc_ivModel
    };
    case "suture": {
        // One stitch per bandaged wound, up to the CBA limit (PMCI_fnc_stitchCount), across the
        // cut of the wound scene (x 232-792, y 256): the needle goes in above the line and out
        // below it, and the points make the zigzag the needle is led along. The time limit
        // is set for 5 stitches and grows with more.
        private _stitches = 1 max ([_target, _part] call PMCI_fnc_stitchCount);
        private _points = [];
        for "_k" from 0 to _stitches - 1 do {
            private _cx = 232 + 560 * (_k + 0.5) / _stitches;
            _points append [[_cx - 6, 230], [_cx + 6, 282]];
        };
        ["init", nil, [_points, (["sutureTolerance", 14] call _set) * _ease, 20, (["sutureFast", 140] call _set) * _ease,
            (["sutureLimit", 40] call _set) * (1 max (_stitches / 5))]] call PMCI_fnc_sutureModel
    };
    case "splint": {
        ["init", nil, [(20 + random 12) * selectRandom [-1, 1], (["splintTolerance", 4] call _set) * _ease, ["splintHold", 2.5] call _set,
            ["splintLimit", 30] call _set, (["splintSpasm", 5] call _set) / _ease, 0.25]] call PMCI_fnc_splintModel
    };
    case "diagnose": {
        // Five parts of the engine bay scene (scene pixels); one of them is faulty.
        private _half = (["diagnoseZone", 0.2] call _set) / 2 * _ease;
        private _state = ["init", nil, [5, floor random 5, ["diagnoseTest", 1.5] call _set, ["diagnoseFix", 4] call _set, ["diagnoseLimit", 40] call _set,
            (0.65 - _half) max 0.05, (0.65 + _half) min 0.97]] call PMCI_fnc_diagnoseModel;
        _state set ["spots", [[230, 190], [420, 330], [560, 170], [720, 320], [860, 200]]];
        _state
    };
    case "weld": {
        // One of the cracks, picked at random, with its hull plate picture. The time limit
        // is set for a seam of 650 px and grows with the length of the crack.
        private _seams = call PMCI_fnc_weldSeams;
        private _variant = floor random count _seams;
        private _state = ["init", nil, [_seams select _variant, (["weldTolerance", 14] call _set) * _ease,
            (["weldSlow", 35] call _set) / _ease, (["weldFast", 160] call _set) * _ease, ["weldLimit", 40] call _set,
            (["weldHeat", 0.6] call _set) / _ease]] call PMCI_fnc_weldModel;
        _state set ["limit", (_state get "limit") * (1 max ((_state get "total") / 650))];
        _state set ["variant", _variant + 1];
        _state
    };
    case "track": {
        private _half = (["trackZone", 0.16] call _set) / 2 * _ease;
        ["init", nil, [40, (["trackTolerance", 6] call _set) * _ease, (["trackSwing", 0.5] call _set) / _ease, ["trackHits", 4] call _set,
            (0.78 - _half) max 0.05, (0.78 + _half) min 0.98, (["trackSpeed", 1.1] call _set) / _ease, ["trackLimit", 30] call _set,
            round ((["trackMisses", 3] call _set) * _ease)]] call PMCI_fnc_trackModel
    };
    case "lockpick": {
        // The sweet spots are somewhere on the picks' half circle, away from its ends; two
        // picks have theirs well apart.
        private _class = ["classic"] call PMCI_fnc_lockTool;
        private _sweets = [15 + random 150];
        if (([_level] call PMCI_fnc_lockPins) > 1) then {_sweets pushBack (((_sweets select 0) - 15 + 40 + random 70) % 150 + 15)};
        ["init", nil, [_sweets, (["lockpickZone", 5] call _set) * _ease, 45, (["lockpickSpeed", 0.6] call _set) * _ease,
            (["lockpickLife", 1.2] call _set) * _ease, [[_unit, _class] call PMCI_fnc_itemCount, -1] select (_class == ""),
            ["lockpickLimit", 90] call _set]] call PMCI_fnc_lockpickModel
    };
    case "terminal": {
        // As many digits as the lock's code; fewer candidates and more brackets when easy.
        private _dump = [(_lock param [3, 4]) max 4 min 6, round ((["terminalCodes", 8] call _set) / _ease) max 3 min 12, [3, 2, 1] select _level] call PMCI_fnc_terminalDump;
        _dump params ["_codes", "_answer", "_rows", "_effects", "_texts"];
        private _state = ["init", nil, [_codes, _answer, _rows, ["terminalAttempts", 4] call _set, _effects, ["terminalLimit", 90] call _set]] call PMCI_fnc_terminalModel;
        _state set ["texts", _texts];
        _state
    };
    case "safe": {
        // 3 to 5 numbers, each well away from the one before.
        private _numbers = [];
        private _last = 0;
        for "_k" from 1 to ([3, 4, 5] select _level) do {
            _last = (_last + 20 + floor random 60) % 100;
            _numbers pushBack _last;
        };
        ["init", nil, [_numbers, (["safeTolerance", 2] call _set) * _ease, 12 * _ease, 0.06, ["safeLimit", 90] call _set,
            round ((["safeMistakes", 2] call _set) * _ease), (["safeNoise", 0.12] call _set) / _ease]] call PMCI_fnc_safeModel
    };
};
PMCI_board = createHashMapFromArray [["game", _game], ["action", _action], ["wound", _wound], ["args", _args], ["kind", _kind], ["state", _state],
    ["ease", _ease], ["last", diag_tickTime], ["depth", 0], ["handler", -1]];
if (_class == "RemoveWheel") then {PMCI_board set ["name", "wheelOff"]};
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

// preInit, every machine: CBA mod settings and keys. The server's values apply to everyone;
// balance values are those of the normal difficulty (easy and hard scale them). The
// wound games (pressure, edges, clean) belong to the bandage action: switching one off
// gives that wound the packing game, switching off "bandage" gives ACE's own bar.
private _category = localize "STR_PMCI_SET_CATEGORY";
private _general = [_category, localize "STR_PMCI_SET_GENERAL"];
["PMCI_difficulty", "LIST", [localize "STR_PMCI_SET_DIFFICULTY", localize "STR_PMCI_SET_DIFFICULTY_TIP"], _general,
    [[0, 1, 2], [localize "STR_PMCI_EASY", localize "STR_PMCI_NORMAL", localize "STR_PMCI_HARD"], 1], 1] call CBA_fnc_addSetting;
["PMCI_prepTime", "SLIDER", [localize "STR_PMCI_SET_PREP", localize "STR_PMCI_SET_PREP_TIP"], _general, [0.5, 5, 1, 1], 1] call CBA_fnc_addSetting;
{
    _x params ["_game", "_settings"];
    private _group = [_category, localize ("STR_PMCI_GAME_" + _game)];
    ["PMCI_enable_" + _game, "CHECKBOX", localize "STR_PMCI_SET_ENABLE", _group, true, 1] call CBA_fnc_addSetting;
    {
        _x params ["_name", "_title", "_range"];
        ["PMCI_" + _name, "SLIDER", localize _title, _group, _range, 1] call CBA_fnc_addSetting;
    } forEach _settings;
} forEach [
    ["cpr", [["cprDuration", "STR_PMCI_SET_CPR_DURATION", [5, 60, 15, 0]], ["cprMinQuality", "STR_PMCI_SET_CPR_QUALITY", [0, 1, 0.5, 2]],
        ["cprTolerance", "STR_PMCI_SET_CPR_TOLERANCE", [0, 0.15, 0.05, 2]],
        ["ribChance", "STR_PMCI_SET_RIB_CHANCE", [0, 1, 0.15, 2]], ["ribMax", "STR_PMCI_SET_RIB_MAX", [0, 5, 1, 0]]]],
    ["tourniquet", [["tourniquetLimit", "STR_PMCI_SET_LIMIT", [5, 120, 25, 0]], ["tqZone", "STR_PMCI_SET_ZONE", [0.05, 0.4, 0.18, 2]],
        ["tqSpeed", "STR_PMCI_SET_TQ_SPEED", [0.1, 1, 0.32, 2]], ["tqSlips", "STR_PMCI_SET_SLIPS", [0, 5, 1, 0]]]],
    ["bandage", [["bandageLimit", "STR_PMCI_SET_LIMIT", [5, 120, 30, 0]], ["bandageEffect", "STR_PMCI_SET_BANDAGE_EFFECT", [0, 1, 0.4, 2]],
        ["bandageZone", "STR_PMCI_SET_ZONE", [0.05, 0.6, 0.22, 2]], ["bandageFill", "STR_PMCI_SET_BANDAGE_FILL", [1, 20, 6, 1]],
        ["bandageDrift", "STR_PMCI_SET_BANDAGE_DRIFT", [0, 1, 0.25, 2]]]],
    ["pressure", [["pressureLimit", "STR_PMCI_SET_LIMIT", [5, 120, 30, 0]], ["pressureZone", "STR_PMCI_SET_ZONE", [0.05, 0.5, 0.2, 2]],
        ["pressureHold", "STR_PMCI_SET_PRESSURE_HOLD", [1, 20, 6, 1]], ["pressurePulse", "STR_PMCI_SET_PRESSURE_PULSE", [0, 3, 1, 2]]]],
    ["edges", [["edgesLimit", "STR_PMCI_SET_LIMIT", [5, 120, 30, 0]], ["edgesSpeed", "STR_PMCI_SET_EDGES_SPEED", [0.2, 3, 1, 2]],
        ["edgesWidth", "STR_PMCI_SET_EDGES_WIDTH", [0.2, 1, 0.6, 2]], ["edgesMisses", "STR_PMCI_SET_MISSES", [0, 10, 3, 0]]]],
    ["clean", [["cleanLimit", "STR_PMCI_SET_LIMIT", [5, 120, 40, 0]], ["cleanScrub", "STR_PMCI_SET_CLEAN_SCRUB", [50, 2000, 450, 0]],
        ["cleanCover", "STR_PMCI_SET_CLEAN_COVER", [0.5, 10, 1.5, 1]]]],
    ["iv", [["ivLimit", "STR_PMCI_SET_LIMIT", [5, 120, 30, 0]], ["ivTolerance", "STR_PMCI_SET_IV_TOLERANCE", [2, 40, 9, 0]],
        ["ivInsert", "STR_PMCI_SET_IV_INSERT", [0.5, 10, 2.5, 1]], ["ivTremor", "STR_PMCI_SET_IV_TREMOR", [0, 30, 6, 0]],
        ["ivMisses", "STR_PMCI_SET_MISSES", [0, 10, 2, 0]]]],
    ["suture", [["sutureLimit", "STR_PMCI_SET_SUTURE_LIMIT", [5, 120, 40, 0]], ["sutureTolerance", "STR_PMCI_SET_LINE_WIDTH", [4, 50, 14, 0]],
        ["sutureFast", "STR_PMCI_SET_FAST", [20, 600, 140, 0]], ["sutureMax", "STR_PMCI_SET_SUTURE_MAX", [1, 10, 10, 0]]]],
    ["splint", [["splintLimit", "STR_PMCI_SET_LIMIT", [5, 120, 30, 0]], ["splintTolerance", "STR_PMCI_SET_SPLINT_TOLERANCE", [1, 20, 4, 0]],
        ["splintHold", "STR_PMCI_SET_SPLINT_HOLD", [0.5, 10, 2.5, 1]], ["splintSpasm", "STR_PMCI_SET_SPLINT_SPASM", [0, 30, 5, 1]]]],
    ["wheel", [["nutTime", "STR_PMCI_SET_NUT_TIME", [0.2, 3, 0.8, 1]], ["swapTime", "STR_PMCI_SET_SWAP_TIME", [0.5, 10, 3, 1]]]],
    ["weld", [["weldLimit", "STR_PMCI_SET_LIMIT", [5, 120, 40, 0]], ["weldTolerance", "STR_PMCI_SET_LINE_WIDTH", [4, 50, 14, 0]],
        ["weldSlow", "STR_PMCI_SET_SLOW", [0, 200, 35, 0]], ["weldFast", "STR_PMCI_SET_FAST", [20, 800, 160, 0]],
        ["weldHeat", "STR_PMCI_SET_WELD_HEAT", [0, 5, 0.6, 2]]]],
    ["track", [["trackLimit", "STR_PMCI_SET_LIMIT", [5, 120, 30, 0]], ["trackTolerance", "STR_PMCI_SET_TRACK_TOLERANCE", [1, 40, 6, 0]],
        ["trackSwing", "STR_PMCI_SET_TRACK_SWING", [0.1, 3, 0.5, 2]], ["trackHits", "STR_PMCI_SET_TRACK_HITS", [1, 10, 4, 0]],
        ["trackZone", "STR_PMCI_SET_ZONE", [0.05, 0.6, 0.16, 2]], ["trackSpeed", "STR_PMCI_SET_TRACK_SPEED", [0.2, 5, 1.1, 2]],
        ["trackMisses", "STR_PMCI_SET_MISSES", [0, 10, 3, 0]]]]
];
// Locks (Zeus module "Lock"): the five key classes Zeus can give a classic lock, the tools
// the hacking games need ("" = none needed; a lockpick is used up when it breaks) and the
// games' tuning. A lock's difficulty is chosen by Zeus.
private _locks = [_category, localize "STR_PMCI_SET_LOCKS"];
for "_k" from 1 to 5 do {
    [format ["PMCI_lockKey%1", _k], "EDITBOX", [format [localize "STR_PMCI_SET_LOCK_KEY", _k], localize "STR_PMCI_SET_LOCK_KEY_TIP"], _locks, "", 1] call CBA_fnc_addSetting;
};
{
    _x params ["_name", "_title"];
    [_name, "EDITBOX", [localize _title, localize "STR_PMCI_SET_TOOL_TIP"], _locks, "", 1] call CBA_fnc_addSetting;
} forEach [["PMCI_lockpickItem", "STR_PMCI_SET_LOCKPICK_ITEM"], ["PMCI_terminalItem", "STR_PMCI_SET_TERMINAL_ITEM"], ["PMCI_safeItem", "STR_PMCI_SET_SAFE_ITEM"]];
{
    _x params ["_name", "_title", "_range"];
    ["PMCI_" + _name, "SLIDER", localize _title, _locks, _range, 1] call CBA_fnc_addSetting;
} forEach [
    ["lockpickLimit", "STR_PMCI_SET_LOCKPICK_LIMIT", [10, 300, 90, 0]], ["lockpickZone", "STR_PMCI_SET_LOCKPICK_ZONE", [1, 30, 5, 1]],
    ["lockpickLife", "STR_PMCI_SET_LOCKPICK_LIFE", [0.2, 5, 1.2, 1]], ["lockpickSpeed", "STR_PMCI_SET_LOCKPICK_SPEED", [0.1, 3, 0.6, 2]],
    ["terminalLimit", "STR_PMCI_SET_TERMINAL_LIMIT", [10, 300, 90, 0]], ["terminalCodes", "STR_PMCI_SET_TERMINAL_CODES", [3, 12, 8, 0]],
    ["terminalAttempts", "STR_PMCI_SET_TERMINAL_ATTEMPTS", [1, 8, 4, 0]],
    ["safeLimit", "STR_PMCI_SET_SAFE_LIMIT", [10, 300, 90, 0]], ["safeTolerance", "STR_PMCI_SET_SAFE_TOLERANCE", [0.5, 8, 2, 1]],
    ["safeMistakes", "STR_PMCI_SET_SAFE_MISTAKES", [0, 10, 2, 0]], ["safeNoise", "STR_PMCI_SET_SAFE_NOISE", [0, 0.5, 0.12, 2]]
];
["PMCI_lockpickTwo", "LIST", [localize "STR_PMCI_SET_LOCKPICK_TWO", localize "STR_PMCI_SET_LOCKPICK_TWO_TIP"], _locks,
    [[1, 2, 3], [localize "STR_PMCI_TWO_NORMAL", localize "STR_PMCI_TWO_HARD", localize "STR_PMCI_TWO_NEVER"], 1], 1] call CBA_fnc_addSetting;
// Keys of the boards, in CBA's controls (Configure Addons -> PMC Interactions). The board
// reads them itself (PMCI_fnc_keyIs); outside a board they do nothing.
["PMC Interactions", "pmci_press", [localize "STR_PMCI_KEY_PRESS", localize "STR_PMCI_KEY_PRESS_TIP"], {false}, {false}, [57, [false, false, false]]] call CBA_fnc_addKeybind;
["PMC Interactions", "pmci_fix", [localize "STR_PMCI_KEY_FIX", localize "STR_PMCI_KEY_FIX_TIP"], {false}, {false}, [28, [false, false, false]]] call CBA_fnc_addKeybind;

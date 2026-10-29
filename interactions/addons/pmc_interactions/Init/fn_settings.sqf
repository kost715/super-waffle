// preInit, every machine: CBA mod settings. The server's values apply to everyone. The
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
        ["ribChance", "STR_PMCI_SET_RIB_CHANCE", [0, 1, 0.15, 2]], ["ribMax", "STR_PMCI_SET_RIB_MAX", [0, 5, 1, 0]]]],
    ["tourniquet", [["tourniquetLimit", "STR_PMCI_SET_LIMIT", [5, 120, 25, 0]]]],
    ["bandage", [["bandageLimit", "STR_PMCI_SET_LIMIT", [5, 120, 30, 0]], ["bandageEffect", "STR_PMCI_SET_BANDAGE_EFFECT", [0, 1, 0.4, 2]]]],
    ["pressure", [["pressureLimit", "STR_PMCI_SET_LIMIT", [5, 120, 30, 0]]]],
    ["edges", [["edgesLimit", "STR_PMCI_SET_LIMIT", [5, 120, 30, 0]]]],
    ["clean", [["cleanLimit", "STR_PMCI_SET_LIMIT", [5, 120, 40, 0]]]],
    ["wheel", [["nutTime", "STR_PMCI_SET_NUT_TIME", [0.2, 3, 0.8, 1]], ["swapTime", "STR_PMCI_SET_SWAP_TIME", [0.5, 10, 3, 1]]]]
];

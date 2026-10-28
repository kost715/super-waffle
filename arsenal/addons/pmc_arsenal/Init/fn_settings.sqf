// preInit, every machine: CBA mod settings. The server's values apply to everyone.
private _category = localize "STR_PMCA_SET_CATEGORY";
["PMCA_debugMode", "CHECKBOX", [localize "STR_PMCA_SET_DEBUG", localize "STR_PMCA_SET_DEBUG_TIP"],
    _category, false, 1] call CBA_fnc_addSetting;
// An item whose stock reaches this many pieces (magazines: full magazines) becomes unlimited.
["PMCA_unlockThreshold", "LIST", [localize "STR_PMCA_SET_UNLOCK", localize "STR_PMCA_SET_UNLOCK_TIP"],
    _category, [[0, 5, 20, 50], [localize "STR_PMCA_SET_UNLOCK_NEVER", "5", "20", "50"], 0], 1, {
        if (isServer && {!isNil "PMCA_storages"}) then {{[_x] call PMCA_fnc_unlock} forEach keys PMCA_storages};
    }] call CBA_fnc_addSetting;
["PMCA_accessMode", "LIST", [localize "STR_PMCA_SET_ACCESS", localize "STR_PMCA_SET_ACCESS_TIP"],
    [_category, localize "STR_PMCA_SET_ACCESS_GROUP"], [[0, 1], [localize "STR_PMCA_SET_ACCESS_ALL", localize "STR_PMCA_SET_ACCESS_SIDE"], 0], 1
] call CBA_fnc_addSetting;
// PMCA_access_<side>_<category>, side as in str side: west, east, guer, civ.
{
    _x params ["_side", "_sideName"];
    {
        ["PMCA_access_" + _side + "_" + _x, "CHECKBOX", localize ("STR_PMCA_SET_CAT_" + _x),
            [_category, format [localize "STR_PMCA_SET_SIDE", _sideName]], true, 1] call CBA_fnc_addSetting;
    } forEach ["weapons", "launchers", "explosives", "equipment"];
} forEach [["west", "BLUFOR"], ["east", "OPFOR"], ["guer", "INDFOR"], ["civ", localize "STR_PMCA_SET_CIV"]];

// CBA preInit (Extended_PreInit_EventHandlers), every machine, also in Eden and the main
// menu: the mod's settings, forced by the server.
private _category = localize "STR_PMCS_SET_CATEGORY";
["PMCS_useDistance", "SLIDER", localize "STR_PMCS_SET_DISTANCE", _category, [2, 10, 4, 0], 1] call CBA_fnc_addSetting;
["PMCS_logLimit", "SLIDER", localize "STR_PMCS_SET_LOG", _category, [20, 500, 100, 0], 1] call CBA_fnc_addSetting;
// Prices: goods are bought by the box at the base price; one piece alone costs more.
["PMCS_weaponBoxUnits", "SLIDER", [localize "STR_PMCS_SET_WEAPON_BOX", localize "STR_PMCS_SET_WEAPON_BOX_TIP"], _category, [1, 20, 4, 0], 1] call CBA_fnc_addSetting;
["PMCS_weaponUnitMarkup", "SLIDER", [localize "STR_PMCS_SET_WEAPON_UNIT", localize "STR_PMCS_SET_WEAPON_UNIT_TIP"], _category, [0, 300, 60, 0], 1] call CBA_fnc_addSetting;
["PMCS_magBoxUnits", "SLIDER", localize "STR_PMCS_SET_MAG_BOX", _category, [1, 100, 30, 0], 1] call CBA_fnc_addSetting;
["PMCS_magUnitMarkup", "SLIDER", [localize "STR_PMCS_SET_MAG_UNIT", localize "STR_PMCS_SET_MAG_UNIT_TIP"], _category, [0, 200, 30, 0], 1] call CBA_fnc_addSetting;

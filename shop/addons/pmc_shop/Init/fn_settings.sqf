// CBA preInit (Extended_PreInit_EventHandlers), every machine, also in Eden and the main
// menu: the mod's settings, forced by the server.
private _category = localize "STR_PMCS_SET_CATEGORY";
["PMCS_useDistance", "SLIDER", localize "STR_PMCS_SET_DISTANCE", _category, [2, 10, 4, 0], 1] call CBA_fnc_addSetting;
["PMCS_logLimit", "SLIDER", localize "STR_PMCS_SET_LOG", _category, [20, 500, 100, 0], 1] call CBA_fnc_addSetting;

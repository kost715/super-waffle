// preInit, every machine: CBA mod settings. The server's values apply to everyone.
private _category = localize "STR_PMCB_SET_CATEGORY";
["PMCB_notes", "EDITBOX", [localize "STR_PMCB_SET_NOTES", localize "STR_PMCB_SET_NOTES_TIP"], _category, "", 1] call CBA_fnc_addSetting;
["PMCB_currency", "EDITBOX", localize "STR_PMCB_SET_CURRENCY", _category, "$", 1] call CBA_fnc_addSetting;
["PMCB_groupName", "EDITBOX", localize "STR_PMCB_SET_GROUP", _category, localize "STR_PMCB_SET_GROUP_DEFAULT", 1] call CBA_fnc_addSetting;
["PMCB_startBalance", "SLIDER", [localize "STR_PMCB_SET_START", localize "STR_PMCB_SET_START_TIP"], _category, [0, 1000000, 0, 0], 1] call CBA_fnc_addSetting;
["PMCB_logLimit", "SLIDER", [localize "STR_PMCB_SET_LOG", localize "STR_PMCB_SET_LOG_TIP"], _category, [100, 10000, 2000, 0], 1] call CBA_fnc_addSetting;

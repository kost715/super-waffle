// preInit, every machine: CBA mod settings. The server's values apply to everyone.
private _category = localize "STR_PMCB_SET_CATEGORY";
// Default: the banknotes of ARES Military Roleplay Items (ARPI); skipped when ARPI is not loaded.
["PMCB_notes", "EDITBOX", [localize "STR_PMCB_SET_NOTES", localize "STR_PMCB_SET_NOTES_TIP"], _category,
    "ar_money_1000dollar:1000, ar_money_500dollar:500, ar_money_200dollar:200, ar_money_100dollar:100, ar_money_50dollar:50, ar_money_25dollar:25, ar_money_5dollar:5", 1] call CBA_fnc_addSetting;
["PMCB_currency", "EDITBOX", localize "STR_PMCB_SET_CURRENCY", _category, "$", 1] call CBA_fnc_addSetting;
["PMCB_groupName", "EDITBOX", localize "STR_PMCB_SET_GROUP", _category, localize "STR_PMCB_SET_GROUP_DEFAULT", 1] call CBA_fnc_addSetting;
["PMCB_startBalance", "SLIDER", [localize "STR_PMCB_SET_START", localize "STR_PMCB_SET_START_TIP"], _category, [0, 1000000, 0, 0], 1] call CBA_fnc_addSetting;
["PMCB_logLimit", "SLIDER", [localize "STR_PMCB_SET_LOG", localize "STR_PMCB_SET_LOG_TIP"], _category, [100, 10000, 2000, 0], 1] call CBA_fnc_addSetting;

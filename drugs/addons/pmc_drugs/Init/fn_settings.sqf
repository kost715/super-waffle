// preInit, every machine: CBA settings, forced by the server. Defaults are those of the
// spec; every drug function reads its values from here (missionNamespace "PMCD_...").
private _category = localize "STR_PMCD_SET_CATEGORY";
private _stim = [_category, localize "STR_PMCD_SET_STIM"];
private _damage = [_category, localize "STR_PMCD_SET_STIM_DAMAGE"];
private _overdose = [_category, localize "STR_PMCD_SET_OVERDOSE"];
private _debt = [_category, localize "STR_PMCD_SET_DEBT"];
{
    _x params ["_name", "_title", "_group", "_range"];
    ["PMCD_" + _name, "SLIDER", localize _title, _group, _range, 1] call CBA_fnc_addSetting;
} forEach [
    ["stimDuty", "STR_PMCD_SET_STIM_DUTY", _stim, [0.1, 1, 0.5, 2]],
    ["stimTime20", "STR_PMCD_SET_STIM_TIME20", _stim, [1, 60, 14, 0]],
    ["stimTime40", "STR_PMCD_SET_STIM_TIME40", _stim, [1, 60, 12, 0]],
    ["stimTime70", "STR_PMCD_SET_STIM_TIME70", _stim, [1, 60, 10, 0]],
    ["loadLight", "STR_PMCD_SET_LOAD_LIGHT", _stim, [5, 100, 30, 0]],
    ["loadHeavy", "STR_PMCD_SET_LOAD_HEAVY", _stim, [5, 150, 55, 0]],
    ["stimThirst", "STR_PMCD_SET_STIM_THIRST", _stim, [1, 10, 3, 1]],
    ["stimInject", "STR_PMCD_SET_INJECT", _stim, [0.5, 10, 2, 1]],
    ["stimDamage1_20", "STR_PMCD_SET_DMG1_20", _damage, [0, 1, 0.15, 2]],
    ["stimDamage1_40", "STR_PMCD_SET_DMG1_40", _damage, [0, 1, 0.2, 2]],
    ["stimDamage1_70", "STR_PMCD_SET_DMG1_70", _damage, [0, 1, 0.25, 2]],
    ["stimDamage2_20", "STR_PMCD_SET_DMG2_20", _damage, [0, 1, 0.25, 2]],
    ["stimDamage2_40", "STR_PMCD_SET_DMG2_40", _damage, [0, 1, 0.3, 2]],
    ["stimDamage2_70", "STR_PMCD_SET_DMG2_70", _damage, [0, 1, 0.35, 2]],
    ["stimDamage3_20", "STR_PMCD_SET_DMG3_20", _damage, [0, 1, 0.2, 2]],
    ["stimDamage3_40", "STR_PMCD_SET_DMG3_40", _damage, [0, 1, 0.25, 2]],
    ["stimDamage3_70", "STR_PMCD_SET_DMG3_70", _damage, [0, 1, 0.3, 2]],
    ["stimDamage4_20", "STR_PMCD_SET_DMG4_20", _damage, [0, 1, 0.15, 2]],
    ["stimDamage4_40", "STR_PMCD_SET_DMG4_40", _damage, [0, 1, 0.2, 2]],
    ["stimDamage4_70", "STR_PMCD_SET_DMG4_70", _damage, [0, 1, 0.25, 2]],
    ["overdosePulse", "STR_PMCD_SET_OD_PULSE", _overdose, [50, 300, 200, 0]],
    ["overdoseRampMin", "STR_PMCD_SET_OD_RAMP_MIN", _overdose, [5, 120, 30, 0]],
    ["overdoseRampMax", "STR_PMCD_SET_OD_RAMP_MAX", _overdose, [5, 120, 50, 0]],
    ["overdoseDeathMin", "STR_PMCD_SET_OD_DEATH_MIN", _overdose, [10, 600, 60, 0]],
    ["overdoseDeathMax", "STR_PMCD_SET_OD_DEATH_MAX", _overdose, [10, 600, 120, 0]],
    ["debtBaseWork", "STR_PMCD_SET_DEBT_WORK", _debt, [100, 1000, 400, 0]],
    ["debtFactor", "STR_PMCD_SET_DEBT_FACTOR", _debt, [0, 2, 0.5, 2]],
    ["debtPaybackFloor", "STR_PMCD_SET_FLOOR", _debt, [0.3, 0.5, 0.4, 2]],
    ["paybackStim", "STR_PMCD_SET_PAY_STIM", _debt, [0.5, 20, 4, 1]],
    ["paybackFen", "STR_PMCD_SET_PAY_FEN", _debt, [0.5, 20, 2.5, 1]]
];
["PMCD_stimFillAN", "CHECKBOX", [localize "STR_PMCD_SET_STIM_FILL", localize "STR_PMCD_SET_STIM_FILL_TIP"], _stim, true, 1] call CBA_fnc_addSetting;

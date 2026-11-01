// preInit, every machine: CBA settings. The drug's numbers are forced by the server
// (defaults of the spec); the icons and the debug panel are each player's own.
private _category = localize "STR_PMCD_SET_CATEGORY";
private _stim = [_category, localize "STR_PMCD_SET_STIM"];
private _debt = [_category, localize "STR_PMCD_SET_DEBT"];
private _hud = [_category, localize "STR_PMCD_SET_HUD"];
{
    _x params ["_name", "_title", "_group", "_range"];
    ["PMCD_" + _name, "SLIDER", localize _title, _group, _range, 1] call CBA_fnc_addSetting;
} forEach [
    ["stimDuty", "STR_PMCD_SET_STIM_DUTY", _stim, [0.1, 1, 0.5, 2]],
    ["stimBaseDamage", "STR_PMCD_SET_BASE_DAMAGE", _stim, [0.1, 0.25, 0.16, 3]],
    ["stimPool", "STR_PMCD_SET_POOL", _stim, [600, 1200, 900, 0]],
    ["stimBevelA", "STR_PMCD_SET_BEVEL_A", _stim, [1, 4, 2, 2]],
    ["stimBevelK", "STR_PMCD_SET_BEVEL_K", _stim, [0.5, 2, 1, 2]],
    ["stimWeightMin", "STR_PMCD_SET_WEIGHT_MIN", _stim, [0, 10, 5, 0]],
    ["stimWeightMax", "STR_PMCD_SET_WEIGHT_MAX", _stim, [60, 100, 80, 0]],
    ["stimThirst", "STR_PMCD_SET_STIM_THIRST", _stim, [1, 10, 3, 1]],
    ["stimInject", "STR_PMCD_SET_INJECT", _stim, [0.5, 10, 2, 1]],
    ["stimPulse", "STR_PMCD_SET_PULSE", _stim, [0, 150, 75, 0]],
    ["stimPulseRamp", "STR_PMCD_SET_PULSE_RAMP", _stim, [1, 60, 10, 0]],
    ["debtFactor", "STR_PMCD_SET_DEBT_FACTOR", _debt, [0, 2, 1, 2]],
    ["paybackMultiplier", "STR_PMCD_SET_PAYBACK", _debt, [8, 25, 15, 1]],
    ["ae2Floor", "STR_PMCD_SET_AE2_FLOOR", _debt, [0.15, 0.4, 0.25, 2]]
];
["PMCD_stimFillAN", "CHECKBOX", [localize "STR_PMCD_SET_STIM_FILL", localize "STR_PMCD_SET_STIM_FILL_TIP"], _stim, true, 1] call CBA_fnc_addSetting;
// Each player's own: where the icons are and whether the debug panel is on.
["PMCD_hudShow", "CHECKBOX", localize "STR_PMCD_SET_HUD_SHOW", _hud, true, 0] call CBA_fnc_addSetting;
["PMCD_hudX", "SLIDER", localize "STR_PMCD_SET_HUD_X", _hud, [0, 1, 0.94, 3], 0] call CBA_fnc_addSetting;
["PMCD_hudY", "SLIDER", localize "STR_PMCD_SET_HUD_Y", _hud, [0, 1, 0.82, 3], 0] call CBA_fnc_addSetting;
["PMCD_hudSize", "SLIDER", localize "STR_PMCD_SET_HUD_SIZE", _hud, [0.02, 0.1, 0.045, 3], 0] call CBA_fnc_addSetting;
["PMCD_debugOn", "CHECKBOX", [localize "STR_PMCD_SET_DEBUG", localize "STR_PMCD_SET_DEBUG_TIP"], _hud, false, 0] call CBA_fnc_addSetting;

// postInit, every machine: the Zeus module's events; on players also the per-second drug
// loop (PMCD_fnc_tick), the one duty factor of all drugs for ACE Advanced Fatigue, the
// thirst of an active Stim1f (ACE Field Rations, when loaded), Fentropil's sway factor
// (ACE) and its cut of new pain (ACE Medical, when loaded), and the self-injections of
// Stim1f, Fentropil, meldonium and the hemostatic (its cut of blood loss, ACE Medical).
["PMCD_muscleCheck", {_this call PMCD_fnc_muscleCheck}] call CBA_fnc_addEventHandler;
["PMCD_muscleSet", {_this call PMCD_fnc_muscleSet}] call CBA_fnc_addEventHandler;
["PMCD_muscleShow", {_this call PMCD_fnc_muscleShow}] call CBA_fnc_addEventHandler;
if (!hasInterface) exitWith {};
[{call PMCD_fnc_tick}, 1] call CBA_fnc_addPerFrameHandler;
["PMCD_drugs", {
    private _state = _this getVariable "PMCD_state";
    if (isNil "_state") then {1} else {[[_state, CBA_missionTime] call PMCD_fnc_effects] call PMCD_fnc_duty}
}] call ace_advanced_fatigue_fnc_addDutyFactor;
if (!isNil "ace_field_rations_fnc_addStatusModifier") then {
    [0, {[_this] call PMCD_fnc_thirst}] call ace_field_rations_fnc_addStatusModifier;
};
// Fentropil: aim sway x (1 - 0.15 g), g kept by the tick.
if (!isNil "ace_common_fnc_addSwayFactor") then {
    ["multiplier", {0 max (1 - (missionNamespace getVariable ["PMCD_fenSway", 0.15]) * (missionNamespace getVariable ["PMCD_fenG", 0]))}, "PMCD_fen"]
        call ace_common_fnc_addSwayFactor;
};
["ace_medical_injured", {_this call PMCD_fnc_fenPain}] call CBA_fnc_addEventHandler;
// Hemostatic: ACE Medical's blood loss of the unit, cut while it acts.
["ace_medical_status_getBloodLoss", {_this call PMCD_fnc_hemoBleed}] call CBA_fnc_addEventHandler;
private _action = ["PMCD_takeStim", localize "STR_PMCD_TAKE_STIM", "\pmc_drugs\data\stim1f_ca.paa", {
    params ["", "_player"];
    [missionNamespace getVariable ["PMCD_stimInject", 2], [_player], {(_this select 0) params ["_unit"]; [_unit] call PMCD_fnc_takeStim}, {},
        localize "STR_PMCD_INJECTING"] call ace_common_fnc_progressBar;
}, {params ["", "_player"]; [_player] call PMCD_fnc_canTake}] call ace_interact_menu_fnc_createAction;
["CAManBase", 1, ["ACE_SelfActions", "ACE_Equipment"], _action, true] call ace_interact_menu_fnc_addActionToClass;
private _fen = ["PMCD_takeFen", localize "STR_PMCD_TAKE_FEN", "\pmc_drugs\data\fentropil_ca.paa", {
    params ["", "_player"];
    [missionNamespace getVariable ["PMCD_fenInject", 2], [_player], {(_this select 0) params ["_unit"]; [_unit] call PMCD_fnc_takeFen}, {},
        localize "STR_PMCD_INJECTING"] call ace_common_fnc_progressBar;
}, {params ["", "_player"]; [_player, "PMCD_Fentropil"] call PMCD_fnc_canTake}] call ace_interact_menu_fnc_createAction;
["CAManBase", 1, ["ACE_SelfActions", "ACE_Equipment"], _fen, true] call ace_interact_menu_fnc_addActionToClass;
private _meld = ["PMCD_takeMeld", localize "STR_PMCD_TAKE_MELD", "\pmc_drugs\data\meldonium_ca.paa", {
    params ["", "_player"];
    [missionNamespace getVariable ["PMCD_meldInject", 2], [_player], {(_this select 0) params ["_unit"]; [_unit] call PMCD_fnc_takeMeld}, {},
        localize "STR_PMCD_INJECTING"] call ace_common_fnc_progressBar;
}, {params ["", "_player"]; [_player, "PMCD_Meldonium"] call PMCD_fnc_canTake}] call ace_interact_menu_fnc_createAction;
["CAManBase", 1, ["ACE_SelfActions", "ACE_Equipment"], _meld, true] call ace_interact_menu_fnc_addActionToClass;
private _hemo = ["PMCD_takeHemo", localize "STR_PMCD_TAKE_HEMO", "\pmc_drugs\data\hemostatic_ca.paa", {
    params ["", "_player"];
    [missionNamespace getVariable ["PMCD_hemoInject", 2], [_player], {(_this select 0) params ["_unit"]; [_unit] call PMCD_fnc_takeHemo}, {},
        localize "STR_PMCD_INJECTING"] call ace_common_fnc_progressBar;
}, {params ["", "_player"]; [_player, "PMCD_Hemostatic"] call PMCD_fnc_canTake}] call ace_interact_menu_fnc_createAction;
["CAManBase", 1, ["ACE_SelfActions", "ACE_Equipment"], _hemo, true] call ace_interact_menu_fnc_addActionToClass;

// postInit, every machine: the Zeus module's events; on players also the per-second drug
// loop (PMCD_fnc_tick), the one duty factor of all drugs for ACE Advanced Fatigue, the
// thirst of an active Stim1f (ACE Field Rations, when loaded) and the self-injection.
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
private _action = ["PMCD_takeStim", localize "STR_PMCD_TAKE_STIM", "\z\ace\addons\medical_treatment\ui\epinephrine_ca.paa", {
    params ["", "_player"];
    [2, [_player], {(_this select 0) params ["_unit"]; [_unit] call PMCD_fnc_takeStim}, {}, localize "STR_PMCD_INJECTING"] call ace_common_fnc_progressBar;
}, {params ["", "_player"]; [_player] call PMCD_fnc_canTake}] call ace_interact_menu_fnc_createAction;
["CAManBase", 1, ["ACE_SelfActions", "ACE_Equipment"], _action, true] call ace_interact_menu_fnc_addActionToClass;

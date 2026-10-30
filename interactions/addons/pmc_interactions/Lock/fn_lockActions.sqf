// [box] -> nothing. Client, once per box: ACE interactions "Lock" with "Open with the key"
// (classic lock with a key set), "Enter the code" (code lock, safe) and "Pick / hack the
// lock". They show only while the box is locked (PMCI_lock).
params ["_box"];
if (isNil "ace_interact_menu_fnc_createAction" || {_box getVariable ["PMCI_lockActions", false]}) exitWith {};
_box setVariable ["PMCI_lockActions", true];
private _path = [[], ["ACE_MainActions"]] select isClass (configOf _box >> "ACE_Actions" >> "ACE_MainActions");
private _root = ["PMCI_lock", localize "STR_PMCI_LOCK_ACTION", "\pmc_interactions\data\icon_lock_ca.paa", {},
    {params ["_target"]; (_target getVariable ["PMCI_lock", []]) isNotEqualTo []}] call ace_interact_menu_fnc_createAction;
[_box, 0, _path, _root] call ace_interact_menu_fnc_addActionToObject;
{
    _x params ["_name", "_title", "_icon", "_statement", "_condition"];
    private _action = [_name, localize _title, format ["\pmc_interactions\data\%1_ca.paa", _icon], _statement, _condition] call ace_interact_menu_fnc_createAction;
    [_box, 0, _path + ["PMCI_lock"], _action] call ace_interact_menu_fnc_addActionToObject;
} forEach [
    ["PMCI_lockKey", "STR_PMCI_LOCK_USE_KEY", "icon_key",
        {params ["_target", "_player"]; [_player, _target, "key"] remoteExecCall ["PMCI_fnc_lockOpen", 2]},
        {params ["_target"]; (_target getVariable ["PMCI_lock", []]) params [["_type", ""], "", ["_key", ""]]; _type == "classic" && {_key != ""}}],
    ["PMCI_lockCode", "STR_PMCI_LOCK_ENTER_CODE", "icon_keypad",
        {params ["_target"]; ["open", _target] call PMCI_fnc_lockKeypad},
        {params ["_target"]; ((_target getVariable ["PMCI_lock", []]) param [0, ""]) in ["code", "safe"]}],
    ["PMCI_lockHack", "STR_PMCI_LOCK_HACK", "icon_lock",
        {params ["_target", "_player"]; [_player, _target] call PMCI_fnc_lockHack},
        {params ["_target"]; (_target getVariable ["PMCI_lock", []]) isNotEqualTo []}]
];

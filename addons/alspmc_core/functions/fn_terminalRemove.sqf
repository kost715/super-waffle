params ["_key"];
if (!isServer) exitWith {};
private _registry = missionNamespace getVariable ["ALSPMC_terminals", createHashMap];
private _old = _registry getOrDefault [_key, [objNull, []]];
{if (!isNull _x) then {deleteVehicle _x}} forEach (_old select 1);
_registry deleteAt _key;
private _layouts = missionNamespace getVariable ["ALSPMC_workstations", createHashMap];
_layouts deleteAt _key;
if (missionNamespace getVariable ["ALSPMC_workstationsReady", false]) then {
    ["alspmc_workstations_v1", (keys _layouts) apply {[_x, _layouts get _x]}] call ALS_fnc_dbSet;
    ALSPMC_terminalsPublic = (keys _registry) apply {[_x, (_registry get _x) select 0]};
    publicVariable "ALSPMC_terminalsPublic";
};

/*
Author: Jeroen Notenbomer; server-side checks: LifeSim PMC project
    Moves the contents of a crate or vehicle into the arsenal's storage.
    Called by the "move from crate to arsenal" button for the arsenal object's own
    inventory. The server reads and clears the cargo itself; the client only names
    the objects, within reach of the arsenal.
Arguments:
    <OBJECT> Unit asking
    <OBJECT> Arsenal object
    <OBJECT> Crate or vehicle to empty into the storage
Scope: Server
Example:
    [player, _arsenal, _arsenal] remoteExecCall ["PMCA_fnc_arsenal_cargoToArsenal", 2];
*/
if (!isServer) exitWith {};
call PMCA_fnc_serverLoad;
params [["_unit", objNull, [objNull]], ["_object", objNull, [objNull]], ["_container", objNull, [objNull]]];
private _owner = call PMCA_fnc_requestOwner;
if (isNull _unit || {!alive _unit} || {isRemoteExecuted && {owner _unit != _owner}}) exitWith {};
private _id = _object getVariable ["PMCA_storage", ""];
private _storage = PMCA_storages getOrDefault [_id, createHashMap];
if (count _storage == 0 || {_unit distance _object > 6} || {isNull _container} || {_container isKindOf "CAManBase"} || {
    _container distance _object > 50
} || {lockedInventory _container}) exitWith {["STR_PMCA_ERR_CONTAINER", []] remoteExecCall ["PMCA_fnc_notify", _owner]};
if (isNil { // Run in unscheduled scope.
    if (_container getVariable ["PMCA_cargoToArsenal_busy", false]) then {
        nil;  // will lead to exit.
    } else {
        _container setVariable ["PMCA_cargoToArsenal_busy", true];
        0;  // not nil, will allow script to continue.
    };
}) exitWith {};  // Silent exit, likely due to spamming
private _items = [_container] call PMCA_fnc_cargoItems;
clearMagazineCargoGlobal _container;
clearItemCargoGlobal _container;
clearWeaponCargoGlobal _container;
clearBackpackCargoGlobal _container;
private _stock = _storage get "items";
private _rows = [];
{
    private _have = _stock getOrDefault [_x, 0];
    if (_have != -1) then {_stock set [_x, _have + _y]};
    _rows pushBack [_x, _y];
} forEach _items;
if (_rows isNotEqualTo [] && {_storage getOrDefault ["persist", true]}) then {PMCA_dirty = true};
[_id, _rows, true, []] call PMCA_fnc_broadcast;
_container setVariable ["PMCA_cargoToArsenal_busy", false];

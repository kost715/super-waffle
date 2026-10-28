/*
	Author: Jeroen Notenbomer; server-side sessions: LifeSim PMC project

	Description:
	Server. Opens the arsenal of a storage for the requesting client: the personal
	arsenal ("arsenal") or the cargo of a nearby vehicle/crate ("container").
	Records what the unit or container holds now; stock changes only when the
	session closes (PMCA_fnc_commit).

	Parameter(s):
	[unit, arsenal object, kind, container]
*/
#include "..\defineCommon.inc"
if (!isServer) exitWith {};
call PMCA_fnc_serverLoad;
params [["_unit", objNull, [objNull]], ["_object", objNull, [objNull]], ["_kind", "arsenal", [""]], ["_container", objNull, [objNull]], ["_claim", [], [[]]]];
private _owner = call PMCA_fnc_requestOwner;
private _deny = {
	params ["_reason"];
	[_reason, []] remoteExecCall ["PMCA_fnc_notify", _owner];
	["Abort"] remoteExecCall ["PMCA_fnc_arsenal", _owner];
};
if (isNull _unit || {!alive _unit} || {isRemoteExecuted && {owner _unit != _owner}}) exitWith {};
private _id = _object getVariable ["PMCA_storage", ""];
if (_id == "" || {!(_id in PMCA_storages)}) exitWith {["STR_PMCA_ERR_NO_STORAGE"] call _deny};
if (_unit distance _object > 6 || {!isNull objectParent _unit}) exitWith {["STR_PMCA_ERR_TOO_FAR"] call _deny};
// A session that never closed (crash, lost packet) is settled with what the server sees.
if (_owner in PMCA_sessions) then {[_owner, nil] call PMCA_fnc_commit};
private _tabs = [_unit, _id] call PMCA_fnc_allowedTabs;
if (_tabs isEqualTo false) exitWith {["STR_PMCA_ERR_NO_ACCESS"] call _deny};
if (_kind == "container") then {
	private _type = typeOf _container;
	private _capacity = 0;
	{_capacity = _capacity + getNumber (configFile >> "CfgVehicles" >> _type >> _x)} forEach ["transportMaxBackpacks", "transportMaxMagazines", "transportMaxWeapons"];
	if (isNull _container || {!alive _container} || {_container isKindOf "CAManBase"} || {_capacity <= 0} || {
		_container distance _object > 50
	} || {lockedInventory _container} || {(values PMCA_sessions) findIf {(_x get "container") isEqualTo _container} >= 0}) exitWith {_kind = ""};
	_container lockInventory true;
} else {
	if (_kind != "arsenal") then {_kind = ""};
};
if (_kind == "") exitWith {["STR_PMCA_ERR_CONTAINER"] call _deny};
PMCA_sessionSeq = (missionNamespace getVariable ["PMCA_sessionSeq", 0]) + 1;
private _session = createHashMapFromArray [
	["token", PMCA_sessionSeq], ["storage", _id], ["object", _object], ["unit", _unit], ["kind", _kind],
	["container", _container], ["tabs", _tabs], ["preview", createHashMap], ["opening", true]
];
PMCA_sessions set [_owner, _session];
// The opening snapshot is what the server sees. Recent pickups or drops may not
// have reached it yet; wait briefly for the state the client reports (the claim
// only decides how long to wait, never what is recorded).
[_owner, _session, _claim] spawn {
	params ["_owner", "_session", "_claim"];
	private _isUnit = (_session get "kind") == "arsenal";
	private _unit = _session get "unit";
	private _view = {
		if (_isUnit) then {[getUnitLoadout _unit] call PMCA_fnc_loadoutItems} else {[_session get "container"] call PMCA_fnc_cargoItems}
	};
	private _before = call _view;
	if (_isUnit && {count _claim >= 10}) then {
		private _claimed = [_claim] call PMCA_fnc_loadoutItems;
		private _until = diag_tickTime + 3;
		while {diag_tickTime < _until && {!isNull _unit} && {
			count _before != count _claimed || {((keys _before) findIf {(_claimed getOrDefault [_x, -1]) != (_before get _x)}) >= 0}
		}} do {
			sleep 0.25;
			_before = call _view;
		};
	};
	private _list = [];
	isNil {
		if (((PMCA_sessions getOrDefault [_owner, createHashMap]) getOrDefault ["token", -1]) != (_session get "token")) exitWith {};
		_session set ["before", _before];
		_session set ["loadout", getUnitLoadout _unit];
		_session deleteAt "opening";
		_list = [_session get "storage", _session get "tabs"] call PMCA_fnc_storageList;
	};
	if (_session getOrDefault ["opening", false]) exitWith {};
	["Open", [_list, _session get "object", _session get "kind", _session get "container"]] remoteExecCall ["PMCA_fnc_arsenal", _owner];
};

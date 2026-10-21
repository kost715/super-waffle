params ["_key"];
if (!isServer || {!(missionNamespace getVariable ["ALSPMC_workstationsReady", false])} || {!(_key in ALSPMC_bases)}) exitWith {objNull};
private _old = ALSPMC_terminals getOrDefault [_key, [objNull, []]];
if (!isNull (_old select 0) && {count (_old select 1) == 4} && {((_old select 1) findIf {isNull _x}) < 0}) exitWith {_old select 0};
// Clean up a partially removed station without discarding its saved layout.
{if (!isNull _x) then {deleteVehicle _x}} forEach (_old select 1);
private _classes = ["terminalDesk", "terminalScreen", "terminalCase", "terminalKeyboard"] apply {
    getText (configFile >> "ALSPMC_Settings" >> _x)
};
if ((_classes findIf {!isClass (configFile >> "CfgVehicles" >> _x)}) >= 0) exitWith {
    ["ALSPMC: vanilla desktop models unavailable; workstation creation deferred"] call ALS_fnc_log;
    objNull
};
private _layout = ALSPMC_workstations getOrDefault [_key, []];
if (_layout isEqualTo []) then {_layout = [_key] call ALSPMC_fnc_terminalFindSpot};
if (_layout isEqualTo []) exitWith {objNull};
_layout params ["_floor", "_heading"];
private _right = [cos _heading, -sin _heading, 0];
private _forward = [sin _heading, cos _heading, 0];
private _objects = [];
private _put = {
    params ["_class", "_local", "_bottom", "_turn"];
    private _obj = createVehicle [_class, [0,0,0], [], 0, "CAN_COLLIDE"];
    if (isNull _obj) exitWith {objNull};
    _obj enableSimulationGlobal false;
    _obj allowDamage false;
    private _low = ((boundingBoxReal _obj) select 0) select 2;
    private _pos = _floor vectorAdd (_right vectorMultiply (_local select 0)) vectorAdd (_forward vectorMultiply (_local select 1));
    _pos set [2, (_floor select 2) + _bottom - _low];
    _obj setDir (_heading + _turn);
    _obj setPosASL _pos;
    _obj setVariable ["ALSPMC_workspaceKey", _key, true];
    _objects pushBack _obj;
    _obj
};
private _desk = [_classes select 0, [0,0], 0, 0] call _put;
if (isNull _desk) exitWith {objNull};
private _bounds = boundingBoxReal _desk;
private _top = (((_bounds select 1) select 2) - ((_bounds select 0) select 2));
private _computer = [_classes select 1, [0,0.12], _top + 0.01, 180] call _put;
[_classes select 2, [0.45,0.1], 0.01, 180] call _put;
[_classes select 3, [0,-0.2], _top + 0.01, 180] call _put;
if (count _objects != 4 || {isNull _computer}) exitWith {{deleteVehicle _x} forEach _objects; objNull};
_computer setVariable ["ALSPMC_terminalKey", _key, true];
ALSPMC_terminals set [_key, [_computer, _objects]];
ALSPMC_workstations set [_key, _layout];
["alspmc_workstations_v1", (keys ALSPMC_workstations) apply {[_x, ALSPMC_workstations get _x]}] call ALS_fnc_dbSet;
ALSPMC_terminalsPublic = (keys ALSPMC_terminals) apply {[_x, (ALSPMC_terminals get _x) select 0]};
publicVariable "ALSPMC_terminalsPublic";
_computer

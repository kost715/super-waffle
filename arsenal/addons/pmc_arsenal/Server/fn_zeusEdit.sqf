// [Zeus unit, storageID, class, action, value] -> nothing. Zeus stock window -> server.
// Changes one item already in stock; magazines are counted in full magazines:
//   "remove"    - take value away (at least 1; not from an unlimited item)
//   "set"       - exactly value (0 removes the item)
//   "unlimited" - make the item unlimited
//   "clear"     - remove the item
// The threshold setting does not apply: Zeus sets what Zeus wants. Logged to the RPT;
// open arsenals show the new count at once.
if (!isServer) exitWith {};
call PMCA_fnc_serverLoad;
params [["_zeus", objNull, [objNull]], ["_id", "", [""]], ["_class", "", [""]], ["_action", "", [""]], ["_value", 0, [0]]];
private _owner = [_zeus] call PMCA_fnc_zeusCaller;
if (_owner < 0) exitWith {};
private _deny = {[_this, []] remoteExecCall ["PMCA_fnc_notify", _owner]};
private _storage = PMCA_storages getOrDefault [_id, createHashMap];
private _items = _storage getOrDefault ["items", createHashMap];
if !(_class in _items) exitWith {"STR_PMCA_ERR_STOCK_ITEM" call _deny};
if !(_value >= 0 && {_value == floor _value} && {_value < 1e7} && {_action != "remove" || {_value >= 1}}) exitWith {"STR_PMCA_ERR_STOCK_AMOUNT" call _deny};
private _size = 1;
if (isClass (configFile >> "CfgMagazines" >> _class)) then {_size = (getNumber (configFile >> "CfgMagazines" >> _class >> "count")) max 1};
private _old = _items get _class;
private _new = switch (_action) do {
    case "remove": {if (_old == -1) then {-2} else {0 max (_old - _value * _size)}};
    case "set": {_value * _size};
    case "unlimited": {-1};
    case "clear": {0};
    default {-3};
};
if (_new == -3) exitWith {};
if (_new == -2) exitWith {"STR_PMCA_ERR_STOCK_UNLIMITED" call _deny};
if (_new == 0) then {_items deleteAt _class} else {_items set [_class, _new]};
if (_new != _old) then {
    if (_storage getOrDefault ["persist", true]) then {PMCA_dirty = true};
    // Amount -1 drops the row whatever it showed; the new count is then added afresh.
    [_id, [[_class, -1]], false, []] call PMCA_fnc_broadcast;
    if (_new != 0) then {[_id, [[_class, _new]], true, []] call PMCA_fnc_broadcast};
    diag_log text format ["[PMCA] Zeus %1 (%2), storage %3: %4 %5 -> %6", name _zeus, getPlayerUID _zeus, _id, _class, _old, _new];
};
[_id, [_id] call PMCA_fnc_stockRows] remoteExecCall ["PMCA_fnc_stockReceive", _owner];

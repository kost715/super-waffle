#include "..\JNA\defineCommon.inc"
// Stock in the arsenal's 27-tab list format, limited to the tabs a unit may take
// from. Items whose mod is no longer loaded stay in stock but are not listed.
params [["_id", "", [""]], ["_tabs", [], [[]]]];
private _list = EMPTY_ARRAY;
private _storage = (missionNamespace getVariable ["PMCA_storages", createHashMap]) getOrDefault [_id, createHashMap];
{
    private _tab = _x call PMCA_fnc_arsenal_itemType;
    if (_tab in _tabs) then {(_list select _tab) pushBack [_x, _y]};
} forEach (_storage getOrDefault ["items", createHashMap]);
_list

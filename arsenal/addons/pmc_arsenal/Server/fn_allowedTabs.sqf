#include "..\defineCommon.inc"
// Arsenal tabs a unit may take from in a storage, or false when it may not open it.
// Categories: weapons (firearms, attachments, ammunition), launchers, explosives
// (grenades, mines, charges) and equipment (clothing, gear, tools, medicine).
// Returning items is always allowed. An integration may set the server variable
// PMCA_accessHandler = {params ["_unit", "_storageID"]; ...categories or false}.
params [["_unit", objNull, [objNull]], ["_id", "", [""]]];
private _byCategory = createHashMapFromArray [
    ["weapons", [IDC_RSCDISPLAYARSENAL_TAB_PRIMARYWEAPON, IDC_RSCDISPLAYARSENAL_TAB_HANDGUN, IDC_RSCDISPLAYARSENAL_TAB_ITEMOPTIC,
        IDC_RSCDISPLAYARSENAL_TAB_ITEMACC, IDC_RSCDISPLAYARSENAL_TAB_ITEMMUZZLE, IDC_RSCDISPLAYARSENAL_TAB_ITEMBIPOD,
        IDC_RSCDISPLAYARSENAL_TAB_CARGOMAG, IDC_RSCDISPLAYARSENAL_TAB_CARGOMAGALL]],
    ["launchers", [IDC_RSCDISPLAYARSENAL_TAB_SECONDARYWEAPON]],
    ["explosives", [IDC_RSCDISPLAYARSENAL_TAB_CARGOTHROW, IDC_RSCDISPLAYARSENAL_TAB_CARGOPUT]],
    ["equipment", [IDC_RSCDISPLAYARSENAL_TAB_UNIFORM, IDC_RSCDISPLAYARSENAL_TAB_VEST, IDC_RSCDISPLAYARSENAL_TAB_BACKPACK,
        IDC_RSCDISPLAYARSENAL_TAB_HEADGEAR, IDC_RSCDISPLAYARSENAL_TAB_GOGGLES, IDC_RSCDISPLAYARSENAL_TAB_NVGS,
        IDC_RSCDISPLAYARSENAL_TAB_BINOCULARS, IDC_RSCDISPLAYARSENAL_TAB_MAP, IDC_RSCDISPLAYARSENAL_TAB_GPS,
        IDC_RSCDISPLAYARSENAL_TAB_RADIO, IDC_RSCDISPLAYARSENAL_TAB_COMPASS, IDC_RSCDISPLAYARSENAL_TAB_WATCH,
        IDC_RSCDISPLAYARSENAL_TAB_CARGOMISC]]
];
private _storage = (missionNamespace getVariable ["PMCA_storages", createHashMap]) getOrDefault [_id, createHashMap];
if (count _storage == 0 || {isNull _unit}) exitWith {false};
private _categories = _storage getOrDefault ["categories", []];
if (_categories isEqualTo []) then {_categories = keys _byCategory};
if (!isNil "PMCA_accessHandler") then {
    private _granted = [_unit, _id] call PMCA_accessHandler;
    _categories = if (_granted isEqualType []) then {_categories arrayIntersect _granted} else {false};
};
if (_categories isEqualTo false) exitWith {false};
private _tabs = [];
{_tabs append (_byCategory getOrDefault [_x, []])} forEach _categories;
_tabs arrayIntersect _tabs

disableSerialization;
private _d = uiNamespace getVariable ["PMCS_console",displayNull];
if (isNull _d) exitWith {};
private _s = uiNamespace getVariable ["PMCS_state",createHashMap];
if (count _s == 0) exitWith {
    (_d displayCtrl 1100) ctrlSetStructuredText parseText (localize "STR_PMCS_LOADING");
    {(_d displayCtrl _x) ctrlEnable false} forEach [3100,3101,3102,3103,3104,3106];
};
private _pending = uiNamespace getVariable ["PMCS_pending",[]];
if (_pending isNotEqualTo [] && {(_s getOrDefault ["reply",""]) == (_pending select 0)}) then {
    _pending = []; uiNamespace setVariable ["PMCS_pending",[]];
};
private _admin = _s get "admin";
private _assignment = _s get "assignmentOK";
(_d displayCtrl 1100) ctrlSetStructuredText parseText format [localize "STR_PMCS_SUMMARY", _s get "member", count (_s get "companies"), _s get "revision",
    localize (["STR_PMCS_OBSERVER","STR_PMCS_ADMIN"] select _admin)];
private _notice = uiNamespace getVariable ["PMCS_localNotice",""];
if (_notice == "") then {_notice = _s getOrDefault ["notice",""]};
if (!_assignment) then {_notice = "STR_PMCS_ASSIGNMENT"};
(_d displayCtrl 1101) ctrlSetStructuredText parseText (if (_notice == "") then {""} else {localize _notice});
if ((_d getVariable ["PMCS_companyList",[]]) isNotEqualTo (_s get "companies")) then {
{
    private _c = _d displayCtrl _x;
    private _previous = _c lbData lbCurSel _c;
    lbClear _c;
    {
        private _idx = _c lbAdd (_x select 1); _c lbSetData [_idx,_x select 0];
        if ((_x select 0) == _previous) then {_c lbSetCurSel _idx};
    } forEach (_s get "companies");
    if (lbCurSel _c < 0) then {_c lbSetCurSel ([0,1 min ((count (_s get "companies"))-1)] select (_x == 2101))};
} forEach [2100,2101];
_d setVariable ["PMCS_companyList",+(_s get "companies")];
};
// State arrives every second; rebuild the list only when its rows changed, so
// it does not flicker or lose its scroll position.
if ((_d getVariable ["PMCS_relationRows", -1]) isNotEqualTo (_s get "relations")) then {
    private _list = _d displayCtrl 1500; lbClear _list;
    {_list lbAdd format ["%1 <-> %2: %3 [%4 / %5]", _x select 0, _x select 1,
        localize (["STR_PMCS_NEUTRAL","STR_PMCS_HOSTILE"] select ((_x select 2)=="hostile")), _x select 3, _x select 4]} forEach (_s get "relations");
    if ((_s get "relations") isEqualTo []) then {_list lbAdd localize "STR_PMCS_ONE"};
    _d setVariable ["PMCS_relationRows", +(_s get "relations")];
};
private _actors = _s get "actors";
private _living = {_x select 1} count _actors;
(_d displayCtrl 1102) ctrlSetStructuredText parseText format [localize "STR_PMCS_PROBES", _living, count _actors,
    localize (["STR_PMCS_WORLD_BLOCKED","STR_PMCS_WORLD_FREE"] select (_s get "worldEnemyAvailable"))];
{(_d displayCtrl _x) ctrlEnable (_admin && {_assignment} && {_pending isEqualTo []})} forEach [3100,3101,3102,3103,3104,3106];
(_d displayCtrl 3106) ctrlSetText localize (["STR_PMCS_WORLD_START","STR_PMCS_WORLD_STOP"] select (_s get "worldHostile"));
if !(_s get "worldEnemyAvailable") then {(_d displayCtrl 3106) ctrlEnable false};
if (count (_s get "companies") < 2) then {{(_d displayCtrl _x) ctrlEnable false} forEach [3100,3101,3103]};

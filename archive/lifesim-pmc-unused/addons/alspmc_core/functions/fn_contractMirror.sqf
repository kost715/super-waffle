params ["_job", "_members"];
private _mode = _job get "alspmcMode";
private _stage = _job get "state";
private _pos = _job get "alspmcSite";
private _plan = _job get "alspmcPlan";
private _destination = [];
private _route = _plan getOrDefault ["route", []];
private _routeIndex = _job getOrDefault ["alspmcRouteIndex", 0];
if (_mode == "sector" && {_stage == "active"} && {_route isNotEqualTo []}) then {
    _pos = _route select (_routeIndex min (count _route - 1));
};
if (_stage == "active" && {_mode in ["convoy", "vip"]}) then {
    _destination = _plan get "destination";
    private _object = if (_mode == "convoy") then {_job get "alspmcTruck"} else {_job get "alspmcProtected"};
    if (!isNull _object) then {_pos = getPosATL _object};
};
private _remaining = {private _o = _x select 0; !(_x select 1) && {!isNull _o && {alive _o}}} count (_job get "alspmcEnemies");
private _left = -1;
if (_mode == "guard" && {_stage == "active"}) then {
    _left = ceil (((_job get "alspmcDutyAt") + (_job get "alspmcDutySeconds") - diag_tickTime) max 0);
};
private _mirror = createHashMapFromArray [["id", _job get "id"], ["alspmcQuestId", _job get "alspmcQuestId"],
    ["alspmc", true], ["alspmcContract", true], ["title", _job get "title"], ["state", _stage],
    ["status", localize (["STR_ALSPMC_mirror_active", "STR_ALSPMC_mirror_rendezvous"] select (_stage == "rendezvous"))],
    ["progLabel", localize "STR_ALSPMC_mirror_label"], ["progText", if (_mode == "sector") then {format [localize "STR_ALSPMC_mirror_points", _routeIndex, count _route]} else {
        if (_left >= 0) then {format [localize "STR_ALSPMC_mirror_seconds", _left]} else {format [localize "STR_ALSPMC_mirror_hostiles", _remaining]}
    }], ["routeDone", _routeIndex], ["routeTotal", count _route],
    ["pay", _job get "pay"], ["pos", _pos], ["destination", _destination],
    ["sector", if (_mode == "mines") then {[_job get "alspmcSite", _job get "alspmcRadius"]} else {[]}]];
private _nav = [[_pos, localize "STR_ALSPMC_quest_target", "gang"]];
if (_destination isNotEqualTo []) then {_nav pushBack [_destination, localize "STR_ALSPMC_contract_destination", "recipient"]};
{
    _x setVariable ["ALS_coopJob", +_mirror, true];
    _x setVariable ["ALS_sideNav", _nav, true];
} forEach _members;
_job set ["pos", _pos];
_job set ["alspmcRemaining", _remaining]; _job set ["alspmcLeft", _left];

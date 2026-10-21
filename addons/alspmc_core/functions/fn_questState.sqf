params ["_unit"];
private _uid = [_unit] call ALS_fnc_uid;
private _ready = missionNamespace getVariable ["ALSPMC_questsReady", false];
private _crew = [_uid] call ALS_fnc_crewOf;
private _nativeJob = (missionNamespace getVariable ["ALS_coopJobs", createHashMap]) getOrDefault [_crew getOrDefault ["job", -1], createHashMap];
private _records = missionNamespace getVariable ["ALSPMC_questRecords", createHashMap];
private _active = createHashMap;
private _history = [];
private _ownActive = false;
private _ids = keys _records;
_ids sort false;
{
    private _row = _records get _x;
    _row params ["_founder", "_status", "_pay", "_pos", "_team", "_start", "_end", "_reason"];
    if (_founder == _uid && {_status == "active"}) then {_ownActive = true};
    if (_founder == _uid || {_uid in _team}) then {
        private _view = createHashMapFromArray [["id", "q" + str _x], ["status", _status], ["pay", _pay],
            ["grid", mapGridPosition _pos], ["teamSize", count _team], ["reason", _reason], ["date", _end]];
        private _meta = (missionNamespace getVariable ["ALSPMC_contractMeta", createHashMap]) getOrDefault [_x, []];
        _view set ["type", _meta param [0, "eliminate"]];
        _view set ["level", _meta param [1, 1]];
        _view set ["paid", _meta param [3, 0]];
        if (_status == "active") then {
            _view set ["pos", _pos];
            private _sameJob = (_nativeJob getOrDefault ["alspmcQuestId", -1]) == _x;
            _view set ["canCancel", _sameJob && {[_uid, _nativeJob, _crew] call ALSPMC_fnc_contractBoss} && {(_nativeJob getOrDefault ["alspmcResult", ""]) == ""}];
            _view set ["canMap", _sameJob];
            _view set ["left", if (_sameJob) then {ceil (((_nativeJob get "since") + (_nativeJob getOrDefault ["alspmcTimeout", 0]) - time) max 0)} else {0}];
            if (_sameJob && {_nativeJob getOrDefault ["alspmcContract", false]}) then {
                _view set ["pos", _nativeJob get "pos"]; _view set ["grid", mapGridPosition (_nativeJob get "pos")];
                _view set ["stage", _nativeJob get "state"]; _view set ["mode", _nativeJob get "alspmcMode"];
                _view set ["left", _nativeJob getOrDefault ["alspmcLeft", -1]];
                _view set ["remaining", _nativeJob getOrDefault ["alspmcRemaining", 0]];
                _view set ["mines", _nativeJob getOrDefault ["alspmcMinesLeft", -1]];
                _view set ["canReady", [_unit, _nativeJob, false] call ALSPMC_fnc_contractReady];
                _view set ["driverDead", _nativeJob getOrDefault ["alspmcDriverDead", false]];
                _view set ["living", count ([_nativeJob] call ALSPMC_fnc_contractTeam)];
                _view set ["radius", _nativeJob get "alspmcRadius"];
                _view set ["routeDone", _nativeJob getOrDefault ["alspmcRouteIndex", 0]];
                _view set ["routeTotal", count ((_nativeJob get "alspmcPlan") getOrDefault ["route", []])];
                _view set ["destination", if ((_nativeJob get "state") == "active" && {(_nativeJob get "alspmcMode") in ["convoy", "vip"]}) then {(_nativeJob get "alspmcPlan") getOrDefault ["destination", []]} else {[]}];
                _view set ["surveyLeft", if ((_nativeJob get "alspmcMode") == "mines" && {(_nativeJob get "state") == "active"}) then {
                    ceil (((getNumber (configFile >> "ALSPMC_Settings" >> "contractSurveySeconds")) - (diag_tickTime - (_nativeJob get "alspmcSurveyAt"))) max 0)
                } else {0}];
            };
            _active = _view;
        } else {if (count _history < 10) then {_history pushBack _view}};
    };
} forEach _ids;
private _licensed = "alspmc_pmc" in (["lic_" + _uid, []] call ALS_fnc_dbGet);
private _base = (keys ALSPMC_bases) findIf {
    ((ALSPMC_bases get _x) select 0) == _uid && {[_uid, ALS_owned getOrDefault [_x, ""]] call ALS_fnc_canUse}
};
// A lethal warrant moves a player to EAST, the contract enemies' own side: they
// would never engage that member, so a crew with one cannot take a contract.
private _crewUIDs = if (count _crew > 0) then {_crew getOrDefault ["members", []]} else {[_uid]};
private _wanted = (_crewUIDs findIf {private _p = [_x] call ALS_fnc_findPlayer; !isNull _p && {side group _p == east}}) >= 0;
private _reason = switch (true) do {
    case (!_ready): {"unavailable"};
    case (_ownActive || {count _active > 0}): {"active"};
    case (!_licensed): {"license"};
    case (_base < 0): {"base"};
    case (count _crew > 0 && {(_crew get "leader") != _uid}): {"leader"};
    case (count _crew > 0 && {(_crew get "job") != -1}): {"busy"};
    case (count (_crew getOrDefault ["members", []]) > 4): {"size"};
    case (_wanted): {"wanted"};
    default {""};
};
private _state = createHashMapFromArray [["ready", _ready], ["canStart", _reason == ""], ["reason", _reason],
    ["pay", (round getNumber (configFile >> "ALSPMC_Settings" >> "questPay")) max 0 min 1000000],
    ["minDistance", (getNumber (configFile >> "ALSPMC_Settings" >> "questMinDistance")) max 300],
    ["maxDistance", (getNumber (configFile >> "ALSPMC_Settings" >> "questMaxDistance")) max (((getNumber (configFile >> "ALSPMC_Settings" >> "questMinDistance")) max 300) + 100)],
    ["timeout", (getNumber (configFile >> "ALSPMC_Settings" >> "questTimeout")) max 60],
    ["active", _active], ["history", _history]];
if (missionNamespace getVariable ["ALSPMC_contractsReady", false]) then {
    private _rating = [_uid] call ALSPMC_fnc_contractProfile;
    _state set ["rating", _rating];
    private _army = count (["army", _unit] call ALSPMC_fnc_contractSites);
    private _government = count (["government", _unit] call ALSPMC_fnc_contractSites);
    private _commercial = count (["commercial", _unit] call ALSPMC_fnc_contractSites);
    private _baseSites = (["assaultBase", _unit] call ALSPMC_fnc_contractSites) select {
        !((_x select 1) in (missionNamespace getVariable ["ALSPMC_garrisonLeases", createHashMap]))
    };
    private _board = [_unit] call ALSPMC_fnc_contractOffers;
    _state set ["poolLeft", ceil (((_board get "expires") - diag_tickTime) max 0)];
    private _catalog = call ALSPMC_fnc_contractCatalog;
    _state set ["catalog", (_board get "offers") apply {
        _x params ["_ticket", "_type"];
        private _entry = (_catalog select {(_x select 0) == _type}) select 0;
        _entry params ["_key", "_category", "_mode", "_minimum", "_price", "_xp"];
        private _world = switch (_key) do {
            case "gov_convoy": {_army > 0 && {_army + _government > 1}};
            case "gov_guard": {_government > 0};
            case "gov_base": {count _baseSites > 0};
            case "private_guard": {_commercial > 0};
            case "private_convoy";
            case "private_vip": {_commercial > 1};
            default {true};
        };
        private _targets = if (_mode != "base") then {[]} else {_baseSites apply {
            private _siteID = _x select 1;
            private _baseRow = (((missionNamespace getVariable ["ALS_war", createHashMap]) getOrDefault ["bases", []]) select {(_x select 0) == _siteID}) param [0, []];
            createHashMapFromArray [["id", _siteID], ["name", toArray (_baseRow param [4, _siteID])], ["owner", _x select 4], ["grid", mapGridPosition (_x select 0)]]
        }};
        createHashMapFromArray [["key", _key], ["offer", _ticket], ["targets", _targets], ["category", _category], ["mode", _mode], ["minLevel", _minimum],
            ["pay", round (_price * (_rating get "multiplier"))], ["xp", _xp], ["world", _world],
            ["available", _world && {_reason == ""} && {(_rating get "level") >= _minimum}]]
    }];
} else {
    if (missionNamespace getVariable ["ALSPMC_contractsStarted", false]) then {
        _state set ["catalog", []]; _state set ["canStart", false]; _state set ["reason", "unavailable"];
    };
};
_state

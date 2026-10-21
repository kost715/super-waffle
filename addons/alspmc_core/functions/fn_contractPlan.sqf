params ["_unit", "_entry", ["_selectedBase", ""]];
_entry params ["_type", "_category", "_mode"];
private _plan = createHashMap;
private _base = [_unit] call ALSPMC_fnc_contractBase;
if (_base isEqualTo []) exitWith {_plan};
private _site = [];
private _destination = [];
if (_mode in ["bandits", "enemyPatrol", "sector", "mines"]) then {
    private _pos = [_unit] call ALSPMC_fnc_questSite;
    if (_pos isNotEqualTo []) then {_site = [_pos, "field", objNull, [], ""]};
} else {
    private _kind = if (_category == "private") then {"commercial"} else {if (_mode == "guard") then {"government"} else {"army"}};
    if (_mode == "base") then {_kind = "assaultBase"};
    private _sites = [_kind, _unit] call ALSPMC_fnc_contractSites;
    // Avoid stacking active contracts on the same source building/base.
    _sites = _sites select {
        private _pos = _x select 0;
        private _ownerOK = true;
        if (_kind in ["army", "assaultBase"]) then {
            private _owner = (((missionNamespace getVariable ["ALS_war", createHashMap]) getOrDefault ["own", createHashMap]) getOrDefault [_x select 1, "Military"]);
            _ownerOK = if (_kind == "army") then {_owner == "Military"} else {
                _owner in ["Military", "Opfor"] && {_selectedBase == "" || {(_x select 1) == _selectedBase}}
            };
        };
        _ownerOK && {[_base, _pos, 100] call ALSPMC_fnc_contractFar} && {((values ALS_coopJobs) findIf {_x getOrDefault ["alspmcContract", false] && {(_x get "alspmcSite") distance2D _pos < 250}}) < 0}
    };
    if (_sites isNotEqualTo []) then {
        private _offset = floor random count _sites;
        for "_i" from 0 to ((count _sites - 1) min 30) do {
            private _candidate = +(_sites select ((_offset + _i) mod count _sites));
            if (_mode == "guard" && {_kind == "commercial"}) then {
                private _object = [_candidate select 1] call ALS_fnc_houseObj;
                private _floor = if (isNull _object) then {[]} else {[_object] call ALS_fnc_houseFloor};
                if (_floor isNotEqualTo []) then {_candidate set [2, _object]; _candidate set [3, _floor select 0]};
            };
            if (_mode != "guard" || {(_candidate select 3) isNotEqualTo []}) exitWith {_site = _candidate};
        };
    };
    if (_site isNotEqualTo [] && {_mode in ["convoy", "vip"]}) then {
        private _destinations = ([_kind, _unit] call ALSPMC_fnc_contractSites) select {
            [_base, _x select 0, 100] call ALSPMC_fnc_contractFar && {(_x select 1) != (_site select 1)} && {(_x select 0) distance2D (_site select 0) >= 1000}
        };
        // Army convoys may finish at another native government facility.
        if (_category == "government") then {
            _destinations append ((["government", _unit] call ALSPMC_fnc_contractSites) select {[_base, _x select 0, 100] call ALSPMC_fnc_contractFar && {(_x select 0) distance2D (_site select 0) >= 1000}});
        };
        if (_destinations isNotEqualTo []) then {_destination = selectRandom _destinations};
    };
};
if (_site isEqualTo [] || {_mode in ["convoy", "vip"] && {_destination isEqualTo []}}) exitWith {_plan};
_plan set ["base", _base];
_plan set ["site", _site select 0]; _plan set ["source", _site select 1];
_plan set ["building", _site select 2]; _plan set ["indoor", _site select 3];
_plan set ["owner", _site select 4];
if (_mode == "sector") then {
    private _points = [];
    private _n = (round getNumber (configFile >> "ALSPMC_Settings" >> "contractPatrolPoints")) max 3 min 8;
    private _bearing = random 360;
    for "_i" from 0 to (_n - 1) do {
        private _point = [];
        for "_attempt" from 1 to 10 do {
            private _candidate = [(_site select 0) getPos [200 + random 120, _bearing + _i * (360 / _n)], 20, 1, true, 3, 0.94] call ALS_fnc_flatSpot;
            if (_candidate isNotEqualTo [] && {(_candidate distance2D (_site select 0)) > 100} && {
                [_base, _candidate, 100] call ALSPMC_fnc_contractFar} && {
                (_points findIf {_x distance2D _candidate < 100}) < 0
            }) exitWith {_point = _candidate};
        };
        if (_point isEqualTo []) exitWith {_points = []};
        _points pushBack _point;
    };
    if (count _points != _n) then {_plan = createHashMap} else {_plan set ["route", _points]};
};
if (_destination isNotEqualTo []) then {_plan set ["destination", _destination select 0]};
if (_mode == "convoy") then {
    private _spots = [_site select 0, _destination select 0, "C_Truck_02_transport_F", 1, 250] call ALS_fnc_warRoadSpot;
    private _endRoad = [_destination select 0, 250] call ALS_fnc_roadNear;
    if (_spots isEqualTo [] || {isNull _endRoad}) then {_plan = createHashMap} else {
        _plan set ["truckPos", (_spots select 0) select 0];
        _plan set ["truckDir", _spots select 1];
        _plan set ["destination", getPosATL _endRoad];
    };
};
// Check the actual resolved positions too, not only registry building centres.
if (count _plan > 0) then {
    private _positions = [_plan get "site"] + (_plan getOrDefault ["route", []]);
    {private _p = _plan getOrDefault [_x, []]; if (_p isNotEqualTo []) then {_positions pushBack _p}} forEach ["destination", "truckPos", "indoor"];
    if ((_positions findIf {!([_base, _x] call ALSPMC_fnc_contractFar)}) >= 0) then {_plan = createHashMap};
};
_plan

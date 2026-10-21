params ["_job", "_members"];
private _result = _job getOrDefault ["alspmcResult", ""];
if (_result != "") exitWith {[["failed",0],["done",1]] select (_result == "complete")};
private _mode = _job get "alspmcMode";
private _site = _job get "alspmcSite";
private _plan = _job get "alspmcPlan";
private _living = [_job] call ALSPMC_fnc_contractTeam;
private _fail = {params ["_why"]; _job set ["alspmcResult", _why]};
if (_mode in ["bandits", "base", "enemyPatrol", "sector", "mines"] && {_living isEqualTo []} && {_members isNotEqualTo []}) exitWith {
    ["wiped"] call _fail; ["failed",0]
};
private _stage = _job get "state";
if (_mode == "base") then {
    private _owner = ((missionNamespace getVariable ["ALS_war", createHashMap]) getOrDefault ["own", createHashMap]) getOrDefault [_plan get "source", "Military"];
    if (_owner != (_plan getOrDefault ["owner", _owner])) then {["site"] call _fail};
};
if ((_job get "alspmcEnemies") isNotEqualTo []) then {["tick", _job] call ALSPMC_fnc_contractHostility};
if (_stage == "rendezvous" && {(_job get "alspmcType") == "gov_convoy"}) then {
    private _owner = ((missionNamespace getVariable ["ALS_war", createHashMap]) getOrDefault ["own", createHashMap]) getOrDefault [_plan get "source", "Military"];
    if (_owner != "Military") then {["site"] call _fail};
};
if (_mode == "mines" && {_stage == "travel"} && {(_living findIf {_x distance2D _site <= (_job get "alspmcRadius")}) >= 0}) then {
    private _n = if (random 1 < ((getNumber (configFile >> "ALSPMC_Settings" >> "contractMineChance")) max 0 min 1)) then {3 + floor random 4} else {0};
    private _ok = true;
    for "_i" from 1 to _n do {
        private _at = [];
        for "_try" from 1 to 12 do {
            private _q = [_site getPos [20 + random 45, random 360], 12, 1, true, 2, 0.94] call ALS_fnc_flatSpot;
            if (_q isNotEqualTo [] && {[_plan get "base", _q] call ALSPMC_fnc_contractFar} && {_q distance2D _site < (_job get "alspmcRadius") - 2} && {(allPlayers findIf {_x distance2D _q < 25}) < 0}) exitWith {_at = _q};
        };
        if (_at isEqualTo []) exitWith {_ok = false};
        private _mine = createMine ["APERSMine", _at, [], 0];
        if (isNull _mine) exitWith {_ok = false};
        (_job get "alspmcObjects") pushBack _mine;
        (_job get "alspmcMines") pushBack _mine;
    };
    if (!_ok) then {["spawn"] call _fail} else {
        _job set ["state", "active"]; _job set ["alspmcSurveyAt", diag_tickTime];
    };
};
if ((_job get "state") == "combat" && {_mode in ["bandits", "base", "enemyPatrol"]}) then {
    private _enemies = _job get "alspmcEnemies";
    {
        if (!(_x select 1)) then {
            private _object = _x select 0;
            if (isNull _object) then {["site"] call _fail} else {if (!alive _object) then {_x set [1, true]}};
        };
    } forEach _enemies;
    if (_enemies isNotEqualTo [] && {(_enemies findIf {!(_x select 1)}) < 0} && {(_job get "alspmcResult") == ""}) then {_job set ["alspmcResult", "complete"]};
};
if ((_job get "state") == "active") then {
    private _target = objNull;
    if (_mode == "convoy") then {
        _target = _job getOrDefault ["alspmcTruck", objNull];
        if (isNull _target || {!alive _target}) then {["truck"] call _fail} else {
            _job set ["alspmcDriverDead", isNull driver _target || {!alive driver _target}];
            if (_target distance2D (_plan get "destination") <= 100) then {_job set ["alspmcResult", "complete"]};
        };
    };
    if (_mode in ["guard", "vip"]) then {
        _target = _job getOrDefault ["alspmcProtected", objNull];
        if (isNull _target || {!alive _target}) then {["protected"] call _fail} else {
            if (_mode == "vip" && {_target distance2D (_plan get "destination") <= 60} && {
                (_living findIf {_x distance2D _target <= 200}) >= 0
            }) then {_job set ["alspmcResult", "complete"]};
        };
    };
    if (_mode == "sector") then {
        private _route = _plan get "route";
        private _index = _job getOrDefault ["alspmcRouteIndex", 0];
        private _radius = (getNumber (configFile >> "ALSPMC_Settings" >> "contractPatrolPointRadius")) max 10 min 75;
        if (_index < count _route && {(_living findIf {_x distance2D (_route select _index) <= _radius}) >= 0}) then {
            _index = _index + 1; _job set ["alspmcRouteIndex", _index];
        };
        if (_index >= count _route) then {_job set ["alspmcResult", "complete"]};
        _target = _living param [0, objNull];
    };
    if (_mode == "guard" && {(_job get "alspmcResult") == ""} && {
        diag_tickTime - (_job get "alspmcDutyAt") >= (_job get "alspmcDutySeconds")
    }) then {_job set ["alspmcResult", "complete"]};
    if (_mode == "mines") then {
        private _left = { !isNull _x && {mineActive _x} } count (_job get "alspmcMines");
        _job set ["alspmcMinesLeft", _left];
        if (_left == 0 && {diag_tickTime - (_job get "alspmcSurveyAt") >= ((getNumber (configFile >> "ALSPMC_Settings" >> "contractSurveySeconds")) max 0)}) then {
            _job set ["alspmcResult", "complete"];
        };
    };
    private _attackDue = false;
    if (_mode == "guard") then {_attackDue = diag_tickTime >= (_job get "alspmcAttackAt")};
    if (_mode == "sector") then {_attackDue = (_job getOrDefault ["alspmcRouteIndex", 0]) > 0};
    if (_mode in ["convoy", "vip"] && {!isNull _target}) then {
        _attackDue = diag_tickTime - (_job get "alspmcDutyAt") >= 30 && {_site distance2D _target >= 0.3 * (_site distance2D (_plan get "destination"))};
    };
    if (_attackDue && {!(_job get "alspmcAttackDone")} && {(_job get "alspmcResult") == ""}) then {
        _job set ["alspmcAttackDone", true];
        if (_job get "alspmcAttackPlanned") then {
            private _center = if (isNull _target) then {_site} else {getPosATL _target};
            private _spawn = [];
            for "_try" from 1 to 12 do {
                private _q = [_center getPos [160 + random 120, random 360], 35, 3, true, 5, 0.94] call ALS_fnc_flatSpot;
                if (_q isNotEqualTo [] && {[_plan get "base", _q, 100] call ALSPMC_fnc_contractFar} && {(allPlayers findIf {_x distance2D _q < 60}) < 0}) exitWith {_spawn = _q};
            };
            if (_spawn isNotEqualTo []) then {[_job, _spawn, _target, true] call ALSPMC_fnc_contractAttack};
        };
    };
};
[_job, _members] call ALSPMC_fnc_contractMirror;
_result = _job get "alspmcResult";
if (_result == "") exitWith {["on"]};
[["failed",0],["done",1]] select (_result == "complete")

params ["_unit", "_job", ["_execute", true]];
private _uid = [_unit] call ALS_fnc_uid;
private _crew = [_uid] call ALS_fnc_crewOf;
private _team = [_job] call ALSPMC_fnc_contractTeam;
// After respawn the player may have a new engine group. Rejoin the existing
// VIP nearby instead of spawning another person or teleporting either actor.
if ((_job get "alspmcMode") == "vip" && {(_job get "state") == "active"}) exitWith {
    private _vip = _job getOrDefault ["alspmcProtected", objNull];
    private _allowed = !isNull _vip && {alive _vip} && {_unit in _team} && {
        [_uid, _job, _crew] call ALSPMC_fnc_contractBoss
    } && {_unit distance _vip <= 30} && {leader group _unit == _unit};
    if (_allowed && {_execute}) then {[_vip] joinSilent (group _unit)};
    _allowed
};
private _radius = (getNumber (configFile >> "ALSPMC_Settings" >> "contractReadyRadius")) max 20;
if ((_job get "state") != "rendezvous" || {!([_uid, _job, _crew] call ALSPMC_fnc_contractBoss)} || {
    (_crew getOrDefault ["id", ""]) != (_job get "crew")
} || {!(_unit in _team)} || {_unit distance2D (_job get "alspmcSite") > _radius}) exitWith {false};
private _mode = _job get "alspmcMode";
if (_mode == "guard" && {private _building = (_job get "alspmcPlan") get "building"; isNull _building || {!alive _building}}) exitWith {false};
// Joining the real Arma group lets its player leader command the VIP normally.
if (_mode == "vip" && {leader group _unit != _unit}) exitWith {false};
if (!_execute) exitWith {true};
private _plan = _job get "alspmcPlan";
private _objects = _job get "alspmcObjects";
private _groups = _job get "alspmcGroups";
private _ok = true;
if (_mode == "convoy") then {
    private _truck = createVehicle ["C_Truck_02_transport_F", _plan get "truckPos", [], 0, "NONE"];
    if (isNull _truck) exitWith {_ok = false};
    _objects pushBack _truck;
    _truck setDir (_plan get "truckDir"); _truck setVectorUp surfaceNormal (_plan get "truckPos");
    _truck setVariable ["ALS_jobEvObj", true]; _truck setVariable ["ALS_keep", true, true];
    _truck setVariable ["ALS_convoy", _job get "id", true];
    // Native vehLocks locks every ownerless vehicle (lock 3) within 5 s unless
    // it is marked unlocked; players must be able to drive it if the driver dies.
    _truck setVariable ["ALS_unlocked", true, true];
    _truck lock 0;
    private _group = createGroup [civilian, true]; _groups pushBack _group;
    if (isNull _group) exitWith {_ok = false};
    private _driver = _group createUnit ["C_man_w_worker_F", _plan get "truckPos", [], 0, "NONE"];
    if (isNull _driver) exitWith {_ok = false};
    _objects pushBack _driver;
    _driver setVariable ["ALS_jobEvObj", true]; _driver setBehaviour "CARELESS"; _driver allowFleeing 0;
    _driver moveInDriver _truck;
    private _cargo = createVehicle ["Land_MetalCase_01_large_F", _plan get "truckPos", [], 0, "CAN_COLLIDE"];
    if (!isNull _cargo) then {
        _cargo attachTo [_truck, [0,-1,0.7]]; _cargo allowDamage false;
        _cargo setVariable ["ALS_jobEvObj", true]; _objects pushBack _cargo;
    };
    _job set ["alspmcTruck", _truck]; _job set ["alspmcDriver", _driver];
    [_truck, _plan get "destination", "NORMAL"] call ALS_fnc_aiDrive;
    _truck setVariable ["ALS_maxKmh", 45]; _truck limitSpeed 45;
};
if (_mode in ["guard", "vip"]) then {
    private _at = _plan get "indoor";
    if (_mode == "vip") then {_at = [_job get "alspmcSite", 1, 40, "C_man_1"] call ALS_fnc_landPos};
    if (_at isEqualTo [] || {!([_plan get "base", _at] call ALSPMC_fnc_contractFar)}) exitWith {_ok = false};
    private _group = createGroup [civilian, true]; _groups pushBack _group;
    if (isNull _group) exitWith {_ok = false};
    private _class = "C_man_1";
    if (_mode == "vip") then {
        _class = (["C_Man_formal_1_F", "C_Nikos_aged", "C_man_1"] select {isClass (configFile >> "CfgVehicles" >> _x)}) select 0;
    };
    private _person = _group createUnit [_class, _at, [], 0, "NONE"];
    if (isNull _person) exitWith {_ok = false};
    _objects pushBack _person;
    removeAllWeapons _person; _person allowFleeing 0;
    _person setVariable ["ALS_jobEvObj", true];
    _job set ["alspmcProtected", _person];
    if (_mode == "guard") then {
        _person setPosATL _at;
        _person disableAI "PATH"; _person disableAI "MOVE"; _person setBehaviour "CARELESS";
    } else {
        _person setVariable ["BIS_enableRandomization", false, true];
        removeHeadgear _person; removeGoggles _person; removeVest _person; removeBackpack _person;
        private _suits = ["U_C_FormalSuit_01_black_F", "U_C_FormalSuit_01_gray_F", "U_NikosAgedBody"] select {isClass (configFile >> "CfgWeapons" >> _x)};
        if (_suits isNotEqualTo []) then {_person forceAddUniform (selectRandom _suits)};
        [_person] joinSilent (group _unit);
    };
};
if (!_ok) exitWith {
    // Roll back this ready attempt, leaving the accepted contract available.
    {if (!isNull _x) then {deleteVehicle _x}} forEach _objects;
    {if (!isNull _x) then {deleteGroup _x}} forEach _groups;
    _job set ["alspmcObjects", []]; _job set ["alspmcGroups", []];
    false
};
_job set ["state", "active"];
_job set ["alspmcDutyAt", diag_tickTime];
_job set ["alspmcAttackAt", diag_tickTime + 60 + random 420];
if (_mode == "sector") then {_job set ["alspmcRouteIndex", 0]};
[_job, _team] call ALSPMC_fnc_contractMirror;
true

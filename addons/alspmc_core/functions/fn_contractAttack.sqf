// The patrol's 3-10 total includes any vehicle crew.
params ["_job", "_center", ["_target", objNull], ["_attacking", false]];
private _profile = _job get "alspmcProfile";
private _mode = _job get "alspmcMode";
private _level = _profile get "level";
private _side = ["side", _job] call ALSPMC_fnc_contractHostility;
if (_side isEqualType false) exitWith {false};
private _n = (_profile get "min") + floor random ((_profile get "max") - (_profile get "min") + 1);
private _vehicleClass = "";
if (_mode == "enemyPatrol") then {
    if (random 1 < 0.5) then {_vehicleClass = ["C_Offroad_01_F", "I_G_Offroad_01_armed_F"] select (_level >= 4)};
} else {
    if (random 1 < (_profile get "pickupChance")) then {_vehicleClass = "I_G_Offroad_01_armed_F"};
};
private _crewN = if (_vehicleClass == "") then {0} else {if (_vehicleClass == "C_Offroad_01_F") then {1} else {2}};
private _footN = if (_mode == "enemyPatrol") then {_n - _crewN} else {_n};
private _assets = call ALSPMC_fnc_contractAssets;
private _classes = _assets get "militia";
if (_classes isEqualTo []) exitWith {false};
private _base = (_job get "alspmcPlan") get "base";
private _created = [];
private _groups = [];
private _enemies = [];
private _ok = true;
private _make = {
    params ["_group", "_at", "_i"];
    private _class = selectRandom _classes;
    if !(isClass (configFile >> "CfgVehicles" >> _class)) exitWith {objNull};
    private _unit = _group createUnit [_class, _at, [], 0, "NONE"];
    if (isNull _unit) exitWith {objNull};
    // Some mod classes retain their config side until an explicit join.
    [_unit] joinSilent _group;
    _unit addRating 10000;
    _unit addEventHandler ["HandleRating", {0}];
    _unit setCaptive false;
    _unit setVariable ["BIS_enableRandomization", false];
    _unit setVariable ["ALS_hitSquad", true, true]; _unit setVariable ["ALS_hostile", true, true];
    _unit setVariable ["ALS_jobEvObj", true];
    [_unit, _level, _i] call ALSPMC_fnc_contractEquip;
    _created pushBack _unit; _enemies pushBack [_unit, false];
    _unit
};
private _footGroup = createGroup [_side, true];
if (isNull _footGroup) exitWith {false};
_groups pushBack _footGroup;
for "_i" from 0 to (_footN - 1) do {
    private _pos = [_center, 3, 45, "O_G_Soldier_F"] call ALS_fnc_landPos;
    if (_pos isEqualTo [] || {!([_base, _pos] call ALSPMC_fnc_contractFar)} || {(allPlayers findIf {alive _x && {_x distance2D _pos < 25}}) >= 0}) exitWith {_ok = false};
    if (isNull ([_footGroup, _pos, _i] call _make)) exitWith {_ok = false};
};
if (_ok && {_vehicleClass != ""}) then {
    private _at = [_center, 8, 80, _vehicleClass] call ALS_fnc_landPos;
    if (_at isEqualTo [] || {!([_base, _at] call ALSPMC_fnc_contractFar)}) then {_ok = false} else {
        private _vehicle = createVehicle [_vehicleClass, _at, [], 0, "NONE"];
        if (isNull _vehicle) then {_ok = false} else {
            _created pushBack _vehicle;
            _vehicle setVariable ["ALS_jobEvObj", true]; _vehicle setVariable ["ALS_hostile", true, true];
            _vehicle lock 2;
            private _group = createGroup [_side, true]; _groups pushBack _group;
            if (isNull _group) then {_ok = false};
            for "_i" from 0 to (if (_ok) then {_crewN - 1} else {-1}) do {
                private _unit = [_group, _at, _i] call _make;
                if (isNull _unit) exitWith {_ok = false};
                if (_i == 0) then {_unit moveInDriver _vehicle} else {_unit moveInGunner _vehicle};
            };
        };
    };
};
if (!_ok) exitWith {
    {if (!isNull _x) then {deleteVehicle _x}} forEach _created;
    {if (!isNull _x) then {deleteGroup _x}} forEach _groups;
    false
};
(_job get "alspmcObjects") append _created;
(_job get "alspmcGroups") append _groups;
(_job get "alspmcEnemies") append _enemies;
["acquire", _job] call ALSPMC_fnc_contractHostility;
{
    _x setBehaviour "COMBAT"; _x setCombatMode "RED";
    if (_attacking) then {
        [_x, if (isNull _target) then {_job get "alspmcSite"} else {getPosATL _target}] call BIS_fnc_taskAttack;
        if (!isNull _target) then {
            _x reveal [_target, 4];
            {_x doTarget _target; _x doFire _target} forEach units _x;
        };
    } else {[_x, _center, 45] call BIS_fnc_taskPatrol};
} forEach _groups;
true

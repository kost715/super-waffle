if (!isServer) exitWith {false};
// Only actors created by this prototype. Player groups are never in this list.
{if (!isNull _x && {!isPlayer _x}) then {deleteVehicle _x}} forEach PMCS_actors;
{if (!isNull _x && {(units _x findIf {isPlayer _x}) < 0}) then {deleteGroup _x}} forEach PMCS_actorGroups;
PMCS_actors = []; PMCS_actorGroups = [];
private _center = PMCS_center;
private _create = {
    params ["_side", "_role", "_class", "_offset", "_count"];
    private _g = createGroup [_side, true];
    if (isNull _g) exitWith {false};
    PMCS_actorGroups pushBack _g;
    private _ok = true;
    for "_i" from 0 to (_count - 1) do {
        private _p = [(_center select 0) + (_offset select 0) + _i * 6, (_center select 1) + (_offset select 1), 0];
        private _free = _p findEmptyPosition [0,10,_class];
        if (_free isEqualTo []) exitWith {_ok = false};
        private _u = _g createUnit [_class, _free, [], 0, "NONE"];
        if (isNull _u) exitWith {_ok = false};
        if (side group _u != _side) exitWith {
            diag_log format ["[PMCS S1] actor side mismatch expected=%1 actual=%2", _side, side group _u];
            deleteVehicle _u; _ok = false;
        };
        _u setVariable ["PMCS_actorRole", _role, true];
        _u setVariable ["PMCS_owned", true];
        _u setPosATL _free;
        _u setSkill 0.5; _u allowFleeing 0;
        _u disableAI "PATH";
        _u addRating 100000;
        _u addEventHandler ["HandleRating", {0}];
        PMCS_actors pushBack _u;
        if (_side == civilian) then {removeAllWeapons _u};
    };
    _g setBehaviour "AWARE"; _g setCombatMode "RED";
    _ok
};
private _ok = true;
private _offsets = [[-40,100],[40,100],[0,190]];
{
    if !([_x select 2, _x select 0, ["B_Soldier_F","O_Soldier_F","I_Soldier_F"] select _forEachIndex, _offsets select _forEachIndex, 2] call _create) then {_ok = false};
} forEach PMCS_plan;
if !([civilian, "civilian", "C_man_1", [-12,35], 2] call _create) then {_ok = false};
if (PMCS_worldSide != sideUnknown) then {
    private _class = ["O_Soldier_F","I_Soldier_F"] select (PMCS_worldSide == resistance);
    if !([PMCS_worldSide, "world_enemy", _class, [0,270], 2] call _create) then {_ok = false};
};
diag_log format ["[PMCS S1] reset actors=%1 groups=%2 ok=%3 worldSide=%4", count PMCS_actors, count PMCS_actorGroups, _ok, PMCS_worldSide];
_ok

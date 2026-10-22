// Contract enemies always fight on EAST. In LifeSim 0.13.0 police and the army
// are WEST, Opfor and the Syndikat gangs are RESISTANCE, players with a lethal
// warrant are moved to EAST, and so are the defenders LifeSim 0.12.1 raises at
// player-held war bases (fn_warArms). Those defenders are moved below to
// RESISTANCE, which LifeSim gives the same relations as EAST (fn_lawInit), so
// the hostility leased here reaches this addon's own units only. Never switch
// the enemies to another side: RESISTANCE would turn every native gang and
// Opfor garrison on the map against civilians.
// Never change a player's side, rating, captive state, group or wanted logic.
params ["_action", "_job"];
private _side = east;
if (_action == "side") exitWith {createCenter _side; _side};
private _leases = missionNamespace getVariable ["ALSPMC_hostileContracts", createHashMap];
private _relations = missionNamespace getVariable ["ALSPMC_hostileRelations", createHashMap];
private _id = _job get "alspmcQuestId";
if (_action == "release") then {_leases deleteAt _id} else {
    createCenter _side;
    // Only the contract roster's sides: CIV, or WEST while Opfor marks a player
    // as hostile. CIV is always included for protected NPCs. EAST (a wanted
    // member) and RESISTANCE (native gangs/Opfor) are never leased.
    private _crew = ((_job getOrDefault ["alspmcRoster", []]) apply {[_x select 0] call ALS_fnc_findPlayer}) select {!isNull _x};
    private _sides = ((_crew apply {side group _x}) + [civilian]) select {_x in [civilian, west]};
    _sides = _sides arrayIntersect _sides;
    _leases set [_id, _sides apply {[_side, _x]}];
};
// Restore unused directed pairs only if another system has not changed them.
{
    private _saved = _relations get _x;
    _saved params ["_from", "_to", "_before"];
    if (((values _leases) findIf {[_from, _to] in _x}) < 0) then {
        if ((_from getFriend _to) == 0) then {_from setFriend [_to, _before]};
        _relations deleteAt _x;
    };
} forEach keys _relations;
{
    _x params ["_from", "_to"];
    private _key = str _x;
    if !(_key in _relations) then {_relations set [_key, [_from, _to, _from getFriend _to]]};
    _from setFriend [_to, 0];
} forEach (_leases getOrDefault [_id, []]);
ALSPMC_hostileContracts = _leases; ALSPMC_hostileRelations = _relations;
// Only while RESISTANCE still has LifeSim's EAST relations; another mod may differ.
if (count _leases > 0 && {(resistance getFriend civilian) >= 0.6} && {(resistance getFriend west) < 0.6}) then {
    {
        private _group = _x;
        private _units = units _group;
        if (side _group == _side && {_units isNotEqualTo []} && {(_units findIf {isPlayer _x}) < 0} && {
            (_units findIf {!isNil {_x getVariable "ALS_defender"}}) >= 0
        }) then {
            private _moved = createGroup [resistance, true];
            if (!isNull _moved) then {
                private _baseID = ((_units select {!isNil {_x getVariable "ALS_defender"}}) select 0) getVariable "ALS_defender";
                private _at = (((missionNamespace getVariable ["ALS_war", createHashMap]) getOrDefault ["bases", []]) select {(_x select 0) == _baseID}) param [0, []];
                _units joinSilent _moved;
                _moved setBehaviour "AWARE"; _moved setCombatMode "RED";
                [_moved, if (_at isEqualTo []) then {getPosATL leader _moved} else {_at select 1}, 60] call BIS_fnc_taskDefend;
            };
        };
    } forEach allGroups;
};
if (_action == "tick") then {
    ["tick", _job] call ALSPMC_fnc_contractCivilians;
    private _living = ([_job] call ALSPMC_fnc_contractTeam) select {side group _x != _side};
    private _protected = _job getOrDefault ["alspmcProtected", objNull];
    if (!isNull _protected && {alive _protected}) then {_living pushBack _protected};
    private _truck = _job getOrDefault ["alspmcTruck", objNull];
    if (!isNull _truck && {alive _truck}) then {_living pushBack _truck};
    {
        if (!isNull _x && {side _x == _side}) then {
            {
                private _enemy = _x;
                if (alive _enemy) then {
                    private _nearest = objNull;
                    private _distance = 500;
                    {private _d = _enemy distance2D _x; if (_d < _distance) then {_nearest = _x; _distance = _d}} forEach _living;
                    if (!isNull _nearest) then {
                        _enemy reveal [_nearest, 4]; _enemy doTarget _nearest; _enemy doFire _nearest;
                    };
                };
            } forEach units _x;
        };
    } forEach (_job getOrDefault ["alspmcGroups", []]);
};
true

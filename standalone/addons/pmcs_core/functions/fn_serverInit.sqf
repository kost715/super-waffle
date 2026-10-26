if (!isServer || {missionNamespace getVariable ["PMCS_started", false]}) exitWith {};
if (getNumber (missionConfigFile >> "PMCS_Prototype" >> "enabled") != 1) exitWith {};
PMCS_started = true; PMCS_ready = false;
PMCS_plan = [getNumber (missionConfigFile >> "PMCS_Prototype" >> "companies")] call PMCS_fnc_sidePlan;
if (PMCS_plan isEqualTo []) exitWith {diag_log "[PMCS S1] invalid company count; startup stopped"};
PMCS_session = "s1_" + str systemTimeUTC;
PMCS_revision = 0;
PMCS_companies = createHashMapFromArray (PMCS_plan apply {[_x select 0, _x]});
PMCS_members = createHashMap; PMCS_relations = createHashMap;
PMCS_worldHostile = false;
PMCS_requests = createHashMap; PMCS_replies = createHashMap;
PMCS_center = [14500,16250,0];
PMCS_actors = []; PMCS_actorGroups = []; PMCS_terminals = [];
{createCenter _x} forEach [west,east,resistance,civilian];
call PMCS_fnc_applyRelations;
private _offsets = [[-50,-40],[50,-40],[0,-100]];
{
    private _offset = _offsets select _forEachIndex;
    private _pos = [(PMCS_center select 0)+(_offset select 0), (PMCS_center select 1)+(_offset select 1), 0];
    private _desk = createVehicle ["Land_TableDesk_F", _pos, [], 0, "CAN_COLLIDE"];
    private _pc = createVehicle ["Land_Laptop_unfolded_F", _pos, [], 0, "CAN_COLLIDE"];
    if (isNull _desk || {isNull _pc}) then {
        {if (!isNull _x) then {deleteVehicle _x}} forEach [_desk,_pc];
    } else {
        _desk setPosATL _pos;
        _pc setPosATL [_pos select 0, _pos select 1, 0.84];
        {_x enableSimulationGlobal false; _x allowDamage false; _x setVariable ["PMCS_owned",true]} forEach [_desk,_pc];
        PMCS_terminals pushBack _pc;
        (["respawn_west","respawn_east","respawn_guerrila"] select _forEachIndex) setMarkerPos [_pos select 0,_pos select 1,0];
    };
} forEach PMCS_plan;
if (count PMCS_terminals != count PMCS_plan) exitWith {diag_log "[PMCS S1] missing computer assets; startup stopped"};
private _actorsOK = call PMCS_fnc_resetActors;
PMCS_terminalPublic = +PMCS_terminals;
publicVariable "PMCS_terminalPublic";
PMCS_ready = true; publicVariable "PMCS_ready";
diag_log format ["[PMCS S1] ready session=%1 companies=%2 actorsOK=%3", PMCS_session, count PMCS_plan, _actorsOK];
// Records actual engine results, not a scripted pass/fail claim about AI combat.
addMissionEventHandler ["EntityKilled", {
    params ["_unit", "_killer"];
    if ((_unit getVariable ["PMCS_actorRole",""]) != "") then {
        diag_log format ["[PMCS S1] killed role=%1 side=%2 killerSide=%3 killerRole=%4", _unit getVariable ["PMCS_actorRole",""], side group _unit, side group _killer, _killer getVariable ["PMCS_actorRole", "player-or-other"]];
    };
}];
addMissionEventHandler ["PlayerDisconnected", {
    params ["_id", "_uid", "_name", "_jip", "_owner"];
    PMCS_replies deleteAt str _owner;
    {if ((_x select [0, count (str _owner + ":")]) == str _owner + ":") then {PMCS_requests deleteAt _x}} forEach keys PMCS_requests;
    diag_log format ["[PMCS S1] disconnected uid=%1; prototype membership retained in session", _uid];
}];

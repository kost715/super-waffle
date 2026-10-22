params ["_dead", "_killer", ["_instigator", objNull]];
if (!isServer || {!(missionNamespace getVariable ["ALSPMC_questsReady", false])}) exitWith {};
if (!isNil {_dead getVariable "ALS_npc"}) then {["killed", createHashMap, _this] call ALSPMC_fnc_contractCivilians};
// New contracts count simultaneous deaths, not permanent elimination. Capture
// the last death now so an immediate respawn before the next native tick cannot
// erase a wipe. Enemy death records survive subsequent body cleanup/streaming.
if (!alive _dead) then {
    {
        private _job = _y;
        if (_job getOrDefault ["alspmcContract", false] && {!(_job getOrDefault ["alspmcEnding", false])}) then {
            {if ((_x select 0) isEqualTo _dead) then {_x set [1, true]}} forEach (_job get "alspmcEnemies");
            private _roster = _job get "alspmcRoster";
            private _deadUID = if (isPlayer _dead) then {[_dead] call ALS_fnc_uid} else {_dead getVariable ["ALS_uid", ""]};
            private _who = _roster findIf {(_x select 1) isEqualTo _dead || {_deadUID != "" && {(_x select 0) == _deadUID}}};
            if (_who >= 0) then {
                (_job get "alspmcCasualties") pushBackUnique ((_roster select _who) select 0);
                if ((_job get "alspmcMode") in ["bandits", "base", "enemyPatrol", "sector", "mines"] && {
                    ([_job] call ALSPMC_fnc_contractTeam) isEqualTo []
                } && {(_job get "alspmcResult") == ""}) then {_job set ["alspmcResult", "wiped"]};
            };
        };
    } forEach ALS_coopJobs;
};
private _tag = _dead getVariable ["ALSPMC_questTarget", []];
if (count _tag != 2) exitWith {};
private _job = ALS_coopJobs getOrDefault [_tag select 0, createHashMap];
if ((_job getOrDefault ["alspmcQuestId", -1]) != (_tag select 1) || {
    (_job getOrDefault ["alspmcTarget", objNull]) != _dead
} || {alive _dead} || {(_job getOrDefault ["alspmcResult", ""]) != ""}) exitWith {};
if (time - (_job get "since") > (_job get "alspmcTimeout")) exitWith {_job set ["alspmcResult", "timeout"]};
private _by = _instigator;
if (isNull _by) then {_by = if (!isNull _killer && {!(_killer isKindOf "CAManBase")}) then {driver _killer} else {_killer}};
private _crew = ALS_crews getOrDefault [_job get "crew", createHashMap];
private _uid = if (isNull _by || {!isPlayer _by}) then {""} else {[_by] call ALS_fnc_uid};
private _credited = _uid in (_job get "team") && {_uid in (_crew getOrDefault ["members", []])};
_job set ["alspmcResult", ["outsider", "killed"] select _credited];

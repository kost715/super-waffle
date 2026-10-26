// Optional journal in the native world/slot DB. Invalid data blocks only quests.
if (!isServer || {missionNamespace getVariable ["ALSPMC_questsStarted", false]}) exitWith {};
ALSPMC_questsStarted = true;
ALSPMC_questsReady = false;
ALSPMC_questRecords = createHashMap;
ALSPMC_questRequests = createHashMap;
ALSPMC_questSequence = 0;
[["alspmc_quests_v1"]] call ALS_fnc_dbLoading;
private _saved = ["alspmc_quests_v1", [1, 0, []]] call ALS_fnc_dbGet;
private _valid = _saved isEqualType [] && {count _saved == 3};
if (_valid) then {
    _valid = (_saved select 0) isEqualTo 1 && {(_saved select 1) isEqualType 0} && {
        (_saved select 1) >= 0 && {(_saved select 1) == floor (_saved select 1)}
    } && {(_saved select 2) isEqualType []};
};
if (_valid) then {
    ALSPMC_questSequence = _saved select 1;
    {
        private _good = _x isEqualType [] && {count _x == 2};
        if (_good) then {
            _x params ["_id", "_row"];
            _good = _id isEqualType 0 && {_id > 0 && {_id == floor _id} && {_id <= ALSPMC_questSequence}} && {
                !(_id in ALSPMC_questRecords)
            } && {_row isEqualType [] && {count _row == 8}};
            if (_good) then {
                _row params ["_founder", "_status", "_pay", "_pos", "_team", "_start", "_end", "_reason"];
                _good = _founder isEqualType "" && {_founder != ""} && {
                    _status in ["active", "done", "failed", "cancelled", "interrupted"]
                } && {_pay isEqualType 0 && {_pay >= 0 && {_pay <= 1000000}}} && {
                    _pos isEqualType [] && {count _pos == 3} && {(_pos findIf {!(_x isEqualType 0) || {abs _x > 1000000}}) < 0}
                } && {_team isEqualType [] && {count _team >= 1 && {count _team <= 4}} && {
                    (_team findIf {!(_x isEqualType "") || {_x == ""}}) < 0
                } && {count (_team arrayIntersect _team) == count _team} && {_founder in _team}} && {
                    _start isEqualType [] && {count _start == 5} && {(_start findIf {!(_x isEqualType 0) || {abs _x > 1000000}}) < 0}
                } && {_end isEqualType [] && {count _end in [0, 5]} && {(_end findIf {!(_x isEqualType 0) || {abs _x > 1000000}}) < 0}} && {
                    _reason in ["", "killed", "outsider", "lost", "timeout", "cancelled", "restart", "empty", "complete", "wiped", "truck", "protected", "sector", "site", "spawn"]
                };
            };
            if (_good) then {ALSPMC_questRecords set [_id, +_row]};
        };
        if (!_good) then {_valid = false};
    } forEach (_saved select 2);
};
if (!_valid) exitWith {
    ALSPMC_questRecords = createHashMap;
    ["ALSPMC: quest journal invalid; original journal preserved, only quests disabled"] call ALS_fnc_log;
};
[["alspmc_quests_v1"], true] call ALS_fnc_dbLoading;
// Native coopInit does not restore live AI/jobs. Never revive or pay an old ID.
private _interrupted = false;
{
    if ((_y select 1) == "active") then {
        _y set [1, "interrupted"]; _y set [6, date]; _y set [7, "restart"];
        _interrupted = true;
    };
} forEach ALSPMC_questRecords;
// Native coopTick dispatches by kind at runtime. Do not add our scenario to
// ALS_fnList: ordinary crews must retain their original offer catalog/minima.
ALS_fnc_coopJob_alspmc_eliminate = {_this call ALSPMC_fnc_questScenario};
ALSPMC_questsReady = true;
call ALSPMC_fnc_contractInit;
call ALSPMC_fnc_questSave;
if (_interrupted) then {call ALS_fnc_dbSave};
addMissionEventHandler ["EntityKilled", {_this call ALSPMC_fnc_questKilled}];

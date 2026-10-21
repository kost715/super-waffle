params ["_mode", ["_job", createHashMap], ["_members", []]];
if (!isServer) exitWith {false};
switch (_mode) do {
    case "start": {
        private _qid = _job getOrDefault ["alspmcQuestId", -1];
        private _row = ALSPMC_questRecords getOrDefault [_qid, []];
        if (count _row != 8 || {(_row select 1) != "starting"} || {
            !((_row select 4) isEqualTo (_job get "team"))
        } || {(_row select 0) != (_job get "alspmcFounder")}) exitWith {false};
        _job set ["alspmcObjects", []]; _job set ["alspmcGroups", []];
        _job set ["alspmcEnemies", []]; _job set ["alspmcMines", []];
        _job set ["alspmcCasualties", []]; _job set ["alspmcResult", ""];
        _job set ["alspmcRoster", (_job get "team") apply {[_x, [_x] call ALS_fnc_findPlayer]}];
        _job set ["alspmcStartedAt", diag_tickTime]; _job set ["alspmcAttackDone", false];
        _job set ["alspmcAttackPlanned", random 1 < ((getNumber (configFile >> "ALSPMC_Settings" >> "contractAttackChance")) max 0 min 1)];
        _job set ["alspmcRadius", if ((_job get "alspmcMode") == "mines") then {75} else {(getNumber (configFile >> "ALSPMC_Settings" >> "contractSectorRadius")) max 100}];
        _job set ["alspmcDutySeconds", (getNumber (configFile >> "ALSPMC_Settings" >> "contractDutySeconds")) max 1];
        private _kind = _job get "alspmcMode";
        private _ok = true;
        if (_kind in ["bandits", "enemyPatrol", "base"]) then {
            _ok = if (_kind == "base") then {["acquire", _job] call ALSPMC_fnc_contractGarrison} else {[_job, _job get "alspmcSite"] call ALSPMC_fnc_contractAttack};
            _job set ["state", "combat"];
        } else {
            _job set ["state", if (_kind in ["base", "mines"]) then {"travel"} else {"rendezvous"}];
        };
        if (!_ok) exitWith {["release", _job] call ALSPMC_fnc_contractHostility; false};
        _row set [1, "active"];
        true
    };
    case "tick": {[_job, _members] call ALSPMC_fnc_contractTick};
    case "end": {
        private _truck = _job getOrDefault ["alspmcTruck", objNull];
        if (!isNull _truck) then {[_truck] call ALS_fnc_drvStop};
        // Only our objects/groups. Native garrisons, buildings and the player's
        // real group are deliberately absent from the cleanup list.
        {if (!isNull _x) then {deleteVehicle _x}} forEach (_job getOrDefault ["alspmcObjects", []]);
        {if (!isNull _x) then {deleteGroup _x}} forEach (_job getOrDefault ["alspmcGroups", []]);
        if (_job getOrDefault ["alspmcBaseLeased", false]) then {["release", _job] call ALSPMC_fnc_contractGarrison};
        ["release", _job] call ALSPMC_fnc_contractHostility;
        true
    };
    default {false};
}

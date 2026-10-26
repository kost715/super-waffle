// New scenario, existing native lifecycle. No coopAccept/Tick/End replacement.
params ["_mode", ["_job", createHashMap], ["_members", []]];
if (!isServer) exitWith {false};
switch (_mode) do {
    case "start": {
        private _qid = _job getOrDefault ["alspmcQuestId", -1];
        private _row = ALSPMC_questRecords getOrDefault [_qid, []];
        if (count _row != 8 || {(_row select 1) != "starting"} || {
            (_row select 0) != (_job getOrDefault ["alspmcFounder", ""])
        } || {!((_row select 4) isEqualTo (_job get "team"))}) exitWith {false};
        private _side = ["side", _job] call ALSPMC_fnc_contractHostility;
        if (_side isEqualType false) exitWith {false};
        private _group = createGroup [_side, true];
        if (isNull _group) exitWith {false};
        private _target = _group createUnit ["O_G_Soldier_F", _job get "pos", [], 0, "NONE"];
        if (isNull _target) exitWith {deleteGroup _group; false};
        _target addRating 10000;
        _target addEventHandler ["HandleRating", {0}];
        _target setCaptive false;
        _target setVariable ["ALS_hitSquad", true, true];
        _target setVariable ["ALS_hostile", true, true];
        _target setVariable ["ALS_jobEvObj", true];
        _target setVariable ["ALS_npcName", localize "STR_ALSPMC_quest_target", true];
        _target setVariable ["ALSPMC_questTarget", [_job get "id", _qid]];
        _target setSkill 0.35;
        _target disableAI "PATH";
        _group setBehaviour "AWARE";
        _group setCombatMode "RED";
        _job set ["alspmcTarget", _target]; _job set ["alspmcGroup", _group];
        _job set ["alspmcGroups", [_group]];
        _job set ["alspmcRoster", (_job get "team") apply {[_x, [_x] call ALS_fnc_findPlayer]}];
        ["acquire", _job] call ALSPMC_fnc_contractHostility;
        _job set ["alspmcResult", ""]; _job set ["state", "hunt"];
        _job set ["alspmcTimeout", (getNumber (configFile >> "ALSPMC_Settings" >> "questTimeout")) max 60];
        _row set [1, "active"];
        true
    };
    case "tick": {
        ["tick", _job] call ALSPMC_fnc_contractHostility;
        private _target = _job getOrDefault ["alspmcTarget", objNull];
        private _result = _job getOrDefault ["alspmcResult", ""];
        if (_result == "killed") exitWith {["done", 1]};
        if (_result != "") exitWith {["failed", 0]};
        if (isNull _target || {!alive _target}) exitWith {_job set ["alspmcResult", "lost"]; ["failed", 0]};
        if (time - (_job get "since") > (_job get "alspmcTimeout")) exitWith {_job set ["alspmcResult", "timeout"]; ["failed", 0]};
        private _pos = getPosATL _target;
        _job set ["pos", _pos];
        {
            _x setVariable ["ALS_sideNav", [[_pos, localize "STR_ALSPMC_quest_target", "gang"]], true];
            _x setVariable ["ALS_coopJob", createHashMapFromArray [["id", _job get "id"], ["title", _job get "title"],
                ["state", "hunt"], ["status", "Eliminate the marked hostile."], ["progLabel", "Target"],
                ["progText", "0 / 1"], ["pay", _job get "pay"], ["alspmc", true], ["pos", _pos]], true];
        } forEach _members;
        ["on"]
    };
    case "end": {
        if (_job getOrDefault ["alspmcEnded", false]) exitWith {};
        _job set ["alspmcEnded", true];
        // Native coopEnd publishes crews after this; see ALSPMC_fnc_contractEnd.
        if (_job getOrDefault ["alspmcCreatedCrew", false]) then {
            private _crew = ALS_crews getOrDefault [_job get "crew", createHashMap];
            if (count _crew > 0 && {count (_crew get "members") <= 1}) then {ALS_crews deleteAt (_crew get "id")};
        };
        private _target = _job getOrDefault ["alspmcTarget", objNull];
        private _group = _job getOrDefault ["alspmcGroup", grpNull];
        // Remove only this scenario's target, including loot, on every exit.
        if (!isNull _target) then {deleteVehicle _target};
        if (!isNull _group) then {deleteGroup _group};
        ["release", _job] call ALSPMC_fnc_contractHostility;
        private _row = ALSPMC_questRecords getOrDefault [_job get "alspmcQuestId", []];
        if (count _row == 8 && {(_row select 1) == "active"}) then {
            private _reason = _job getOrDefault ["alspmcResult", ""];
            if (_reason == "") then {_reason = "empty"};
            private _won = _members isEqualType 0 && {_members > 0} && {_reason == "killed"};
            if (!_won && {_reason == "killed"}) then {_reason = "empty"};
            _row set [1, if (_won) then {"done"} else {if (_reason == "cancelled") then {"cancelled"} else {"failed"}}];
            _row set [6, date]; _row set [7, _reason];
            // Native coopEnd has already changed the native wallets. Save the
            // money and this receipt together; the addon never adds money.
            call ALSPMC_fnc_questSave;
            call ALS_fnc_dbSave;
        };
    };
    default {false};
}

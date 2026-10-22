params ["_request", "_share"];
if !(_request getOrDefault ["alspmcContract", false]) exitWith {_this call ALSPMC_nativeCoopEnd};
if (!isServer) exitWith {false};
private _out = false;
isNil {
    private _job = ALS_coopJobs getOrDefault [_request get "id", createHashMap];
    if (count _job == 0 || {(_job getOrDefault ["alspmcQuestId", -1]) != (_request get "alspmcQuestId")} || {
        !(_job getOrDefault ["alspmcContract", false]) || {_job getOrDefault ["alspmcEnding", false]}
    }) exitWith {};
    private _crew = ALS_crews getOrDefault [_job get "crew", createHashMap];
    private _connected = ((_crew getOrDefault ["members", []]) apply {[_x] call ALS_fnc_findPlayer}) select {!isNull _x};
    private _reason = _job getOrDefault ["alspmcResult", ""];
    if (_connected isEqualTo []) then {_reason = "empty"};
    // A remote forged result/share cannot settle an ongoing server contract.
    if (_reason == "") exitWith {};
    private _qid = _job get "alspmcQuestId";
    private _row = ALSPMC_questRecords getOrDefault [_qid, []];
    private _meta = ALSPMC_contractMeta getOrDefault [_qid, []];
    if (count _row != 8 || {(_row select 1) != "active"} || {count _meta != 4}) exitWith {};
    _job set ["alspmcEnding", true];
    private _won = _reason == "complete";
    private _reward = if (_won) then {_row select 2} else {0};
    if (_reward > 0 && {(_meta select 3) == 0}) then {
        private _companyID = _job getOrDefault ["alspmcCompany", ""];
        private _paid = if (_companyID != "") then {[_companyID, _qid, _reward, _row select 0] call ALSPMC_fnc_companyReward} else {
            [_row select 0, 0, _reward] call ALS_fnc_moneyAdd
        };
        if (!_paid) then {_won = false; _reason = "payment"};
    };
    if (_reason == "payment") exitWith {_job set ["alspmcEnding", false]};
    if (_won) then {
        _meta set [3, _reward];
        private _founder = _job getOrDefault ["alspmcRatingOwner", _row select 0];
        ALSPMC_ratingXP set [_founder, ((ALSPMC_ratingXP getOrDefault [_founder, 0]) + (_meta select 2)) min 100000000];
    };
    _row set [1, if (_won) then {"done"} else {if (_reason == "cancelled") then {"cancelled"} else {
        if (_reason in ["site", "spawn", "empty"]) then {"interrupted"} else {"failed"}
    }}];
    _row set [6, date]; _row set [7, _reason];
    ["end", _job, [0,1] select _won] call ALSPMC_fnc_contractScenario;
    private _recipients = ((_job get "team") + (_crew getOrDefault ["members", []])) arrayIntersect ((_job get "team") + (_crew getOrDefault ["members", []]));
    {
        private _unit = [_x] call ALS_fnc_findPlayer;
        if (!isNull _unit) then {
            private _mirror = _unit getVariable ["ALS_coopJob", createHashMap];
            if ((_mirror getOrDefault ["alspmcQuestId", -1]) == _qid) then {
                _unit setVariable ["ALS_coopJob", nil, true]; _unit setVariable ["ALS_sideNav", [], true];
            };
            [["STR_ALSPMC_contract_failed", "STR_ALSPMC_contract_done"] select _won, [_reward]] remoteExecCall ["ALSPMC_fnc_message", _unit];
        };
    } forEach _recipients;
    ALS_coopJobs deleteAt (_job get "id");
    if (count _crew > 0 && {(_crew get "job") == (_job get "id")}) then {_crew set ["job", -1]; _crew set ["offersAt", -1e9]};
    // Remove the one-member crew created for a solo operation: native crewDo
    // refuses invitations to anyone already in a crew. A crew others joined stays.
    if (_job getOrDefault ["alspmcCreatedCrew", false] && {count _crew > 0} && {
        count (_crew get "members") <= 1
    } && {(_crew get "job") isEqualTo -1}) then {ALS_crews deleteAt (_crew get "id")};
    private _ratingOwner = _job getOrDefault ["alspmcRatingOwner", _row select 0];
    private _founderUnit = [_ratingOwner] call ALS_fnc_findPlayer;
    // The board belongs to the owner; any online member can stand in for them.
    if (isNull _founderUnit) then {
        private _company = ALSPMC_companies getOrDefault [_job getOrDefault ["alspmcCompany", ""], createHashMap];
        {
            private _member = [_x] call ALS_fnc_findPlayer;
            if (!isNull _member) exitWith {_founderUnit = _member};
        } forEach (keys (_company getOrDefault ["members", createHashMap]));
    };
    private _settlement = [_meta select 0, _won, _job getOrDefault ["alspmcOfferSlot", ""]];
    if (!isNull _founderUnit) then {
        ([_founderUnit] + _settlement) call ALSPMC_fnc_contractOffers;
    } else {
        // Nobody to plan sites for now: settle the slot at the next board view, so
        // a failed type still returns instead of the whole board being rerolled.
        private _queue = missionNamespace getVariable ["ALSPMC_boardSettlements", createHashMap];
        _queue set [_ratingOwner, (_queue getOrDefault [_ratingOwner, []]) + [_settlement]];
        ALSPMC_boardSettlements = _queue;
    };
    call ALS_fnc_crewPublish;
    call ALSPMC_fnc_questSave;
    // One native DB snapshot commits the company/legacy wallet, XP and result receipt.
    call ALS_fnc_dbSave;
    _out = true;
    true
};
_out

params ["_unit", "_op", "_arg", "_token"];
if !([_unit] call ALSPMC_fnc_requestAllowed) exitWith {false};
if (!(missionNamespace getVariable ["ALSPMC_questsReady", false]) || {!(_arg isEqualType "")} || {_token <= 0}) exitWith {false};
private _uid = [_unit] call ALS_fnc_uid;
private _cache = ALSPMC_questRequests getOrDefault [_uid, []];
private _seen = _cache findIf {(_x select 0) == _token};
if (_seen >= 0) exitWith {
    private _old = _cache select _seen;
    (_old select 1) == _op && {(_old select 2) == _arg} && {_old select 3}
};
private _ok = false;
isNil {
    private _crew = [_uid] call ALS_fnc_crewOf;
    if (_op == "questReady") exitWith {
        private _job = ALS_coopJobs getOrDefault [_crew getOrDefault ["job", -1], createHashMap];
        if (!(_job getOrDefault ["alspmcContract", false]) || {"q" + str (_job get "alspmcQuestId") != _arg}) exitWith {};
        _ok = [_unit, _job] call ALSPMC_fnc_contractReady;
    };
    if (_op == "questCancel") exitWith {
        private _job = ALS_coopJobs getOrDefault [_crew getOrDefault ["job", -1], createHashMap];
        if (!("alspmcQuestId" in _job) || {
            !([_uid, _job, _crew] call ALSPMC_fnc_contractBoss)
        } || {"q" + str (_job get "alspmcQuestId") != _arg} || {
            _job getOrDefault ["alspmcEnded", false]
        } || {(_job getOrDefault ["alspmcResult", ""]) != ""}) exitWith {};
        _job set ["alspmcResult", "cancelled"];
        [_job, 0] call ALS_fnc_coopEnd;
        _ok = true;
    };
    if (_op != "questStart") exitWith {};
    private _state = [_unit] call ALSPMC_fnc_questState;
    if !(_state get "canStart") exitWith {};
    // Keep old test records readable, but never accept new prototype payouts.
    if (_arg == "eliminate" && {missionNamespace getVariable ["ALSPMC_companiesReady", false]}) exitWith {};
    private _entry = [];
    private _type = "eliminate";
    private _selection = "";
    private _ticket = "";
    private _board = createHashMap;
    if (_arg != "eliminate") then {
        private _parts = _arg splitString "|";
        _ticket = _parts param [0, ""];
        _selection = _parts param [1, ""];
        _board = [_unit] call ALSPMC_fnc_contractOffers;
        private _offered = ((_board get "offers") select {(_x select 0) == _ticket}) param [0, []];
        if (count _offered == 2 && {count _parts <= 2}) then {
            _type = _offered select 1;
            _entry = ((call ALSPMC_fnc_contractCatalog) select {(_x select 0) == _type}) param [0, []];
        };
    };
    if (_arg != "eliminate" && {_entry isEqualTo []}) exitWith {};
    private _plan = createHashMap;
    private _profile = [_uid, _entry param [2, ""]] call ALSPMC_fnc_contractProfile;
    if (_entry isNotEqualTo []) then {
        if (missionNamespace getVariable ["ALSPMC_contractsReady", false] && {(_profile get "level") >= (_entry select 3)}) then {
            _plan = [_unit, _entry, _selection] call ALSPMC_fnc_contractPlan;
        };
    };
    private _pos = if (_entry isEqualTo []) then {[_unit] call ALSPMC_fnc_questSite} else {_plan getOrDefault ["site", []]};
    if (_pos isEqualTo []) exitWith {
        ["STR_ALSPMC_quest_no_site"] remoteExecCall ["ALSPMC_fnc_message", _unit];
    };
    private _company = [_uid] call ALSPMC_fnc_companyOf;
    if (count _company == 0) exitWith {};
    private _pay = if (_entry isEqualTo []) then {_state get "pay"} else {round ((_entry select 4) * (_profile get "multiplier"))};
    if ((_company get "balance") + _pay > 10000000) exitWith {
        ["STR_ALSPMC_treasury_room"] remoteExecCall ["ALSPMC_fnc_message", _unit];
    };
    private _createdCrew = count _crew == 0;
    if (_createdCrew) then {
        // Same valid one-member schema as native crewDo's initial invitation.
        ALS_crewSeq = ALS_crewSeq + 1;
        _crew = createHashMapFromArray [["id", "c" + str ALS_crewSeq], ["leader", _uid], ["members", [_uid]], ["job", -1]];
        ALS_crews set [_crew get "id", _crew];
    };
    ALS_coopSeq = ALS_coopSeq + 1;
    ALSPMC_questSequence = ALSPMC_questSequence + 1;
    private _qid = ALSPMC_questSequence;
    private _team = (_crew get "members") select {!isNull ([_x] call ALS_fnc_findPlayer)};
    ALSPMC_questRecords set [_qid, [_uid, "starting", _pay, _pos, +_team, date, [], ""]];
    private _offer = createHashMapFromArray [
        ["id", ALS_coopSeq], ["kind", "alspmc_eliminate"], ["min", 1], ["pay", _pay],
        // Native phonePush injects raw JSON into ExecJS. ASCII here also keeps
        // the original English phone safe; our own app uses escaped Russian.
        ["title", "PMC: eliminate one target"], ["brief", "Eliminate the marked hostile. Starting crew members only."],
        ["pos", _pos], ["alspmcQuestId", _qid], ["alspmcFounder", _uid],
        ["alspmcCompany", _company get "id"], ["alspmcRatingOwner", _company get "owner"]
    ];
    private _oldOffers = +(_crew getOrDefault ["offers", []]);
    if (_entry isNotEqualTo []) then {
        _offer set ["kind", "alspmc_contract"]; _offer set ["alspmcContract", true];
        _offer set ["alspmcType", _type]; _offer set ["alspmcMode", _entry select 2];
        _offer set ["alspmcProfile", _profile]; _offer set ["alspmcPlan", _plan];
        // LifeSim 0.13.0 shows these in its Crew app through fix(), which
        // decodes the UTF-8 that ExecJS hands over, so Russian text is safe.
        _offer set ["alspmcSite", _pos]; _offer set ["title", localize ("STR_ALSPMC_title_" + _type)];
        _offer set ["brief", localize "STR_ALSPMC_contract_brief"];
        ALSPMC_contractMeta set [_qid, [_type, _profile get "level", _entry select 5, 0]];
    };
    _crew set ["offers", _oldOffers + [_offer]];
    _ok = [_unit, _offer get "id"] call ALS_fnc_coopAccept;
    if (!_ok) then {
        _crew set ["offers", _oldOffers];
        ALSPMC_questRecords deleteAt _qid;
        if (_entry isNotEqualTo []) then {ALSPMC_contractMeta deleteAt _qid};
        if (_createdCrew) then {ALS_crews deleteAt (_crew get "id")};
        call ALS_fnc_crewPublish;
    } else {
        private _job = ALS_coopJobs get (_offer get "id");
        if (_createdCrew) then {_job set ["alspmcCreatedCrew", true]};
        if (_entry isNotEqualTo []) then {
            // Keep six visible slots while an operation is active. The consumed
            // ticket is gone; its reserved slot cannot be used while we're busy.
            ALSPMC_boardSequence = ALSPMC_boardSequence + 1;
            private _slot = "o" + str ALSPMC_boardSequence + "_" + _type;
            private _offers = _board get "offers";
            private _at = _offers findIf {(_x select 0) == _ticket};
            if (_at >= 0) then {_offers set [_at, [_slot, _type]]};
            _job set ["alspmcOfferSlot", _slot];
        };
        private _members = _team apply {[_x] call ALS_fnc_findPlayer};
        if (_entry isEqualTo []) then {["tick", _job, _members] call ALSPMC_fnc_questScenario} else {[_job, _members] call ALSPMC_fnc_contractMirror};
        // No money moved yet: the periodic save is enough. A restart before it
        // simply leaves no record of an operation that is interrupted anyway.
        call ALSPMC_fnc_questSave;
    };
};
_cache pushBack [_token, _op, _arg, _ok];
if (count _cache > 32) then {_cache deleteAt 0};
ALSPMC_questRequests set [_uid, _cache];
_ok

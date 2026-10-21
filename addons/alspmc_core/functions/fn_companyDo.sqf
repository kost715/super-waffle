// Only desktopDo calls management operations. Phone can accept/decline an invite.
params ["_unit", "_op", "_arg", ["_computer", objNull]];
if (!([_unit] call ALSPMC_fnc_requestAllowed) || {!(missionNamespace getVariable ["ALSPMC_companiesReady", false])}) exitWith {false};
if !(_arg isEqualType [] && {count _arg == 2}) exitWith {false};
_arg params ["_revision", "_value"];
private _uid = [_unit] call ALS_fnc_uid;
private _ok = false;
isNil {
    private _c = [_uid] call ALSPMC_fnc_companyOf;
    if (_op in ["companyAccept", "companyDecline"]) exitWith {
        if !(_value isEqualType "") exitWith {};
        private _invite = ALSPMC_companyInvites getOrDefault [_uid, []];
        if (count _invite != 2 || {(_invite select 0) != _value} || {diag_tickTime >= (_invite select 1)}) exitWith {};
        if (_op == "companyDecline") exitWith {ALSPMC_companyInvites deleteAt _uid; _ok = true};
        private _target = ALSPMC_companies getOrDefault [_value, createHashMap];
        if (count _c > 0 || {count _target == 0}) exitWith {};
        (_target get "members") set [_uid, "member"];
        _target set ["revision", (_target get "revision") + 1];
        private _ledger = _target get "ledger";
        _ledger insert [0, [[date, _uid, 0, "join", _uid]]]; _target set ["ledger", _ledger select [0,100]];
        ALSPMC_companyInvites deleteAt _uid;
        _ok = true;
    };
    if (count _c == 0 || {isNull _computer} || {!([_unit, _computer] call ALSPMC_fnc_terminalCanUse)}) exitWith {};
    private _base = ALSPMC_bases getOrDefault [_computer getVariable ["ALSPMC_terminalKey", ""], []];
    if (_base isEqualTo [] || {(_base select 0) != (_c get "owner")}) exitWith {};
    // Persistent revision: duplicate, delayed and concurrent packets fail closed.
    if !(_revision isEqualType 0 && {finite _revision} && {_revision == (_c get "revision")}) exitWith {};
    private _role = (_c get "members") get _uid;
    private _members = _c get "members";
    private _delta = 0;
    switch (_op) do {
        case "companyInvite": {
            if (!(_role in ["owner", "manager"]) || {!(_value isEqualType "")} || {_value == ""} || {
                isNull ([_value] call ALS_fnc_findPlayer) || {count ([_value] call ALSPMC_fnc_companyOf) > 0}
            }) exitWith {};
            ALSPMC_companyInvites set [_value, [_c get "id", diag_tickTime + 600]];
            ["STR_ALSPMC_company_invite"] remoteExecCall ["ALSPMC_fnc_message", [_value] call ALS_fnc_findPlayer];
            _ok = true;
        };
        case "companyPromote";
        case "companyDemote";
        case "companyRemove": {
            if (_role != "owner" || {!(_value isEqualType "")} || {!(_value in _members)} || {_value == _uid}) exitWith {};
            if (_op in ["companyRemove", "companyDemote"] && {((values ALS_coopJobs) findIf {(_x getOrDefault ["alspmcCompany", ""]) == (_c get "id")}) >= 0}) exitWith {};
            if (_op == "companyRemove") then {_members deleteAt _value} else {_members set [_value, ["member", "manager"] select (_op == "companyPromote")]};
            _ok = true;
        };
        case "companyLeave": {
            if (_role == "owner") exitWith {};
            // Do not change the beneficiary/permissions halfway through a job.
            if (((values ALS_coopJobs) findIf {(_x getOrDefault ["alspmcCompany", ""]) == (_c get "id")}) >= 0) exitWith {};
            _members deleteAt _uid; _ok = true;
        };
        case "companyDeposit";
        case "companyWithdraw": {
            if !(_value isEqualType 0 && {finite _value} && {_value > 0} && {_value <= 10000000} && {_value == floor _value}) exitWith {};
            private _balance = _c get "balance";
            if (_op == "companyWithdraw" && {_role != "owner" || {_value > (_balance - (_c get "debt") - (_c get "reserve"))}}) exitWith {};
            private _incoming = 0;
            {if ((_x getOrDefault ["alspmcCompany", ""]) == (_c get "id")) then {_incoming = _incoming + (_x get "pay")}} forEach (values ALS_coopJobs);
            // Leave room for the accepted contract, so a deposit cannot block its payout.
            if (_op == "companyDeposit" && {_balance + _value + _incoming > 10000000}) exitWith {};
            _delta = [_value, -_value] select (_op == "companyWithdraw");
            if !([_uid, 0, -_delta] call ALS_fnc_moneyAdd) exitWith {};
            _c set ["balance", _balance + _delta];
            _ok = true;
        };
    };
    if (_ok) then {
        _c set ["revision", (_c get "revision") + 1];
        private _ledger = _c get "ledger";
        _ledger insert [0, [[date, _uid, _delta, _op, str _value]]]; _c set ["ledger", _ledger select [0,100]];
    };
};
if (_ok) then {call ALSPMC_fnc_companySave; call ALS_fnc_dbSave; call ALSPMC_fnc_companyTick};
_ok

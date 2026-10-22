params ["_unit", ["_desktop", false]];
private _uid = [_unit] call ALS_fnc_uid;
private _c = [_uid] call ALSPMC_fnc_companyOf;
private _invites = [];
{
    if (diag_tickTime < _y) then {
        private _from = ALSPMC_companies getOrDefault [_x, createHashMap];
        if (count _from > 0) then {_invites pushBack createHashMapFromArray [["id", _x], ["name", ALSPMC_names getOrDefault [_from get "owner", []]]]};
    };
} forEach ((missionNamespace getVariable ["ALSPMC_companyInvites", createHashMap]) getOrDefault [_uid, createHashMap]);
private _s = createHashMapFromArray [["ready", missionNamespace getVariable ["ALSPMC_companiesReady", false]], ["invites", _invites]];
if (count _c == 0) exitWith {_s};
private _role = (_c get "members") get _uid;
{_s set [_x, _c get _x]} forEach ["id", "balance", "debt", "reserve", "seconds", "revision"];
_s set ["role", _role];
_s set ["free", ((_c get "balance") - (_c get "debt") - (_c get "reserve")) max 0];
if (_desktop) then {
    _s set ["members", (keys (_c get "members")) apply {
        createHashMapFromArray [["uid", _x], ["role", (_c get "members") get _x], ["name", [_x] call ALSPMC_fnc_playerName], ["online", !isNull ([_x] call ALS_fnc_findPlayer)]]
    }];
    // Headless clients are listed by allPlayers but are not people to hire.
    _s set ["candidates", if (_role in ["owner", "manager"]) then {((allPlayers - entities "HeadlessClient_F") select {
        count ([[_x] call ALS_fnc_uid] call ALSPMC_fnc_companyOf) == 0
    }) apply {createHashMapFromArray [["uid", [_x] call ALS_fnc_uid], ["name", toArray name _x]]}} else {[]}];
    private _ledger = +(_c get "ledger");
    _s set ["ledger", _ledger];
    private _names = createHashMap;
    {_names set [_x select 1, [_x select 1] call ALSPMC_fnc_playerName]} forEach _ledger;
    _s set ["names", _names];
};
_s

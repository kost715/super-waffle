// Wraps LifeSim's "start a new career" (pause menu, fn_menuMsg). The original
// wipes the player's own money, licences and houses but knows nothing of PMC
// keys, so a treasury would carry a fortune across the fresh start. Our records
// are cleared first, then the original runs unchanged with the same arguments.
params ["_p"];
if (!isServer) exitWith {false};
// Refused requests stay the original's to refuse; never clear anything for them.
if (isNull _p || {!isPlayer _p} || {isRemoteExecuted && {remoteExecutedOwner != owner _p}} || {
    ([_p] call ALS_fnc_uid) == ""
} || {!(missionNamespace getVariable ["ALSPMC_companiesReady", false])}) exitWith {_this call ALSPMC_nativeCareerRestart};
private _uid = [_p] call ALS_fnc_uid;
isNil {
    ALSPMC_companyInvites deleteAt _uid;
    private _c = [_uid] call ALSPMC_fnc_companyOf;
    if (count _c == 0) exitWith {};
    private _id = _c get "id";
    if ((_c get "owner") != _uid) exitWith {
        (_c get "members") deleteAt _uid;
        _c set ["revision", (_c get "revision") + 1];
        private _ledger = _c get "ledger";
        _ledger insert [0, [[date, _uid, 0, "careerRestart", _uid]]]; _c set ["ledger", _ledger select [0,100]];
        call ALSPMC_fnc_companySave;
        ["STR_ALSPMC_company_left_restart"] remoteExecCall ["ALSPMC_fnc_message", _p];
    };
    // The owner closes the company: the treasury is forfeited with the old
    // career, a running operation ends unpaid and the employees are free.
    {
        if ((_x getOrDefault ["alspmcCompany", ""]) == _id && {(_x getOrDefault ["alspmcResult", ""]) == ""}) then {
            _x set ["alspmcResult", "cancelled"];
            [_x, 0] call ALS_fnc_coopEnd;
        };
    } forEach (values ALS_coopJobs);
    {
        private _member = [_x] call ALS_fnc_findPlayer;
        if (_x != _uid && {!isNull _member}) then {["STR_ALSPMC_company_closed_member"] remoteExecCall ["ALSPMC_fnc_message", _member]};
    } forEach (keys (_c get "members"));
    ALSPMC_companies deleteAt _id;
    {_y deleteAt _id} forEach ALSPMC_companyInvites;
    call ALSPMC_fnc_companySave;
    ALSPMC_contractBoards deleteAt _uid;
    (missionNamespace getVariable ["ALSPMC_boardSettlements", createHashMap]) deleteAt _uid;
    if (missionNamespace getVariable ["ALSPMC_contractsReady", false]) then {
        ALSPMC_ratingXP deleteAt _uid;
        call ALSPMC_fnc_contractSave;
    };
    if (missionNamespace getVariable ["ALSPMC_namesReady", false]) then {
        ALSPMC_names deleteAt _uid;
        ["alspmc_names_v1", (keys ALSPMC_names) apply {[_x, +(ALSPMC_names get _x)]}] call ALS_fnc_dbSet;
    };
    ["STR_ALSPMC_company_closed_owner"] remoteExecCall ["ALSPMC_fnc_message", _p];
};
// The original ends with LifeSim's world save, which commits the keys above.
_this call ALSPMC_nativeCareerRestart

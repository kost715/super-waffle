if (!isServer || {!(missionNamespace getVariable ["ALSPMC_companiesReady", false])}) exitWith {};
private _now = diag_tickTime;
private _elapsed = (_now - (missionNamespace getVariable ["ALSPMC_companyClockAt", _now])) max 0;
ALSPMC_companyClockAt = _now;
{
    private _c = _y;
    if (((keys (_c get "members")) findIf {!isNull ([_x] call ALS_fnc_findPlayer)}) >= 0) then {
        _c set ["seconds", (_c get "seconds") + _elapsed];
    };
} forEach ALSPMC_companies;
// Addressed, changed-only access snapshots are just an action visibility hint.
// The server always rechecks current membership and native base ownership.
{
    private _unit = _x;
    private _c = [[_unit] call ALS_fnc_uid] call ALSPMC_fnc_companyOf;
    private _access = createHashMap;
    if (count _c > 0) then {
        {if ((_y select 0) == (_c get "owner") && {[_c get "owner", ALS_owned getOrDefault [_x, ""]] call ALS_fnc_canUse}) then {_access set [_x, true]}} forEach ALSPMC_bases;
    };
    if !(_access isEqualTo (_unit getVariable ["ALSPMC_companyAccess", createHashMap])) then {
        _unit setVariable ["ALSPMC_companyAccess", _access];
        ["ALSPMC_companyAccess", _access] remoteExecCall ["ALSPMC_fnc_stateSet", _unit];
    };
} forEach allPlayers;
call ALSPMC_fnc_companySave;

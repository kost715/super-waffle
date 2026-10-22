if (!isServer || {isRemoteExecuted && {!isNil "_fnc_scriptNameParent"} && {_fnc_scriptNameParent == _fnc_scriptName}} || {!(missionNamespace getVariable ["ALSPMC_companiesReady", false])}) exitWith {};
private _now = diag_tickTime;
private _elapsed = (_now - (missionNamespace getVariable ["ALSPMC_companyClockAt", _now])) max 0;
ALSPMC_companyClockAt = _now;
private _names = missionNamespace getVariable ["ALSPMC_playerNames", createHashMap];
private _renamed = false;
{
    private _c = _y;
    private _online = false;
    {
        private _p = [_x] call ALS_fnc_findPlayer;
        if (!isNull _p) then {
            _online = true;
            // Remember the last name seen, for members and ledgers while offline.
            private _bytes = toArray name _p;
            if !((_names getOrDefault [_x, []]) isEqualTo _bytes) then {_names set [_x, _bytes]; _renamed = true};
        };
    } forEach (keys (_c get "members"));
    if (_online) then {_c set ["seconds", (_c get "seconds") + _elapsed]};
} forEach ALSPMC_companies;
ALSPMC_playerNames = _names;
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
// The active-time counter alone is written once a minute, not every tick, so
// LifeSim's DB is not marked changed (and written to disk) at every save.
if (_renamed || {_now - (missionNamespace getVariable ["ALSPMC_companySavedAt", -1e9]) >= 60}) then {
    call ALSPMC_fnc_companySave;
};

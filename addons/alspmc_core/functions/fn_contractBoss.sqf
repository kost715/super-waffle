// Company operations require a current owner/manager; callers also check the roster.
// The founder/temporary-leader fallback below applies to legacy operations only.
params ["_uid", "_job", "_crew"];
private _companyID = _job getOrDefault ["alspmcCompany", ""];
if (_companyID != "") exitWith {
    private _c = [_uid] call ALSPMC_fnc_companyOf;
    count _c > 0 && {(_c get "id") == _companyID} && {((_c get "members") get _uid) in ["owner", "manager"]}
};
private _founder = _job getOrDefault ["alspmcFounder", ""];
if (_founder == "") exitWith {(_crew getOrDefault ["leader", ""]) == _uid};
_uid == _founder || {isNull ([_founder] call ALS_fnc_findPlayer) && {(_crew getOrDefault ["leader", ""]) == _uid}}

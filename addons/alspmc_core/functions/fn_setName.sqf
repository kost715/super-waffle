params [["_unit", objNull, [objNull]], ["_bytes", [], [[]]]];
if !([_unit] call ALSPMC_fnc_requestAllowed) exitWith {false};
private _uid = [_unit] call ALS_fnc_uid;
if (!(missionNamespace getVariable ["ALSPMC_companiesReady", false])) exitWith {false};
private _company = [_uid] call ALSPMC_fnc_companyOf;
if (count _company > 0 && {(_company get "owner") != _uid}) exitWith {false};
if !("alspmc_pmc" in (["lic_" + _uid, []] call ALS_fnc_dbGet)) exitWith {
    ["STR_ALSPMC_need_license"] remoteExecCall ["ALSPMC_fnc_message", _unit]; false
};
if !(missionNamespace getVariable ["ALSPMC_namesReady", false]) exitWith {false};
private _name = [_bytes] call ALSPMC_fnc_normalizeName;
if (_name isEqualTo []) exitWith {
    ["STR_ALSPMC_invalid_name"] remoteExecCall ["ALSPMC_fnc_message", _unit]; false
};
ALSPMC_names set [_uid, _name];
[_uid] call ALSPMC_fnc_companyEnsure;
// Written to the world DB now; LifeSim's periodic save commits it to disk.
["alspmc_names_v1", (keys ALSPMC_names) apply {[_x, +(ALSPMC_names get _x)]}] call ALS_fnc_dbSet;
["STR_ALSPMC_name_saved"] remoteExecCall ["ALSPMC_fnc_message", _unit];
true

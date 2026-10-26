params [["_unit", objNull, [objNull]], ["_computer", objNull, [objNull]]];
if (isNull _unit || {isNull _computer} || {!alive _unit} || {_unit distance _computer > 4}) exitWith {false};
private _key = _computer getVariable ["ALSPMC_terminalKey", ""];
if (_key == "") exitWith {false};
if (isServer) exitWith {
    private _registered = (missionNamespace getVariable ["ALSPMC_terminals", createHashMap]) getOrDefault [_key, [objNull, []]];
    if ((_registered select 0) != _computer || {!(_key in ALSPMC_bases)}) exitWith {false};
    private _uid = [_unit] call ALS_fnc_uid;
    private _c = [_uid] call ALSPMC_fnc_companyOf;
    private _founder = (ALSPMC_bases get _key) select 0;
    [_uid, ALS_owned getOrDefault [_key, ""]] call ALS_fnc_canUse || {
        count _c > 0 && {(_c get "owner") == _founder} && {[_founder, ALS_owned getOrDefault [_key, ""]] call ALS_fnc_canUse}
    }
};
private _found = (missionNamespace getVariable ["ALSPMC_terminalsPublic", []]) findIf {(_x select 0) == _key && {(_x select 1) == _computer}};
_found >= 0 && {(_key in (player getVariable ["ALSPMC_companyAccess", createHashMap])) || {
    (((player getVariable ["ALSPMC_phoneState", createHashMap]) getOrDefault ["bases", []]) findIf {(_x get "key") == _key}) >= 0
} || {((missionNamespace getVariable ["ALS_ownedPublic", []]) findIf {
    (_x select 0) == _key && {[_x select 2] call ALS_fnc_mine}
}) >= 0}}

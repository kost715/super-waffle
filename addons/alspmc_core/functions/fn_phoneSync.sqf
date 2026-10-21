params ["_unit", ["_reply", 0], ["_ok", true]];
if (!isServer) exitWith {};
private _uid = [_unit] call ALS_fnc_uid;
private _company = [_uid] call ALSPMC_fnc_companyOf;
private _founder = if (count _company > 0) then {_company get "owner"} else {_uid};
private _license = "alspmc_pmc" in (["lic_" + _founder, []] call ALS_fnc_dbGet);
private _bases = [];
{
    private _key = _x;
    private _owner = ALS_owned getOrDefault [_key, ""];
    if ([_uid, _owner] call ALS_fnc_canUse || {count _company > 0 && {(_y select 0) == _founder} && {[_founder, _owner] call ALS_fnc_canUse}}) then {
        private _h = ALS_houses getOrDefault [_key, []];
        private _co = (missionNamespace getVariable ["ALS_companies", createHashMap]) getOrDefault [_owner, createHashMap];
        if (count _h >= 8) then {
            _bases pushBack createHashMapFromArray [
                ["key", _key], ["town", toArray (_h select 4)], ["grid", mapGridPosition (_h select 0)],
                ["pos", _h select 0], ["name", ALSPMC_names getOrDefault [_y select 0, []]],
                ["price", _y select 2], ["locked", _key in ALS_locked],
                ["canSell", _owner == _uid || {(_co getOrDefault ["founder", ""]) == _uid}],
                ["nativeAccess", [_uid, _owner] call ALS_fnc_canUse],
                ["near", (_unit distance2D (_h select 0)) <= 40]
            ];
        };
    };
} forEach ALSPMC_bases;
private _hasOwnBase = ((keys ALSPMC_bases) findIf {((ALSPMC_bases get _x) select 0) == _founder}) >= 0;
private _nearby = [];
if (!_hasOwnBase && {_founder == _uid}) then {
    {
        private _h = ALS_houses get _x;
        private _distance = _unit distance2D (_h select 0);
        if (_distance <= 40 && {!(_x in ALS_owned)} && {!(_x in (missionNamespace getVariable ["ALS_reserved", []]))} && {(_h select 7) != "Wrecked"}) then {
            _nearby pushBack createHashMapFromArray [
                ["key", _x], ["town", toArray (_h select 4)], ["grid", mapGridPosition (_h select 0)],
                ["area", round (_h select 2)], ["distance", round _distance]
            ];
        };
    } forEach (missionNamespace getVariable ["ALSPMC_industrialKeys", []]);
};
private _clerkNear = ((missionNamespace getVariable ["ALS_npcPublic", []]) findIf {
    (_x select 1) == "clerk" && {_unit distance2D (_x select 0) <= 15}
}) >= 0;
private _price = (ALS_licenses get "alspmc_pmc") select 1;
// Periodic status updates must not overwrite an action acknowledgement before
// the owning client has observed it (server replies can arrive between ticks).
if (_reply == 0) then {
    private _previous = _unit getVariable ["ALSPMC_phoneState", createHashMap];
    _reply = _previous getOrDefault ["reply", 0];
    _ok = _previous getOrDefault ["ok", true];
};
private _state = createHashMapFromArray [
    ["company", [_unit] call ALSPMC_fnc_companyState],
    ["licensed", _license], ["name", ALSPMC_names getOrDefault [_founder, []]],
    ["canRename", _founder == _uid && {_license} && {missionNamespace getVariable ["ALSPMC_namesReady", false]}],
    ["licensePrice", _price], ["clerkNear", _clerkNear], ["bases", _bases],
    ["hasOwnBase", _hasOwnBase], ["nearby", _nearby select [0, 8]],
    ["basePrice", (round getNumber (configFile >> "ALSPMC_Settings" >> "basePrice")) max 1],
    ["reply", _reply], ["ok", _ok]
];
_state set ["quests", [_unit] call ALSPMC_fnc_questState];
// Server copy for the next reply/desktop merge; the owner gets its own copy.
_unit setVariable ["ALSPMC_phoneState", _state];
["ALSPMC_phoneState", _state] remoteExecCall ["ALSPMC_fnc_stateSet", _unit];

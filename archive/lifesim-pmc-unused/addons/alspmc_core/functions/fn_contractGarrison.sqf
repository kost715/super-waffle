// Native ownership/supply/commander state remains unchanged. Only the selected
// base's temporary guards are replaced; normal generation resumes on release.
params ["_action", "_job"];
private _plan = _job get "alspmcPlan";
private _id = _plan get "source";
private _qid = _job get "alspmcQuestId";
private _leases = missionNamespace getVariable ["ALSPMC_garrisonLeases", createHashMap];
if (_action == "release") exitWith {
    if ((_leases getOrDefault [_id, -1]) == _qid) then {
        _leases deleteAt _id;
        private _gar = (missionNamespace getVariable ["ALS_warGar", createHashMap]) getOrDefault [_id, createHashMap];
        private _flag = _gar getOrDefault ["flag", objNull];
        if (!isNull _flag) then {deleteVehicle _flag};
        // Military/Opfor bases have no player-owned depot crate. Preserve any
        // unexpected crate rather than deleting player inventory.
        if (!isNil "ALS_warGar") then {ALS_warGar deleteAt _id};
    };
    ALSPMC_garrisonLeases = _leases;
    true
};
if (_id in _leases) exitWith {(_leases get _id) == _qid};
private _owner = ((missionNamespace getVariable ["ALS_war", createHashMap]) getOrDefault ["own", createHashMap]) getOrDefault [_id, "Military"];
if !(_owner in ["Military", "Opfor"]) exitWith {false};
if (_owner != (_plan getOrDefault ["owner", _owner])) exitWith {false};
private _gar = (missionNamespace getVariable ["ALS_warGar", createHashMap]) getOrDefault [_id, createHashMap];
private _group = _gar getOrDefault ["grp", grpNull];
private _guards = if (isNull _group) then {[]} else {units _group};
if ((_guards findIf {isPlayer _x}) >= 0) exitWith {false};
_leases set [_id, _qid]; ALSPMC_garrisonLeases = _leases;
_job set ["alspmcBaseLeased", true];
{if (!isNull _x) then {deleteVehicle _x}} forEach _guards;
if (!isNull _group) then {deleteGroup _group};
_job set ["alspmcRole", _owner];
private _profile = +(_job get "alspmcProfile");
private _level = _profile get "level";
_profile set ["min", [15,20] select (_level >= 5)];
_profile set ["max", [20,25] select (_level >= 5)];
_job set ["alspmcProfile", _profile];
private _ok = [_job, _job get "alspmcSite"] call ALSPMC_fnc_contractAttack;
if (!_ok) then {["release", _job] call ALSPMC_fnc_contractGarrison};
_ok

// Read native registries only; never reserve/reclassify/sell a service building.
// Each site: [position, sourceID, buildingObject, indoorPosition, ownershipID].
params ["_kind", ["_unit", objNull]];
private _filter = {
    params ["_sites"];
    _sites = _sites select {[_kind, _x] call ALSPMC_fnc_contractSiteAvailable};
    if (isNull _unit) exitWith {_sites};
    private _base = [_unit] call ALSPMC_fnc_contractBase;
    _sites select {[_base, _x select 0, 100] call ALSPMC_fnc_contractFar}
};
private _out = [];
private _cache = missionNamespace getVariable ["ALSPMC_contractSitesCache", createHashMap];
private _cached = _cache getOrDefault [_kind, []];
if (_cached isNotEqualTo [] && {diag_tickTime - (_cached select 0) < 30}) exitWith {[+(_cached select 1)] call _filter};
private _war = missionNamespace getVariable ["ALS_war", createHashMap];
private _owners = _war getOrDefault ["own", createHashMap];
if (_kind in ["army", "enemyBase", "assaultBase"]) exitWith {
    {
        _x params ["_id", "_pos", "_type"];
        private _who = _owners getOrDefault [_id, "Military"];
        if ((_kind == "army" && {_who == "Military"} && {_type == "outpost"}) || {
            _kind == "enemyBase" && {_who == "Opfor"} && {_war getOrDefault ["on", false]}
        } || {
            _kind == "assaultBase" && {_who in ["Military", "Opfor"]} && {
                !(_id in (missionNamespace getVariable ["ALSPMC_garrisonLeases", createHashMap]))
            }
        }) then {_out pushBack [_pos, _id, objNull, [], _who]};
    } forEach (_war getOrDefault ["bases", []]);
    _cache set [_kind, [diag_tickTime, _out]]; ALSPMC_contractSitesCache = _cache;
    [_out] call _filter
};
if (_kind == "government") then {
    private _centers = [];
    {if ((_x select 1) in ["clerk", "police"]) then {_centers pushBack (_x select 0)}} forEach (missionNamespace getVariable ["ALS_npcPublic", []]);
    { _centers pushBack (_x select 1) } forEach (missionNamespace getVariable ["ALS_stations", []]);
    private _buildings = (missionNamespace getVariable ["ALS_map", createHashMap]) getOrDefault ["buildings", createHashMap];
    // LifeSim 0.13.0 classifies police stations, and hospitals/clinics as
    // "medical" (fn_classifyBuilding); town halls are found through their clerks.
    {{_centers pushBack (ASLToATL (_x select 0))} forEach (_buildings getOrDefault [_x, []])} forEach ["police", "medical"];
    {
        private _objects = nearestObjects [_x, ["House", "Building"], 90];
        {
            private _building = _x;
            private _floor = [_building] call ALS_fnc_houseFloor;
            // Never a player's property or a commercial venue: try the next building.
            if (_floor isNotEqualTo [] && {["government", [[], "", _building]] call ALSPMC_fnc_contractSiteAvailable}) exitWith {
                if ((_out findIf {(_x select 2) isEqualTo _building}) < 0) then {
                    _out pushBack [getPosATL _building, str getPosATL _building, _building, _floor select 0, ""];
                };
            };
        } forEach (_objects select [0, 5]);
    } forEach _centers;
};
if (_kind == "commercial") then {
    // Vacant commercial buildings only: not bought by a player or company and
    // not reserved by LifeSim (cafes, clinics, rival HQs and similar venues).
    private _reserved = missionNamespace getVariable ["ALS_reserved", []];
    {
        private _h = _y;
        if (count _h >= 8 && {(_h select 6) in ["Shop", "Industrial"]} && {(_h select 7) != "Wrecked"} && {
            !(_x in ALS_owned)
        } && {!(_x in _reserved)}) then {
            // Resolve physical objects only when planning this accepted job.
            _out pushBack [ASLToATL (_h select 0), _x, objNull, [], ""];
        };
    } forEach ALS_houses;
};
_cache set [_kind, [diag_tickTime, _out]]; ALSPMC_contractSitesCache = _cache;
[_out] call _filter

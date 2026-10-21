if (!isServer || {missionNamespace getVariable ["ALSPMC_contractsStarted", false]}) exitWith {};
ALSPMC_contractsStarted = true;
ALSPMC_contractsReady = false;
ALSPMC_contractMeta = createHashMap;
ALSPMC_ratingXP = createHashMap;
ALSPMC_contractBoards = createHashMap;
ALSPMC_garrisonLeases = createHashMap;
ALSPMC_hostileContracts = createHashMap;
ALSPMC_hostileRelations = createHashMap;
[["alspmc_contracts_v1"]] call ALS_fnc_dbLoading;
private _saved = ["alspmc_contracts_v1", [1, [], []]] call ALS_fnc_dbGet;
private _valid = _saved isEqualType [] && {count _saved == 3} && {(_saved select 0) isEqualTo 1} && {
    (_saved select 1) isEqualType [] && {(_saved select 2) isEqualType []}
};
if (_valid) then {
    private _types = (call ALSPMC_fnc_contractCatalog) apply {_x select 0};
    {
        private _good = _x isEqualType [] && {count _x == 2};
        if (_good) then {
            _x params ["_id", "_meta"];
            _good = _id isEqualType 0 && {_id > 0 && {_id == floor _id} && {_id <= ALSPMC_questSequence}} && {
                !(_id in ALSPMC_contractMeta)
            } && {_meta isEqualType [] && {count _meta == 4}};
            if (_good) then {
                _good = (_meta select 0) in _types && {(_meta select 1) in [1,2,3,4,5]} && {
                    (_meta select 2) isEqualType 0 && {(_meta select 2) >= 0 && {(_meta select 2) <= 10000}}
                } && {(_meta select 3) isEqualType 0 && {(_meta select 3) >= 0 && {(_meta select 3) <= 1000000}}};
            };
            if (_good) then {ALSPMC_contractMeta set [_id, +_meta]};
        };
        if (!_good) then {_valid = false};
    } forEach (_saved select 1);
    {
        private _good = _x isEqualType [] && {count _x == 2};
        if (_good) then {
            _x params ["_uid", "_xp"];
            _good = _uid isEqualType "" && {_uid != ""} && {!(_uid in ALSPMC_ratingXP)} && {
                _xp isEqualType 0 && {_xp >= 0 && {_xp == floor _xp} && {_xp <= 100000000}}
            };
            if (_good) then {ALSPMC_ratingXP set [_uid, _xp]};
        };
        if (!_good) then {_valid = false};
    } forEach (_saved select 2);
};
if (!_valid) exitWith {
    ALSPMC_contractMeta = createHashMap; ALSPMC_ratingXP = createHashMap;
    ["ALSPMC: rating/contract metadata invalid; original key preserved, new contracts disabled"] call ALS_fnc_log;
};
[["alspmc_contracts_v1"], true] call ALS_fnc_dbLoading;
ALS_fnc_coopJob_alspmc_contract = {_this call ALSPMC_fnc_contractScenario};
// Only our new owner-paid contracts are settled here. Ordinary native jobs
// and the previous single-target test delegate to the captured original.
if (isNil "ALSPMC_nativeCoopEnd") then {
    ALSPMC_nativeCoopEnd = ALS_fnc_coopEnd;
    ALS_fnc_coopEnd = {_this call ALSPMC_fnc_contractEnd};
};
if (isNil "ALSPMC_nativeWarBases" && {!(isNil "ALS_fnc_warBases")}) then {
    ALSPMC_nativeWarBases = ALS_fnc_warBases;
    ALS_fnc_warBases = {_this call ALSPMC_fnc_contractWarBases};
};
ALSPMC_contractsReady = true;
call ALSPMC_fnc_contractSave;

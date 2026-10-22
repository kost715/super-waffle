if (!isServer || {missionNamespace getVariable ["ALSPMC_serverStarted", false]}) exitWith {};
ALSPMC_serverStarted = true;
ALSPMC_ready = false;
publicVariable "ALSPMC_ready";
ALSPMC_bases = createHashMap;
[["alspmc_bases_v1"]] call ALS_fnc_dbLoading;
private _saved = ["alspmc_bases_v1", []] call ALS_fnc_dbGet;
private _valid = _saved isEqualType [];
if (_valid) then {
    {
        private _good = _x isEqualType [] && {count _x == 2};
        if (_good) then {
            _x params ["_key", "_record"];
            _good = _key isEqualType "" && {_record isEqualType []} && {count _record == 3};
            if (_good) then {
                _record params ["_founder", "_marketValue", "_paid"];
                _good = _founder isEqualType "" && {_founder != ""} && {
                    _marketValue isEqualType 0 && {_marketValue >= 0}
                } && {_paid isEqualType 0 && {_paid > 0}};
            };
            if (_good) then {ALSPMC_bases set [_key, +_record]};
        };
        if (!_good) then {_valid = false};
    } forEach _saved;
};
if (!_valid) exitWith {
    ALSPMC_bases = createHashMap;
    ["ALSPMC: base data invalid; original save preserved, purchases disabled"] call ALS_fnc_log;
};
[["alspmc_bases_v1"], true] call ALS_fnc_dbLoading;

// New optional key: old alpha-1 saves need no migration or second purchase.
ALSPMC_names = createHashMap;
ALSPMC_namesReady = false;
[["alspmc_names_v1"]] call ALS_fnc_dbLoading;
private _names = ["alspmc_names_v1", []] call ALS_fnc_dbGet;
private _namesValid = _names isEqualType [];
if (_namesValid) then {
    {
        private _good = _x isEqualType [] && {count _x == 2};
        if (_good) then {
            _x params ["_who", "_bytes"];
            _good = _who isEqualType "" && {_who != ""} && {_bytes isEqualType []} && {
                ([_bytes] call ALSPMC_fnc_normalizeName) isEqualTo _bytes && {_bytes isNotEqualTo []}
            };
            if (_good) then {ALSPMC_names set [_who, +_bytes]};
        };
        if (!_good) then {_namesValid = false};
    } forEach _names;
};
if (_namesValid) then {
    [["alspmc_names_v1"], true] call ALS_fnc_dbLoading;
    ALSPMC_namesReady = true;
} else {
    ALSPMC_names = createHashMap;
    ["ALSPMC: name data invalid; original name data preserved, renaming disabled"] call ALS_fnc_log;
};
private _types = getArray (configFile >> "ALSPMC_Settings" >> "allowedTypes");
ALSPMC_industrialKeys = (keys ALS_houses) select {((ALS_houses get _x) param [6, "Home"]) in _types};

// Compose with the original function; ordinary property sales stay native.
ALSPMC_nativeHouseSell = ALS_fnc_houseSell;
ALS_fnc_houseSell = {_this call ALSPMC_fnc_sellHouse};
// Same composition for a new career: PMC records go before the original runs.
if (isNil "ALSPMC_nativeCareerRestart") then {
    ALSPMC_nativeCareerRestart = ALS_fnc_careerRestart;
    ALS_fnc_careerRestart = {_this call ALSPMC_fnc_careerRestart};
};
call ALSPMC_fnc_reconcile;
call ALSPMC_fnc_save;
call ALSPMC_fnc_terminalInit;
call ALSPMC_fnc_questInit;
call ALSPMC_fnc_companyInit;
[{call ALSPMC_fnc_companyTick}, 2] call CBA_fnc_addPerFrameHandler;
ALSPMC_ready = true;
publicVariable "ALSPMC_ready";
[{call ALSPMC_fnc_reconcile}, 2] call CBA_fnc_addPerFrameHandler;

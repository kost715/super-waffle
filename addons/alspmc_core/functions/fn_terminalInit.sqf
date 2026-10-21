if (!isServer) exitWith {};
ALSPMC_workstationsReady = false;
ALSPMC_terminals = createHashMap;
ALSPMC_workstations = createHashMap;
ALSPMC_terminalRetry = createHashMap;
[["alspmc_workstations_v1"]] call ALS_fnc_dbLoading;
private _saved = ["alspmc_workstations_v1", []] call ALS_fnc_dbGet;
private _valid = _saved isEqualType [];
if (_valid) then {
    {
        private _good = _x isEqualType [] && {count _x == 2};
        if (_good) then {
            _x params ["_key", "_layout"];
            _good = _key isEqualType "" && {_layout isEqualType []} && {count _layout == 2};
            if (_good) then {
                _layout params ["_pos", "_dir"];
                _good = _pos isEqualType [] && {count _pos == 3} && {
                    (_pos findIf {!(_x isEqualType 0) || {abs _x > 1000000}}) < 0
                } && {_dir isEqualType 0 && {abs _dir <= 1000000}};
            };
            if (_good) then {ALSPMC_workstations set [_key, _layout]};
        };
        if (!_good) then {_valid = false};
    } forEach _saved;
};
if (!_valid) exitWith {
    ["ALSPMC: workstation layout invalid; original layout data preserved"] call ALS_fnc_log;
};
[["alspmc_workstations_v1"], true] call ALS_fnc_dbLoading;
ALSPMC_workstationsReady = true;
call ALSPMC_fnc_terminalSync;
// Commit migration of an existing base immediately, using LifeSim's save path.
if (count ALSPMC_workstations > 0) then {call ALS_fnc_dbSave};

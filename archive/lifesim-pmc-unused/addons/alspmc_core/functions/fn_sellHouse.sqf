// Keep LifeSim's own permission checks, storage transfer and payment rules.
if (!isServer) exitWith {false};
private _key = _this param [1, ""];
if !(_key in ALSPMC_bases) exitWith {_this call ALSPMC_nativeHouseSell};
private _result = false;
isNil {
    _result = _this call ALSPMC_nativeHouseSell;
    if (_result) then {
        private _record = ALSPMC_bases get _key;
        if (_key in ALS_houses) then {(ALS_houses get _key) set [5, _record select 1]};
        ALSPMC_bases deleteAt _key;
        [_key] call ALSPMC_fnc_terminalRemove;
        call ALSPMC_fnc_save;
        call ALS_fnc_dbSave;
    };
};
_result

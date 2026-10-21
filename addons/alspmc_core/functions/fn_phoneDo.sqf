params [["_unit", objNull, [objNull]], ["_op", "", [""]], ["_arg", ""], ["_token", 0, [0]]];
if !([_unit] call ALSPMC_fnc_requestAllowed) exitWith {false};
if (_token < 0 || {_token > 1000000000} || {_token != floor _token}) exitWith {false};
private _ok = switch (_op) do {
    case "status": {true};
    case "license": {
        private _bought = [_unit, "alspmc_pmc"] call ALS_fnc_licBuy;
        if (_bought) then {
            call ALS_fnc_dbSave;
            ["STR_ALSPMC_license_bought"] remoteExecCall ["ALSPMC_fnc_message", _unit];
        };
        _bought
    };
    case "name": {[_unit, _arg] call ALSPMC_fnc_setName};
    case "base": {[_unit, _arg] call ALSPMC_fnc_buyBase};
    case "questStart";
    case "questReady";
    case "questCancel": {[_unit, _op, _arg, _token] call ALSPMC_fnc_questDo};
    case "lock";
    case "unlock";
    case "sell": {
        private _uid = [_unit] call ALS_fnc_uid;
        if (!(_arg isEqualType "") || {!(_arg in ALSPMC_bases)} || {
            !([_uid, ALS_owned getOrDefault [_arg, ""]] call ALS_fnc_canUse)
        }) exitWith {false};
        // A sale commits the DB in ALSPMC_fnc_sellHouse. Doors are saved by
        // LifeSim's own periodic save, like the native door action.
        if (_op == "sell") then {
            [_unit, _arg] call ALS_fnc_houseSell
        } else {[_unit, _arg, _op == "lock"] call ALS_fnc_houseLock}
    };
    default {false};
};
[_unit, _token, _ok] call ALSPMC_fnc_phoneSync;
_ok

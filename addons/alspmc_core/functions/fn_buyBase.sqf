params [["_unit", objNull, [objNull]], ["_key", "", [""]]];
if !([_unit] call ALSPMC_fnc_requestAllowed) exitWith {false};
private _result = false;
// All checks, payment and ownership change run without scheduler preemption.
isNil {
    _result = call {
        call ALSPMC_fnc_reconcile;
        private _uid = [_unit] call ALS_fnc_uid;
        private _say = {
            params ["_id", ["_args", []]];
            [_id, _args] remoteExecCall ["ALSPMC_fnc_message", _unit];
            false
        };
        // A forged native licence is not an establishment permit.
        if !("alspmc_pmc" in (["lic_" + _uid, []] call ALS_fnc_dbGet)) exitWith {
            ["STR_ALSPMC_need_license"] call _say
        };
        private _h = ALS_houses getOrDefault [_key, []];
        if (count _h < 8) exitWith {["STR_ALSPMC_invalid_property"] call _say};
        if !((_h select 6) in getArray (configFile >> "ALSPMC_Settings" >> "allowedTypes")) exitWith {
            ["STR_ALSPMC_invalid_property"] call _say
        };
        if ((_h select 7) == "Wrecked") exitWith {["STR_ALSPMC_invalid_property"] call _say};
        if (_unit distance2D (_h select 0) > 40) exitWith {["STR_ALSPMC_too_far"] call _say};
        if (_key in (missionNamespace getVariable ["ALS_reserved", []])) exitWith {
            ["STR_ALSPMC_reserved"] call _say
        };
        if (_key in ALS_owned) exitWith {["STR_ALSPMC_owned"] call _say};
        if (((keys ALSPMC_bases) findIf {
            ((ALSPMC_bases get _x) select 0) == _uid && {_x in ALS_owned}
        }) >= 0) exitWith {["STR_ALSPMC_already_base"] call _say};

        private _price = (round getNumber (configFile >> "ALSPMC_Settings" >> "basePrice")) max 1;
        private _bank = ([_uid] call ALS_fnc_moneyGet) select 1;
        if !([_uid, _price] call ALS_fnc_moneyPay) exitWith {
            ["STR_ALSPMC_not_enough", [_price]] call _say
        };
        if !([_key, _uid] call ALS_fnc_houseClaim) exitWith {
            // Restore exactly the bank/cash split used by native moneyPay.
            private _fromBank = _price min _bank;
            [_uid, _price - _fromBank, _fromBank] call ALS_fnc_moneyAdd;
            ["STR_ALSPMC_owned"] call _say
        };
        ALSPMC_bases set [_key, [_uid, _h select 5, _price]];
        // The property remains a native warehouse, with native storage/doors.
        [_key] call ALS_fnc_bizGet;
        call ALSPMC_fnc_save;
        call ALS_fnc_bizPublish;
        [_key] call ALSPMC_fnc_terminalEnsure;
        call ALS_fnc_dbSave;
        ["STR_ALSPMC_bought", [_price, _h select 4]] call _say;
        true
    };
};
_result

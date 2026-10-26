params [["_unit", objNull, [objNull]], ["_op", "", [""]], ["_arg", ""], ["_token", 0, [0]], ["_computer", objNull, [objNull]]];
if !([_unit] call ALSPMC_fnc_requestAllowed) exitWith {false};
private _key = _computer getVariable ["ALSPMC_terminalKey", ""];
if !([_unit, _computer] call ALSPMC_fnc_terminalCanUse) exitWith {
    ["ALSPMC_desktopState", createHashMapFromArray [["valid", false], ["terminalKey", _key]]] remoteExecCall ["ALSPMC_fnc_stateSet", _unit];
    false
};
// One implementation for both interfaces: no second wallet, PMC, or copy of
// purchase/name/door logic. The PC adds only physical terminal authorization.
if (_token < 0 || {_token > 1000000000} || {_token != floor _token}) exitWith {false};
private _ok = false;
if ((_op select [0,7]) == "company") then {
    _ok = [_unit, _op, _arg, _computer] call ALSPMC_fnc_companyDo;
    [_unit, _token, _ok] call ALSPMC_fnc_phoneSync;
} else {_ok = [_unit, _op, _arg, _token] call ALSPMC_fnc_phoneDo};
private _state = +(_unit getVariable ["ALSPMC_phoneState", createHashMap]);
_state set ["company", [_unit, true] call ALSPMC_fnc_companyState];
_state set ["terminalKey", _key];
_state set ["valid", [_unit, _computer] call ALSPMC_fnc_terminalCanUse];
["ALSPMC_desktopState", _state] remoteExecCall ["ALSPMC_fnc_stateSet", _unit];
_ok

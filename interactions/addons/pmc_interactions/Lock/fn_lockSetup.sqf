#include "..\ui_defines.hpp"
// [mode, value] -> nothing. Client (Zeus): the lock window of the Zeus module. Lock type
// (classic, code, safe, or none to open the box), difficulty, and the key that fits a
// classic lock (one of the five set in CBA, or none) or the 4-6 digit code of a code
// lock or safe. "Done" sends it to the server (PMCI_fnc_lockSet).
params ["_mode", ["_value", 0]];
private _display = uiNamespace getVariable ["PMCI_lockDisplay", displayNull];
private _types = ["classic", "code", "safe", "none"];
switch (_mode) do {
    case "onLoad": {
        uiNamespace setVariable ["PMCI_lockDisplay", _value];
        _display = _value;
        private _box = PMCI_lockSetup get "box";
        (_display displayCtrl PMCI_IDC_LOCK_TITLE) ctrlSetText format [localize "STR_PMCI_LOCK_TITLE", getText (configOf _box >> "displayName")];
        (_box getVariable ["PMCI_lock", []]) params [["_type", "classic"], ["_level", 1], ["_key", ""]];
        private _typeList = _display displayCtrl PMCI_IDC_LOCK_TYPE;
        {_typeList lbAdd localize ("STR_PMCI_LOCK_TYPE_" + _x)} forEach _types;
        _typeList lbSetCurSel (0 max (_types find _type));
        private _levels = _display displayCtrl PMCI_IDC_LOCK_LEVEL;
        {_levels lbAdd localize _x} forEach ["STR_PMCI_EASY", "STR_PMCI_NORMAL", "STR_PMCI_HARD"];
        _levels lbSetCurSel _level;
        private _keyList = _display displayCtrl PMCI_IDC_LOCK_KEY;
        _keyList lbSetData [_keyList lbAdd localize "STR_PMCI_LOCK_NO_KEY_FITS", ""];
        {
            if (_x != "") then {
                private _row = _keyList lbAdd format ["%1: %2", _forEachIndex + 1, [_x] call PMCI_fnc_itemName];
                _keyList lbSetData [_row, _x];
                _keyList lbSetTooltip [_row, _x];
                if (toLower _x == toLower _key) then {_keyList lbSetCurSel _row};
            };
        } forEach (call PMCI_fnc_lockKeys);
        // A new lock takes the first key; a lock without a key keeps none.
        if (lbCurSel _keyList < 0) then {_keyList lbSetCurSel ([0, 1] select (lbSize _keyList > 1 && {(_box getVariable ["PMCI_lock", []]) isEqualTo []}))};
        if (lbSize _keyList == 1) then {(_display displayCtrl PMCI_IDC_LOCK_STATUS) ctrlSetText localize "STR_PMCI_LOCK_NO_KEYS_SET"};
        ["type"] call PMCI_fnc_lockSetup;
    };
    case "onUnload": {
        uiNamespace setVariable ["PMCI_lockDisplay", displayNull];
        PMCI_lockSetup = nil;
    };
    case "type": {
        private _type = _types param [lbCurSel (_display displayCtrl PMCI_IDC_LOCK_TYPE), "classic"];
        (_display displayCtrl PMCI_IDC_LOCK_KEY) ctrlEnable (_type == "classic");
        (_display displayCtrl PMCI_IDC_LOCK_LEVEL) ctrlEnable (_type != "none");
        {(_display displayCtrl _x) ctrlEnable (_type in ["code", "safe"])} forEach [PMCI_IDC_LOCK_CODE, PMCI_IDC_LOCK_RANDOM];
    };
    case "random": {
        private _code = "";
        for "_k" from 1 to (4 + floor random 3) do {_code = _code + str (floor random 10)};
        (_display displayCtrl PMCI_IDC_LOCK_CODE) ctrlSetText _code;
    };
    case "done": {
        private _type = _types param [lbCurSel (_display displayCtrl PMCI_IDC_LOCK_TYPE), "classic"];
        private _keyList = _display displayCtrl PMCI_IDC_LOCK_KEY;
        private _key = if (lbCurSel _keyList < 0) then {""} else {_keyList lbData (lbCurSel _keyList)};
        private _code = ctrlText (_display displayCtrl PMCI_IDC_LOCK_CODE);
        if (_type in ["code", "safe"] && {!([_code] call PMCI_fnc_codeValid)}) exitWith {
            (_display displayCtrl PMCI_IDC_LOCK_STATUS) ctrlSetText localize "STR_PMCI_LOCK_ERR_CODE";
        };
        [player, PMCI_lockSetup get "box", _type, 0 max lbCurSel (_display displayCtrl PMCI_IDC_LOCK_LEVEL), _key, _code] remoteExecCall ["PMCI_fnc_lockSet", 2];
        closeDialog 1;
    };
};

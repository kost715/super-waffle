#include "..\ui_defines.hpp"
// [mode, value] -> nothing. Client: the keypad of a code lock or safe. "open" [box] opens
// it; digits come from the keyboard or the buttons; "enter" sends the code to the server
// (PMCI_fnc_lockOpen), which opens the box or says the code is wrong.
params ["_mode", ["_value", 0]];
private _display = uiNamespace getVariable ["PMCI_keypadDisplay", displayNull];
private _field = _display displayCtrl PMCI_IDC_KEYPAD_CODE;
switch (_mode) do {
    case "open": {
        PMCI_keypad = _value;
        createDialog "PMCI_RscLockKeypad";
    };
    case "onLoad": {
        uiNamespace setVariable ["PMCI_keypadDisplay", _value];
        ctrlSetFocus (_value displayCtrl PMCI_IDC_KEYPAD_CODE);
    };
    case "onUnload": {
        uiNamespace setVariable ["PMCI_keypadDisplay", displayNull];
        PMCI_keypad = nil;
    };
    case "digit": {
        if (count ctrlText _field < 6) then {_field ctrlSetText (ctrlText _field + str _value)};
    };
    case "back": {
        private _text = ctrlText _field;
        _field ctrlSetText (_text select [0, 0 max (count _text - 1)]);
    };
    case "clear": {_field ctrlSetText ""};
    case "enter": {
        private _code = (toArray ctrlText _field) select {_x >= 48 && {_x <= 57}};
        [player, PMCI_keypad, "code", toString _code] remoteExecCall ["PMCI_fnc_lockOpen", 2];
        closeDialog 1;
    };
};

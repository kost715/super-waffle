#include "..\ui_defines.hpp"
// [mode, value] -> nothing. Client (Zeus): the muscle damage window. The value stays
// hidden until "Check" asks the player's machine for it (PMCD_fnc_muscleCheck, answered
// to PMCD_fnc_muscleShow); "Set" sends a value 0-1 to the player's machine
// (PMCD_fnc_muscleSet). Always one unit, never anything automatic.
params ["_mode", ["_value", 0]];
private _display = uiNamespace getVariable ["PMCD_muscleDisplay", displayNull];
switch (_mode) do {
    case "onLoad": {
        uiNamespace setVariable ["PMCD_muscleDisplay", _value];
        (_value displayCtrl PMCD_IDC_TITLE) ctrlSetText format [localize "STR_PMCD_MUSCLE_TITLE", name PMCD_muscleTarget];
        (_value displayCtrl PMCD_IDC_VALUE) ctrlSetText localize "STR_PMCD_MUSCLE_HIDDEN";
    };
    case "onUnload": {
        uiNamespace setVariable ["PMCD_muscleDisplay", displayNull];
        PMCD_muscleTarget = nil;
    };
    case "check": {
        ["PMCD_muscleCheck", [player, PMCD_muscleTarget], PMCD_muscleTarget] call CBA_fnc_targetEvent;
    };
    case "set": {
        private _text = ctrlText (_display displayCtrl PMCD_IDC_EDIT);
        private _number = parseNumber ((_text splitString ",") joinString ".");
        ["PMCD_muscleSet", [player, PMCD_muscleTarget, 0 max (_number min 1)], PMCD_muscleTarget] call CBA_fnc_targetEvent;
    };
};

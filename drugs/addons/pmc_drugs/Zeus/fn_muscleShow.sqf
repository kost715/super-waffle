#include "..\ui_defines.hpp"
// [unit, value] -> nothing. Zeus: the answer of the unit's machine, shown in the open
// window if it is still about that unit.
params ["_unit", "_value"];
private _display = uiNamespace getVariable ["PMCD_muscleDisplay", displayNull];
if (isNull _display || {isNil "PMCD_muscleTarget"} || {!(_unit isEqualTo PMCD_muscleTarget)}) exitWith {};
(_display displayCtrl PMCD_IDC_VALUE) ctrlSetText format [localize "STR_PMCD_MUSCLE_VALUE", _value toFixed 2];

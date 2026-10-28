// [unit, object] -> true when the object is a registered ATM within 5 m of the unit.
params [["_unit", objNull, [objNull]], ["_atm", objNull, [objNull]]];
!isNull _atm && {_atm getVariable ["PMCB_atm", false]} && {_unit distance _atm <= 5}

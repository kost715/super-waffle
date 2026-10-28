// [unit] -> true when the unit's player is a Zeus (has a curator assigned).
params [["_unit", objNull, [objNull]]];
!isNull _unit && {!isNull getAssignedCuratorLogic _unit}

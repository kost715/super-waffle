// [object, mode] -> nothing. Every machine with a player: the laptop's action. The
// market management laptop offers it only to a Zeus (the server checks again).
params [["_object", objNull, [objNull]], ["_mode", "shop", [""]]];
if (!hasInterface || {isNull _object}) exitWith {};
private _old = _object getVariable ["PMCS_action", -1];
if (_old >= 0) then {_object removeAction _old};
private _condition = format ["_this distance _target <= %1%2", missionNamespace getVariable ["PMCS_useDistance", 4],
    ["", " && {!isNull getAssignedCuratorLogic _this}"] select (_mode == "admin")];
private _id = _object addAction [localize (["STR_PMCS_ACTION_SHOP", "STR_PMCS_ACTION_ADMIN"] select (_mode == "admin")),
    {[_this select 0] call PMCS_fnc_open}, nil, 6, true, true, "", _condition, (missionNamespace getVariable ["PMCS_useDistance", 4]) + 1];
_object setVariable ["PMCS_action", _id];

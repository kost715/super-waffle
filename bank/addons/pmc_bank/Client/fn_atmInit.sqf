// [object, enable] -> nothing. Server -> every client (JIP included): adds or
// removes the "ATM" action on an object.
params [["_object", objNull, [objNull]], ["_enable", true, [true]]];
if (!hasInterface || {isNull _object}) exitWith {};
private _id = _object getVariable ["PMCB_actionId", -1];
if (_id >= 0) then {
    _object removeAction _id;
    _object setVariable ["PMCB_actionId", -1];
};
if (_enable) then {
    _id = _object addAction [localize "STR_PMCB_ACT_ATM", {[_this select 0] call PMCB_fnc_open}, nil, 6, true, true, "",
        "alive _target && {_target distance _this < 4} && {isNull objectParent _this}"];
    _object setVariable ["PMCB_actionId", _id];
};

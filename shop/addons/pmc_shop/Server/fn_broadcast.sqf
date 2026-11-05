// [] -> nothing. Server. The market changed: every open laptop gets it again.
{
    _y params ["_unit", "_mode"];
    if (isNull _unit) then {PMCS_viewers deleteAt _x} else {[_x, _unit, _mode] call PMCS_fnc_push};
} forEach +PMCS_viewers;

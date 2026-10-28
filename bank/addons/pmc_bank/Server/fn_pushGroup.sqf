// [except owner] -> nothing. Server. The group's account changed: refresh every
// open ATM screen except the one that already got its own update.
params [["_except", -1, [0]]];
{
    if (_x != _except) then {[_x, _y] call PMCB_fnc_push};
} forEach PMCB_viewers;

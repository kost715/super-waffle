// [token, slot, weapon class, new class, [low, medium, high parts]] -> nothing. Server ->
// the player's machine after the upgrade is paid: swaps the weapon in that slot for the new
// one, keeps its attachments and loaded magazines where the new weapon takes them (the rest
// go to the inventory, or to the ground when it is full), takes the parts from the
// inventory and tells the server (PMCS_fnc_upgradeDone). Nothing changes when the weapon or
// the parts are no longer there: the server then refunds the money.
params [["_token", "", [""]], ["_slot", 0, [0]], ["_from", "", [""]], ["_to", "", [""]], ["_parts", [0, 0, 0], [[]]]];
private _unit = player;
private _current = [primaryWeapon _unit, secondaryWeapon _unit, handgunWeapon _unit] select _slot;
private _items = items _unit;
private _enough = true;
{
    private _class = _x;
    if (({_x == _class} count _items) < (_parts param [_forEachIndex, 0])) then {_enough = false};
} forEach (call PMCS_fnc_parts);
if (_current != _from || {!_enough} || {!alive _unit}) exitWith {[_unit, _token, false] remoteExecCall ["PMCS_fnc_upgradeDone", 2]};
// What the weapon carries: attachments (strings) and magazines ([class, rounds, ...]).
private _entry = (weaponsItems _unit) select {(_x select 0) == _from};
private _carried = [];
if (_entry isNotEqualTo []) then {
    {
        if (_x isEqualType "" && {_x != ""}) then {_carried pushBack _x};
        if (_x isEqualType [] && {count _x >= 2} && {(_x select 0) isEqualType ""} && {(_x select 0) != ""}) then {_carried pushBack [_x select 0, _x select 1]};
    } forEach ((_entry select 0) select [1, count (_entry select 0)]);
};
_unit removeWeapon _from;
_unit addWeapon _to;
if (([primaryWeapon _unit, secondaryWeapon _unit, handgunWeapon _unit] select _slot) != _to) exitWith {
    _unit addWeapon _from;
    [_unit, _token, false] remoteExecCall ["PMCS_fnc_upgradeDone", 2];
};
{_unit addWeaponItem [_to, _x, true]} forEach _carried;
// What the new weapon did not take goes back to the player.
private _kept = [];
{
    {
        if (_x isEqualType "" && {_x != ""}) then {_kept pushBack _x};
        if (_x isEqualType [] && {count _x >= 2} && {(_x select 0) isEqualType ""}) then {_kept pushBack (_x select 0)};
    } forEach (_x select [1, count _x]);
} forEach ((weaponsItems _unit) select {(_x select 0) == _to});
private _ground = objNull;
{
    private _class = if (_x isEqualType []) then {_x select 0} else {_x};
    private _at = _kept find _class;
    if (_at >= 0) then {_kept deleteAt _at} else {
        if (_unit canAdd _class) then {
            if (_x isEqualType []) then {_unit addMagazine _x} else {_unit addItem _class};
        } else {
            if (isNull _ground) then {_ground = createVehicle ["GroundWeaponHolder", getPosATL _unit, [], 0, "CAN_COLLIDE"]};
            if (_x isEqualType []) then {_ground addMagazineAmmoCargo [_class, 1, _x select 1]} else {_ground addItemCargoGlobal [_class, 1]};
        };
    };
} forEach _carried;
{
    private _class = _x;
    for "_i" from 1 to (_parts param [_forEachIndex, 0]) do {_unit removeItem _class};
} forEach (call PMCS_fnc_parts);
[_unit, _token, true] remoteExecCall ["PMCS_fnc_upgradeDone", 2];
if (!isNil "PMCS_ui") then {["refresh"] call PMCS_fnc_uiTech};

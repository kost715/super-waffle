// [token, vest class, new class, [[item class, count], ...]] -> nothing. Server -> the
// player's machine after a vest upgrade is accepted: puts on the new vest with everything
// the old one held, takes the items from the inventory and tells the server
// (PMCS_fnc_upgradeDone). Nothing changes when the vest or the items are no longer there:
// the server then refunds any money. An undo gives items back (to the inventory, or to the
// ground beside the player when it is full).
params [["_token", "", [""]], ["_from", "", [""]], ["_to", "", [""]], ["_take", [], [[]]], ["_give", [], [[]]]];
private _unit = player;
private _items = items _unit;
private _enough = (_take findIf {private _c = _x select 0; ({_x == _c} count _items) < (_x select 1)}) < 0;
if (vest _unit != _from || {!_enough} || {!alive _unit}) exitWith {[_unit, _token, false] remoteExecCall ["PMCS_fnc_upgradeDone", 2]};
// The loadout with the new vest and the old vest's contents.
private _before = getUnitLoadout _unit;
private _loadout = +_before;
private _vest = +(_loadout select 4);
_vest set [0, _to];
_loadout set [4, _vest];
_unit setUnitLoadout _loadout;
if (vest _unit != _to) exitWith {
    _unit setUnitLoadout _before;
    [_unit, _token, false] remoteExecCall ["PMCS_fnc_upgradeDone", 2];
};
{
    _x params ["_class", "_n"];
    for "_i" from 1 to _n do {_unit removeItem _class};
} forEach _take;
private _ground = objNull;
{
    _x params ["_class", "_n"];
    for "_i" from 1 to _n do {
        if (_unit canAdd _class) then {_unit addItem _class} else {
            if (isNull _ground) then {_ground = createVehicle ["GroundWeaponHolder", getPosATL _unit, [], 0, "CAN_COLLIDE"]};
            _ground addItemCargoGlobal [_class, 1];
        };
    };
} forEach _give;
[_unit, _token, true] remoteExecCall ["PMCS_fnc_upgradeDone", 2];
if (!isNil "PMCS_ui") then {["body"] call PMCS_fnc_uiTech};

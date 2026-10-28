// [[[class, count], ...]] -> nothing. Server -> client after a withdrawal: puts the
// banknotes into the inventory; what does not fit is left on the ground.
params [["_rows", [], [[]]]];
if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {};
private _spill = [];
{
    _x params ["_class", "_count"];
    private _magazine = isClass (configFile >> "CfgMagazines" >> _class);
    for "_i" from 1 to _count do {
        if (player canAdd _class) then {
            if (_magazine) then {player addMagazine _class} else {player addItem _class};
        } else {
            _spill pushBack [_class, _magazine];
        };
    };
} forEach _rows;
if (_spill isNotEqualTo []) then {
    private _holder = createVehicle ["GroundWeaponHolder", getPosATL player, [], 0, "CAN_COLLIDE"];
    {
        if (_x select 1) then {_holder addMagazineCargoGlobal [_x select 0, 1]} else {_holder addItemCargoGlobal [_x select 0, 1]};
    } forEach _spill;
    ["STR_PMCB_SPILLED", []] call PMCB_fnc_notify;
};

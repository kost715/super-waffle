// getUnitLoadout array -> hashmap canonical class -> amount (magazines in rounds).
// The loadout format lists every item exactly once, unlike items + assignedItems.
params [["_loadout", [], [[]]]];
private _out = createHashMap;
private _add = {
    params ["_class", "_amount"];
    if !(_class isEqualType "" && {_class != ""} && {_amount isEqualType 0} && {_amount > 0}) exitWith {};
    private _key = [_class] call PMCA_fnc_itemKey;
    if (_key != "") then {_out set [_key, (_out getOrDefault [_key, 0]) + _amount]};
};
// [weapon, muzzle, pointer, optic, [magazine, rounds], [magazine2, rounds], bipod]
private _weapon = {
    params ["_entry"];
    if !(_entry isEqualType []) exitWith {};
    {
        if (_x isEqualType "") then {[_x, 1] call _add} else {
            if (_x isEqualType [] && {count _x >= 2}) then {[_x select 0, _x select 1] call _add};
        };
    } forEach _entry;
};
// [item, count], [magazine, count, rounds] or [weaponArray, count]
private _contents = {
    params ["_list"];
    if !(_list isEqualType []) exitWith {};
    {
        if (_x isEqualType []) then {
            switch (count _x) do {
                case 3: {[_x select 0, (_x select 1) * (_x select 2)] call _add};
                case 2: {
                    if ((_x select 0) isEqualType []) then {
                        for "_i" from 1 to ((_x select 1) min 100) do {[_x select 0] call _weapon};
                    } else {[_x select 0, _x select 1] call _add};
                };
            };
        };
    } forEach _list;
};
_loadout params [["_primary", []], ["_secondary", []], ["_handgun", []], ["_uniform", []], ["_vest", []], ["_backpack", []],
    ["_headgear", ""], ["_goggles", ""], ["_binocular", []], ["_linked", []]];
{[_x] call _weapon} forEach [_primary, _secondary, _handgun, _binocular];
{
    if (_x isEqualType [] && {_x isNotEqualTo []}) then {[_x select 0, 1] call _add; [_x param [1, []]] call _contents};
} forEach [_uniform, _vest, _backpack];
{[_x, 1] call _add} forEach [_headgear, _goggles];
if (_linked isEqualType []) then {{[_x, 1] call _add} forEach _linked};
_out

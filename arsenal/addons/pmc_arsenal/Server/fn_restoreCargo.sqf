#include "..\defineCommon.inc"
// [container, hashmap class -> amount] -> nothing. Server. Puts a snapshot back
// into an emptied container: weapons without attachments, magazines by rounds.
params ["_container", "_items"];
if (isNull _container) exitWith {};
clearMagazineCargoGlobal _container;
clearItemCargoGlobal _container;
clearWeaponCargoGlobal _container;
clearBackpackCargoGlobal _container;
{
    private _class = _x;
    private _amount = _y;
    private _tab = _class call PMCA_fnc_arsenal_itemType;
    switch (true) do {
        case (_tab in [IDC_RSCDISPLAYARSENAL_TAB_PRIMARYWEAPON, IDC_RSCDISPLAYARSENAL_TAB_SECONDARYWEAPON,
            IDC_RSCDISPLAYARSENAL_TAB_HANDGUN, IDC_RSCDISPLAYARSENAL_TAB_BINOCULARS]): {_container addWeaponCargoGlobal [_class, _amount]};
        case (_tab == IDC_RSCDISPLAYARSENAL_TAB_BACKPACK): {_container addBackpackCargoGlobal [_class, _amount]};
        case (isClass (configFile >> "CfgMagazines" >> _class)): {
            private _full = (getNumber (configFile >> "CfgMagazines" >> _class >> "count")) max 1;
            while {_amount > 0} do {
                _container addMagazineAmmoCargo [_class, 1, _amount min _full];
                _amount = _amount - _full;
            };
        };
        default {_container addItemCargoGlobal [_class, _amount]};
    };
} forEach _items;

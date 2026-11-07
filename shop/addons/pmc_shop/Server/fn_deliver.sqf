// [box, kind, class, count] -> nothing. Server. Puts goods into the delivery box.
params ["_box", "_kind", "_class", "_count"];
switch (_kind) do {
    case "mag": {_box addMagazineCargoGlobal [_class, _count]};
    case "item";
    case "gear": {_box addItemCargoGlobal [_class, _count]};
    case "backpack": {_box addBackpackCargoGlobal [_class, _count]};
    default {_box addWeaponCargoGlobal [_class, _count]};
};

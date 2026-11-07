// [] -> the gunsmith's vest upgrades (built once per machine, from CfgPMCShop >>
// GearUpgrades): [[key, from name, to name, from class, to class, kind ("role" | "belt" |
// "rev" undo), price, warbelts, old uniforms, item class ("" none), item count, gives,
// from state, to state, category], ...]   (states: the version's role, "базовый", "стрелок + пояс")
// Every upgrade can be undone: an "rev:" entry puts the old vest back for free and gives
// back what the upgrade took (the pouches, the belt and the rig come off the vest); gives
// is that list, [[class, count], ...] ([] for a forward upgrade).
if (!isNil "PMCS_gearList") exitWith {PMCS_gearList};
private _forward = ("true" configClasses (configFile >> "CfgPMCShop" >> "GearUpgrades")) apply {
    [getText (_x >> "key"), getText (_x >> "from"), getText (_x >> "to"), getText (_x >> "fromClass"), getText (_x >> "toClass"), getText (_x >> "kind"),
        getNumber (_x >> "price"), getNumber (_x >> "belt"), getNumber (_x >> "uniform"), getText (_x >> "item"), getNumber (_x >> "itemCount"), [],
        getText (_x >> "fromState"), getText (_x >> "toState"), getText (_x >> "category")]
};
PMCS_gearList = +_forward;
{
    _x params ["_key", "_from", "_to", "_fromClass", "_toClass"];
    PMCS_gearList pushBack ["rev:" + _key, _to, _from, _toClass, _fromClass, "rev", 0, 0, 0, "", 0, [_x] call PMCS_fnc_gearTake,
        _x select 13, _x select 12, _x select 14];
} forEach _forward;
PMCS_gearList

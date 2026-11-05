// [] -> the gunsmith's upgrades (built once per machine, from CfgPMCShop >> Upgrades):
//   [[key, from name, to name, kind ("gl" grenade launcher | "up" upgrade), operation,
//     price, [low, medium, high parts], pairs [[source class or pattern, target], ...]], ...]
// The parts are the items ar_things_weapon_parts_low / _med / _high.
if (!isNil "PMCS_upgradeList") exitWith {PMCS_upgradeList};
PMCS_upgradeList = ("true" configClasses (configFile >> "CfgPMCShop" >> "Upgrades")) apply {
    [getText (_x >> "key"), getText (_x >> "from"), getText (_x >> "to"), getText (_x >> "kind"), getText (_x >> "op"),
        getNumber (_x >> "price"), getArray (_x >> "parts"), getArray (_x >> "pairs")]
};
PMCS_upgradeList

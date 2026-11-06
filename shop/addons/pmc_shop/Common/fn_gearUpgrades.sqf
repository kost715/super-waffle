// [] -> the gunsmith's vest upgrades (built once per machine, from CfgPMCShop >>
// GearUpgrades): [[key, from name, to name, from class, to class, kind ("role" | "belt"),
// price, warbelts, old uniforms, item class ("" none), item count], ...]
if (!isNil "PMCS_gearList") exitWith {PMCS_gearList};
PMCS_gearList = ("true" configClasses (configFile >> "CfgPMCShop" >> "GearUpgrades")) apply {
    [getText (_x >> "key"), getText (_x >> "from"), getText (_x >> "to"), getText (_x >> "fromClass"), getText (_x >> "toClass"), getText (_x >> "kind"),
        getNumber (_x >> "price"), getNumber (_x >> "belt"), getNumber (_x >> "uniform"), getText (_x >> "item"), getNumber (_x >> "itemCount")]
};
PMCS_gearList

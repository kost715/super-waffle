// [] -> the gunsmith's weapon upgrades (built once per machine, from CfgPMCShop >> Upgrades):
//   [[key, from name, to name, kind ("gl" grenade launcher | "up" upgrade | "rev" undo),
//     operation, price, [low, medium, high parts], pairs [[source class or pattern, target], ...]], ...]
// The parts are the items ar_things_weapon_parts_low / _med / _high. Every upgrade can be
// undone: an "rev:" entry turns the result back (free; the parts are used up and stay so).
if (!isNil "PMCS_upgradeList") exitWith {PMCS_upgradeList};
private _forward = ("true" configClasses (configFile >> "CfgPMCShop" >> "Upgrades")) apply {
    [getText (_x >> "key"), getText (_x >> "from"), getText (_x >> "to"), getText (_x >> "kind"), getText (_x >> "op"),
        getNumber (_x >> "price"), getArray (_x >> "parts"), getArray (_x >> "pairs")]
};
private _back = _forward apply {
    _x params ["_key", "_from", "_to", "", "", "", "", "_pairs"];
    ["rev:" + _key, _to, _from, "rev", _from, 0, [0, 0, 0], _pairs apply {[_x select 1, _x select 0]}]
};
PMCS_upgradeList = _forward + _back;
PMCS_upgradeList

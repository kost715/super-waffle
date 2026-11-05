// [] -> the catalog (built once per machine, from the mod's config CfgPMCShop):
//   "items"   key -> [kind ("weapon" | "mag"), name, category (the table's weapon
//             category, "ammo" for magazines), calibre, price type, base price (one
//             piece in a box), 0 (unused), variants [[class, label, picture], ...],
//             magazine label, ammo type]
//   "order"   item keys in catalog order (weapons, then magazines)
//   "types"   price type -> [name, unit price]
//   "categories"  [[category key, label], ...] of the weapons on sale
//   "calibres"    calibre -> [magazine keys]
// Weapon classes with "*" are patterns: every class of the game that fits becomes a
// variant. Classes the game does not have are left out (once, in the RPT); an item with
// no class left is not on sale.
if (!isNil "PMCS_catalog") exitWith {PMCS_catalog};
private _root = configFile >> "CfgPMCShop";
private _types = createHashMap;
{
    _types set [configName _x, [getText (_x >> "name"), getNumber (_x >> "unitPrice")]];
} forEach ("true" configClasses (_root >> "PriceTypes"));
private _labels = createHashMap;
{_labels set [getText (_x >> "source"), getText (_x >> "name")]} forEach ("true" configClasses (_root >> "Categories"));
private _items = createHashMap;
private _order = [];
private _calibres = createHashMap;
private _categories = [];
private _missing = [];
private _all = [];
private _weaponInfo = {
    params ["_class"];
    private _cfg = configFile >> "CfgWeapons" >> _class;
    [configName _cfg, getText (_cfg >> "displayName"), getText (_cfg >> "picture")]
};
{
    private _patterns = getArray (_x >> "classes");
    if (_all isEqualTo [] && {_patterns findIf {"*" in _x} >= 0}) then {
        _all = ("getNumber (_x >> 'scope') >= 2" configClasses (configFile >> "CfgWeapons")) apply {configName _x};
    };
    private _variants = [];
    {
        private _pattern = _x;
        if ("*" in _pattern) then {
            private _found = _all select {[_x, _pattern] call PMCS_fnc_match};
            _found sort true;
            if (_found isEqualTo []) then {_missing pushBack _pattern};
            {_variants pushBackUnique ([_x] call _weaponInfo)} forEach _found;
        } else {
            if (isClass (configFile >> "CfgWeapons" >> _pattern)) then {_variants pushBackUnique ([_pattern] call _weaponInfo)} else {_missing pushBack _pattern};
        };
    } forEach _patterns;
    // Two variants with one name: the class tells them apart.
    private _names = _variants apply {_x select 1};
    {
        private _label = _x select 1;
        if (({_x == _label} count _names) > 1) then {_x set [1, format ["%1 (%2)", _label, _x select 0]]};
        if ((_x select 1) == "") then {_x set [1, _x select 0]};
    } forEach _variants;
    if (_variants isNotEqualTo []) then {
        private _key = configName _x;
        private _type = getText (_x >> "priceType");
        (_types getOrDefault [_type, ["", 0]]) params ["", "_unit"];
        private _category = getText (_x >> "category");
        _items set [_key, ["weapon", getText (_x >> "name"), _category, getText (_x >> "caliber"), _type, _unit, 0, _variants, "", ""]];
        _order pushBack _key;
        if (_categories findIf {(_x select 0) == _category} < 0) then {_categories pushBack [_category, _labels getOrDefault [_category, _category]]};
    };
} forEach ("true" configClasses (_root >> "Weapons"));
{
    private _class = configName _x;
    private _cfg = configFile >> "CfgMagazines" >> _class;
    if (isClass _cfg) then {
        private _calibre = getText (_x >> "caliber");
        _items set [_class, ["mag", getText (_cfg >> "displayName"), "ammo", _calibre, "ammo", getNumber (_x >> "price"), 0,
            [[_class, getText (_cfg >> "displayName"), getText (_cfg >> "picture")]], getText (_x >> "magazine"), getText (_x >> "ammo")]];
        _order pushBack _class;
        if !(_calibre in _calibres) then {_calibres set [_calibre, []]};
        (_calibres get _calibre) pushBack _class;
    } else {_missing pushBack _class};
} forEach ("true" configClasses (_root >> "Magazines"));
if (_missing isNotEqualTo []) then {diag_log text format ["[PMCS] %1 catalog classes are not in the game and are not on sale: %2", count _missing, _missing]};
PMCS_catalog = createHashMapFromArray [["items", _items], ["order", _order], ["types", _types], ["categories", _categories],
    ["calibres", _calibres]];
PMCS_catalog

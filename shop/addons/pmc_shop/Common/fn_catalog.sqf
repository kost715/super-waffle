// [] -> the catalog (built once per machine, from the mod's config CfgPMCShop):
//   "items"   key -> [kind ("weapon" | "mag"), name, category (the table's weapon
//             category, "ammo" for magazines), calibre, "" (unused), base price (one
//             weapon in a box; one magazine of the first type), 0 (unused), variants,
//             magazine label, "" (unused)]
//             a variant: [id, label, picture, classes, price factor]
//               weapon  a class of the table: [class, the game's name, picture, [class], 1];
//                       a pattern ("MMM_weap_AK74_H*S*"): one variant named by the mod
//                       ("MMM") whose classes are every class of the game that fits; a
//                       box (or a single piece) gets one of them at random
//               magazine row  one variant per ammo type: [class, type, picture, [class],
//                       factor from the table]
//   "order"   item keys in catalog order (weapons, then magazine rows)
//   "categories"  [[category key, label], ...] of the weapons on sale
//   "calibres"    calibre -> [magazine row keys]
// Classes the game does not have are left out (once, in the RPT); an item with no class
// left is not on sale.
if (!isNil "PMCS_catalog") exitWith {PMCS_catalog};
private _root = configFile >> "CfgPMCShop";
private _labels = createHashMap;
{_labels set [getText (_x >> "source"), getText (_x >> "name")]} forEach ("true" configClasses (_root >> "Categories"));
private _items = createHashMap;
private _order = [];
private _calibres = createHashMap;
private _categories = [];
private _missing = [];
private _all = [];
{
    private _patterns = getArray (_x >> "classes");
    if (_all isEqualTo [] && {_patterns findIf {"*" in _x} >= 0}) then {
        _all = ("getNumber (_x >> 'scope') >= 2" configClasses (configFile >> "CfgWeapons")) apply {configName _x};
    };
    private _variants = [];
    {
        private _pattern = _x;
        if ("*" in _pattern) then {
            // Only the classes this pattern owns: a more specific pattern of the table (a GP-25
            // version) keeps its own.
            private _found = _all select {[_x, _pattern] call PMCS_fnc_match && {([_x] call PMCS_fnc_ownerPattern) == toLower _pattern}};
            _found sort true;
            if (_found isEqualTo []) then {_missing pushBack _pattern} else {
                private _mod = toUpper ((_pattern splitString "_") select 0);
                _variants pushBack [_pattern, _mod, getText (configFile >> "CfgWeapons" >> (_found select 0) >> "picture"), _found, 1];
            };
        } else {
            private _cfg = configFile >> "CfgWeapons" >> _pattern;
            if (isClass _cfg) then {
                _variants pushBack [configName _cfg, getText (_cfg >> "displayName"), getText (_cfg >> "picture"), [configName _cfg], 1];
            } else {_missing pushBack _pattern};
        };
    } forEach _patterns;
    // Two variants with one name: the id tells them apart.
    private _names = _variants apply {_x select 1};
    {
        private _label = _x select 1;
        if (({_x == _label} count _names) > 1) then {_x set [1, format ["%1 (%2)", _label, _x select 0]]};
        if ((_x select 1) == "") then {_x set [1, _x select 0]};
    } forEach _variants;
    if (_variants isNotEqualTo []) then {
        private _key = configName _x;
        private _category = getText (_x >> "category");
        _items set [_key, ["weapon", getText (_x >> "name"), _category, getText (_x >> "caliber"), "", getNumber (_x >> "price"), 0, _variants, "", ""]];
        _order pushBack _key;
        if (_categories findIf {(_x select 0) == _category} < 0) then {_categories pushBack [_category, _labels getOrDefault [_category, _category]]};
    };
} forEach ("true" configClasses (_root >> "Weapons"));
{
    private _key = configName _x;
    private _variants = [];
    {
        _x params [["_type", "", [""]], ["_factor", 1, [0]], ["_class", "", [""]]];
        private _cfg = configFile >> "CfgMagazines" >> _class;
        if (isClass _cfg) then {
            _variants pushBack [configName _cfg, localize ("STR_PMCS_AMMO_" + _type), getText (_cfg >> "picture"), [configName _cfg], _factor];
        } else {_missing pushBack _class};
    } forEach getArray (_x >> "types");
    if (_variants isNotEqualTo []) then {
        private _calibre = getText (_x >> "caliber");
        private _label = getText (_x >> "magazine");
        _items set [_key, ["mag", format ["%1 %2", _calibre, _label], "ammo", _calibre, "", getNumber (_x >> "price"), 0, _variants, _label, ""]];
        _order pushBack _key;
        if !(_calibre in _calibres) then {_calibres set [_calibre, []]};
        (_calibres get _calibre) pushBack _key;
    };
} forEach ("true" configClasses (_root >> "Magazines"));
if (_missing isNotEqualTo []) then {diag_log text format ["[PMCS] %1 catalog classes are not in the game and are not on sale: %2", count _missing, _missing]};
PMCS_catalog = createHashMapFromArray [["items", _items], ["order", _order], ["categories", _categories], ["calibres", _calibres]];
PMCS_catalog

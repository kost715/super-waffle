// [] -> [shown item keys, counts per type (key -> n), counts per calibre (calibre -> n)].
// Client. What the shop's grid shows on the current tab: weapons (catalog weapons and
// what a Zeus added) or ammunition (magazines), on sale or sold out, by the search text,
// the ticked types and calibres, sorted. Counts are taken before the type and calibre
// filters, so every box shows how many it would add.
private _market = PMCS_ui get "market";
private _catalog = call PMCS_fnc_catalog;
private _ammo = (PMCS_ui get "tab") == "ammo";
private _search = toLower (PMCS_ui get "search");
private _keys = (_catalog get "order") select {(((_catalog get "items") get _x) select 0) == (["weapon", "mag"] select _ammo)};
{
    if (((_y select 0) == "mag") isEqualTo _ammo) then {_keys pushBack _x};
} forEach (_market getOrDefault ["custom", createHashMap]);
private _shown = [];
private _types = createHashMap;
private _cals = createHashMap;
{
    private _key = _x;
    private _info = [_key, _market] call PMCS_fnc_itemInfo;
    private _state = ([_key, _market] call PMCS_fnc_price) select 0;
    private _name = toLower ([_key, _market] call PMCS_fnc_itemName);
    if (_state in ["ok", "soldout"] && {_search == "" || {_search in _name} || {(_info select 7) findIf {_search in toLower (_x select 0)} >= 0}}) then {
        private _type = [_info select 2, _info select 9] select _ammo;
        if (_type == "") then {_type = "custom"};
        private _cal = [_info select 3, "-"] select ((_info select 3) == "");
        _types set [_type, (_types getOrDefault [_type, 0]) + 1];
        _cals set [_cal, (_cals getOrDefault [_cal, 0]) + 1];
        if !(_type in (PMCS_ui get "offTypes") || {_cal in (PMCS_ui get "offCals")}) then {_shown pushBack _key};
    };
} forEach _keys;
private _sort = PMCS_ui get "sort";
private _rows = _shown apply {
    private _price = ([_x, _market] call PMCS_fnc_price) select 1;
    [[_price, -_price, 0] select _sort, [_x, _market] call PMCS_fnc_itemName, _x]
};
if (_sort == 2) then {_rows = _rows apply {[_x select 1, _x select 2]}};
_rows sort true;
[_rows apply {_x select (count _x - 1)}, _types, _cals]

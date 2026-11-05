// [] -> [shown keys, counts per category, counts per calibre]. Client. What the shop's grid
// shows on the current tab, on sale or sold out, by the search text and the ticked boxes,
// sorted by the card's box price (the first variant: a magazine row's Ball) or by name:
//   weapons    catalog weapons and what a Zeus added (not magazines); filters: the
//              table's weapon category and the calibre
//   ammunition magazine rows of the table (one per calibre and magazine) and magazines a
//              Zeus added; filter: the calibre
// Counts are taken before the filters, so every box shows how many it would add.
private _market = PMCS_ui get "market";
private _catalog = call PMCS_fnc_catalog;
private _ammo = (PMCS_ui get "tab") == "ammo";
private _search = toLower (PMCS_ui get "search");
private _sort = PMCS_ui get "sort";
private _types = createHashMap;
private _cals = createHashMap;
private _rows = [];
private _keys = (_catalog get "order") select {((((_catalog get "items") get _x) select 0) == "mag") isEqualTo _ammo};
{
    if (((_y select 0) == "mag") isEqualTo _ammo) then {_keys pushBack _x};
} forEach (_market getOrDefault ["custom", createHashMap]);
{
    private _key = _x;
    private _info = [_key, _market] call PMCS_fnc_itemInfo;
    ([_key, _market] call PMCS_fnc_price) params ["_state", "", "_box"];
    private _name = [_key, _market] call PMCS_fnc_itemName;
    if (_state in ["ok", "soldout"] && {_search == "" || {_search in toLower _name}
        || {(_info select 7) findIf {(_x select 3) findIf {_search in toLower _x} >= 0} >= 0}}) then {
        private _type = _info select 2;
        private _cal = [_info select 3, "-"] select ((_info select 3) == "");
        _types set [_type, (_types getOrDefault [_type, 0]) + 1];
        _cals set [_cal, (_cals getOrDefault [_cal, 0]) + 1];
        if !(_type in (PMCS_ui get "offTypes") || {_cal in (PMCS_ui get "offCals")}) then {
            _rows pushBack [[_box, -_box, 0] select _sort, _name, _key];
        };
    };
} forEach _keys;
if (_sort == 2) then {_rows = _rows apply {[_x select 1, _x select 2]}};
_rows sort true;
[_rows apply {_x select (count _x - 1)}, _types, _cals]

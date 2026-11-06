// [] -> [shown keys, counts per category, counts per calibre]. Client. What the shop's grid
// shows on the current tab, on sale or sold out, by the search text and the selected filter
// rows (only what is selected stays; a section with nothing selected shows all), sorted by
// the card's box price (the first variant: a magazine row's Ball) or by name:
//   weapons    catalog weapons and what a Zeus added (not magazines); filters: the
//              table's weapon category and the calibre
//   ammunition magazine rows of the table (one per calibre and magazine) and magazines a
//              Zeus added; filter: the calibre
// Counts are taken before the filters, so every row shows how many goods it stands for.
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
        // No calibre: single-use launchers and added items (on the ammunition tab, magazines a
        // Zeus added are listed under "-"). They have no calibre row.
        private _cal = _info select 3;
        if (_cal == "" && {_ammo}) then {_cal = "-"};
        _types set [_type, (_types getOrDefault [_type, 0]) + 1];
        if (_cal != "") then {_cals set [_cal, (_cals getOrDefault [_cal, 0]) + 1]};
        _rows pushBack [[_box, -_box, 0] select _sort, _name, _key, _type, _cal];
    };
} forEach _keys;
// The selected rows are what stays; a section with nothing selected shows all. Goods without
// a calibre stay while every calibre row is selected.
private _selTypes = PMCS_ui get "selTypes";
private _selCals = PMCS_ui get "selCals";
private _allCals = ((keys _cals) findIf {!(_x in _selCals)}) < 0;
_rows = (_rows select {
    (_selTypes isEqualTo [] || {(_x select 3) in _selTypes})
        && {_selCals isEqualTo [] || {(_x select 4) in _selCals} || {(_x select 4) == "" && {_allCals}}}
}) apply {[_x select 0, _x select 1, _x select 2]};
if (_sort == 2) then {_rows = _rows apply {[_x select 1, _x select 2]}};
_rows sort true;
[_rows apply {_x select (count _x - 1)}, _types, _cals]

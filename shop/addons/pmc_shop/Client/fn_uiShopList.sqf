// [] -> [shown keys, counts per first filter, counts per calibre]. Client. What the shop's
// grid shows on the current tab, on sale or sold out, by the search text and the ticked
// boxes, sorted:
//   weapons    item keys (catalog weapons and what a Zeus added); filters: the table's
//              weapon category and the calibre
//   ammunition calibres (strings) with magazines on sale; filter: the ammo type (a calibre
//              is shown when it has one of the ticked types)
// Counts are taken before the filters, so every box shows how many it would add.
private _market = PMCS_ui get "market";
private _catalog = call PMCS_fnc_catalog;
private _ammo = (PMCS_ui get "tab") == "ammo";
private _search = toLower (PMCS_ui get "search");
private _sort = PMCS_ui get "sort";
private _types = createHashMap;
private _cals = createHashMap;
private _rows = [];
if (_ammo) then {
    private _byCal = createHashMap;
    {
        private _key = _x;
        private _info = [_key, _market] call PMCS_fnc_itemInfo;
        private _cal = [_info select 3, "-"] select ((_info select 3) == "");
        if (((_info select 0) == "mag") && {(([_key, _market] call PMCS_fnc_price) select 0) in ["ok", "soldout"]}
            && {_search == "" || {_search in toLower _cal} || {_search in toLower _key} || {_search in toLower (_info select 8)}}) then {
            if !(_cal in _byCal) then {_byCal set [_cal, []]};
            (_byCal get _cal) pushBack _key;
        };
    } forEach ((_catalog get "order") + keys (_market getOrDefault ["custom", createHashMap]));
    {
        private _cal = _x;
        private _keys = _y;
        private _calTypes = [];
        {_calTypes pushBackUnique ((([_x, _market] call PMCS_fnc_itemInfo) select 9) call {[_this, "special"] select (_this == "")})} forEach _keys;
        {_types set [_x, (_types getOrDefault [_x, 0]) + 1]} forEach _calTypes;
        if ((_calTypes findIf {!(_x in (PMCS_ui get "offTypes"))}) >= 0) then {
            private _cheapest = selectMin (_keys apply {([_x, _market] call PMCS_fnc_price) select 2});
            _rows pushBack [[_cheapest, -_cheapest, 0] select _sort, _cal, _cal];
        };
    } forEach _byCal;
} else {
    private _keys = (_catalog get "order") select {(((_catalog get "items") get _x) select 0) == "weapon"};
    {
        if ((_y select 0) != "mag") then {_keys pushBack _x};
    } forEach (_market getOrDefault ["custom", createHashMap]);
    {
        private _key = _x;
        private _info = [_key, _market] call PMCS_fnc_itemInfo;
        ([_key, _market] call PMCS_fnc_price) params ["_state", "", "_box"];
        private _name = [_key, _market] call PMCS_fnc_itemName;
        if (_state in ["ok", "soldout"] && {_search == "" || {_search in toLower _name} || {(_info select 7) findIf {_search in toLower (_x select 0)} >= 0}}) then {
            private _type = _info select 2;
            private _cal = [_info select 3, "-"] select ((_info select 3) == "");
            _types set [_type, (_types getOrDefault [_type, 0]) + 1];
            _cals set [_cal, (_cals getOrDefault [_cal, 0]) + 1];
            if !(_type in (PMCS_ui get "offTypes") || {_cal in (PMCS_ui get "offCals")}) then {
                _rows pushBack [[_box, -_box, 0] select _sort, _name, _key];
            };
        };
    } forEach _keys;
};
if (_sort == 2) then {_rows = _rows apply {[_x select 1, _x select 2]}};
_rows sort true;
[_rows apply {_x select (count _x - 1)}, _types, _cals]

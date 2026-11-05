// [calibre] -> the magazine keys of that calibre on sale or sold out (catalog magazines
// and magazines a Zeus added; those have no calibre and are listed under "-"). Client.
params [["_calibre", "", [""]]];
private _market = PMCS_ui get "market";
private _keys = +(((call PMCS_fnc_catalog) get "calibres") getOrDefault [_calibre, []]);
if (_calibre == "-") then {
    {if ((_y select 0) == "mag") then {_keys pushBack _x}} forEach (_market getOrDefault ["custom", createHashMap]);
};
_keys select {(([_x, _market] call PMCS_fnc_price) select 0) in ["ok", "soldout"]}

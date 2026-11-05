// [category] -> its name in the shop: the table's weapon category as the catalog names it
// ("Штурмовые винтовки"), "ammo" -> ammunition, "custom" -> added by a Zeus.
params [["_category", "", [""]]];
if (_category == "ammo") exitWith {localize "STR_PMCS_TAB_AMMO"};
if (_category == "custom") exitWith {localize "STR_PMCS_CATEGORY_CUSTOM"};
private _row = ((call PMCS_fnc_catalog) get "categories") select {(_x select 0) == _category};
if (_row isEqualTo []) exitWith {_category};
(_row select 0) select 1

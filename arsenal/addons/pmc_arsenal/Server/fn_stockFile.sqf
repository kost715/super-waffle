// postInit, server. Applies the editable stock file once after each edit.
// Looked up in this order:
//   <Arma 3>\userconfig\pmc_arsenal_stock.txt   (server started with -filePatching)
//   pmc_arsenal_stock.txt in the mission folder
// Format: [[storageID, [[class, amount], [magazine, magazines, extraRounds], ...]], ...]
// with // comments; amount -1 is unlimited. Every storage listed gets exactly that
// stock; storages not listed are untouched. The applied text is kept in the profile,
// so an unchanged file is not applied again and stock changed in play stays.
if (!isServer || {PMCA_saveBlocked}) exitWith {false};
private _path = "";
private _text = "";
// Reading a missing file is a script error in Arma: check first.
{
    if (_text == "" && {fileExists _x}) then {_text = loadFile _x; _path = _x};
} forEach ((["userconfig\pmc_arsenal_stock.txt"] select {isFilePatchingEnabled}) + ["pmc_arsenal_stock.txt"]);
if (_text == "") exitWith {false};
if (_text isEqualTo (profileNamespace getVariable ["PMCA_stockFile_v1", ""])) exitWith {false};
// Drop // comments outside quoted class names.
private _comment = toString [47, 47];
private _lines = (_text splitString toString [10, 13]) apply {
    private _line = _x;
    private _at = _line find _comment;
    if (_at >= 0 && {(count ((toArray (_line select [0, _at])) select {_x == 34})) % 2 == 0}) then {_line select [0, _at]} else {_line}
};
// The list starts at the first "["; anything before it (an editor's byte order mark) is dropped.
private _codes = toArray (_lines joinString " ");
private _clean = toString (_codes select [(_codes find 91) max 0, count _codes]);
private _data = parseSimpleArray _clean;
private _blank = ((toArray _clean) select {!(_x in [9, 32])}) isEqualTo [91, 93];
if !(_data isEqualType [] && {_data isNotEqualTo [] || {_blank}} && {
    (_data findIf {!(_x isEqualTypeArray ["", []]) || {(_x select 0) == ""}}) < 0}) exitWith {
    diag_log text format ["[PMCA] ERROR: %1 is not a valid stock list; nothing was changed", _path];
    false
};
{
    _x params ["_id", "_rows"];
    private _items = createHashMap;
    {
        _x params [["_class", "", [""]], ["_amount", 0, [0]], ["_extra", 0, [0]]];
        private _key = [_class] call PMCA_fnc_itemKey;
        private _valid = _key != "" && {(_key call PMCA_fnc_arsenal_itemType) >= 0} && {_amount == -1 || {_amount >= 0 && {_amount == floor _amount}}} && {
            _extra >= 0 && {_extra == floor _extra}};
        if (_valid) then {
            if (_amount != -1 && {isClass (configFile >> "CfgMagazines" >> _key)}) then {
                _amount = _amount * ((getNumber (configFile >> "CfgMagazines" >> _key >> "count")) max 1) + _extra;
            };
            if (_amount != 0) then {
                private _have = _items getOrDefault [_key, 0];
                _items set [_key, if (_have == -1 || {_amount == -1}) then {-1} else {_have + _amount}];
            };
        } else {
            diag_log text format ["[PMCA] %1: skipped row %2 of storage %3 (unknown class or bad amount)", _path, _x, _id];
        };
    } forEach _rows;
    private _storage = PMCA_storages getOrDefault [_id, createHashMap];
    if (count _storage == 0) then {
        _storage = createHashMapFromArray [["categories", []], ["persist", true]];
        PMCA_storages set [_id, _storage];
    };
    _storage set ["items", _items];
    [_id] call PMCA_fnc_unlock;
} forEach _data;
profileNamespace setVariable ["PMCA_stockFile_v1", _text];
PMCA_dirty = true;
diag_log text format ["[PMCA] Stock file %1 applied: %2 storage(s)", _path, count _data];
true

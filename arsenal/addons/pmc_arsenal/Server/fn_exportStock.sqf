// -> text. Server. The current stock in the format of the editable stock file
// (see PMCA_fnc_stockFile), written to the server RPT; on a hosting player's
// machine it is copied to the clipboard too unless [false] is passed.
params [["_clipboard", true, [true]]];
if (!isServer || {isNil "PMCA_storages"}) exitWith {""};
private _nl = toString [13, 10];
private _out = ["// PMC Arsenal: stock. Edit, save, restart the mission.",
    "// [class, pieces]; magazines: [class, magazines, extra rounds]; -1 = unlimited.", "["];
private _ids = (keys PMCA_storages) select {(PMCA_storages get _x) getOrDefault ["persist", true]};
_ids sort true;
{
    private _id = _x;
    private _items = (PMCA_storages get _id) get "items";
    private _classes = keys _items;
    _classes sort true;
    private _rows = _classes apply {
        private _amount = _items get _x;
        private _size = (getNumber (configFile >> "CfgMagazines" >> _x >> "count")) max 1;
        if (_amount != -1 && {isClass (configFile >> "CfgMagazines" >> _x)}) then {
            private _extra = _amount % _size;
            private _row = format ["        [%1, %2", str _x, floor (_amount / _size) toFixed 0];
            if (_extra > 0) then {_row = _row + ", " + (_extra toFixed 0)};
            _row + "]"
        } else {
            format ["        [%1, %2]", str _x, _amount toFixed 0]
        }
    };
    _out pushBack format ["    [%1, [", str _id];
    _out pushBack (_rows joinString ("," + _nl));
    _out pushBack (["    ]]", "    ]],"] select (_forEachIndex < count _ids - 1));
} forEach _ids;
_out pushBack "]";
private _text = _out joinString _nl;
diag_log text "[PMCA] ---- stock file begins ----";
{diag_log text _x} forEach (_text splitString _nl);
diag_log text "[PMCA] ---- stock file ends ----";
if (_clipboard && {hasInterface}) then {copyToClipboard _text};
_text

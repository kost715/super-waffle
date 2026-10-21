// Strict UTF-8 bytes, 3..40 visible Unicode characters. Transport and DB use
// numeric bytes so the Arma browser bridge cannot re-encode Cyrillic names.
params [["_bytes", [], [[]]]];
if (count _bytes > 320 || {(_bytes findIf {!(_x isEqualType 0) || {_x != floor _x} || {_x < 0} || {_x > 255}}) >= 0}) exitWith {[]};
private _clean = [];
private _space = true;
{
    if (_x != 32 || {!_space}) then {_clean pushBack _x};
    _space = _x == 32;
} forEach _bytes;
if (_clean isNotEqualTo [] && {(_clean select (count _clean - 1)) == 32}) then {_clean deleteAt (count _clean - 1)};
private _i = 0;
private _chars = 0;
private _valid = true;
while {_i < count _clean && {_valid}} do {
    private _b = _clean select _i;
    private _n = 1;
    private _cp = _b;
    private _min = 0;
    switch (true) do {
        case (_b < 128): {};
        case (_b >= 194 && {_b <= 223}): {_n = 2; _cp = _b - 192; _min = 128};
        case (_b >= 224 && {_b <= 239}): {_n = 3; _cp = _b - 224; _min = 2048};
        case (_b >= 240 && {_b <= 244}): {_n = 4; _cp = _b - 240; _min = 65536};
        default {_valid = false};
    };
    if (_i + _n > count _clean) then {_valid = false};
    if (_valid) then {
        for "_j" from 1 to (_n - 1) do {
            private _next = _clean select (_i + _j);
            if (_next < 128 || {_next > 191}) then {_valid = false};
            _cp = _cp * 64 + _next - 128;
        };
        if (_cp < _min || {_cp > 1114111} || {_cp >= 55296 && {_cp <= 57343}} || {
            _cp < 32 || {_cp >= 127 && {_cp <= 159}} || {_cp in [60, 62, 8232, 8233]}
        } || {_cp >= 8203 && {_cp <= 8207}} || {_cp >= 8234 && {_cp <= 8238}} || {
            _cp >= 8288 && {_cp <= 8303}
        } || {_cp in [160, 65279]}) then {_valid = false};
    };
    _chars = _chars + 1;
    _i = _i + _n;
};
if (!_valid || {_chars < 3} || {_chars > 40}) exitWith {[]};
_clean

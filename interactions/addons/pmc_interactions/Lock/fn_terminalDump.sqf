// [digits, codes, brackets] -> [codes, answer index, rows, bracket effects, row texts]. Random.
// The memory dump of the terminal game (PMCI_fnc_terminalModel): `codes` different codes
// of `digits` digits, each the answer with some of its digits changed (so likeness narrows
// them down), and `brackets` bracket pairs, spread over 16 rows of junk. The last of two or
// more brackets restores the attempts, the others remove duds. A row text is
// [address, before, middle, after]: middle is the code or the bracket pair, "" in junk.
params ["_digits", "_count", "_brackets"];
private _shuffle = {
    private _list = +_this;
    for "_i" from count _list - 1 to 1 step -1 do {
        private _j = floor random (_i + 1);
        private _swap = _list select _i;
        _list set [_i, _list select _j];
        _list set [_j, _swap];
    };
    _list
};
private _answer = "";
for "_k" from 1 to _digits do {_answer = _answer + str (floor random 10)};
private _codes = [_answer];
private _places = [];
for "_k" from 0 to _digits - 1 do {_places pushBack _k};
private _tries = 0;
while {count _codes < _count && {_tries < 500}} do {
    _tries = _tries + 1;
    private _chars = toArray _answer;
    {
        private _digit = 48 + floor random 9;
        if (_digit >= (_chars select _x)) then {_digit = _digit + 1};
        _chars set [_x, _digit];
    } forEach ((_places call _shuffle) select [0, 1 + floor random _digits]);
    private _code = toString _chars;
    if !(_code in _codes) then {_codes pushBack _code};
};
_codes = _codes call _shuffle;
private _rows = [];
for "_k" from 0 to 15 do {_rows pushBack ["junk", -1]};
private _spots = [];
for "_k" from 0 to 15 do {_spots pushBack _k};
_spots = _spots call _shuffle;
{_rows set [_spots select _forEachIndex, ["code", _forEachIndex]]} forEach _codes;
for "_k" from 0 to (_brackets min (16 - count _codes)) - 1 do {_rows set [_spots select (count _codes + _k), ["bracket", _k]]};
private _effects = [];
for "_k" from 0 to _brackets - 1 do {_effects pushBack (["dud", "reset"] select (_brackets > 1 && {_k == _brackets - 1}))};
// Junk has neither digits nor brackets, so only the real codes and pairs stand out.
private _junk = toArray "!@#$%^&*-+=?/\|:;.,'_~";
private _noise = {
    private _out = [];
    for "_k" from 1 to _this do {_out pushBack selectRandom _junk};
    toString _out
};
private _hex = "0123456789ABCDEF";
private _texts = [];
{
    _x params ["_kind", "_index"];
    private _middle = switch (_kind) do {
        case "code": {_codes select _index};
        case "bracket": {
            private _pair = selectRandom ["()", "[]", "{}", "<>"];
            (_pair select [0, 1]) + ((1 + floor random 4) call _noise) + (_pair select [1, 1])
        };
        default {""};
    };
    private _before = floor random (15 - count _middle);
    private _address = 62624 + 12 * _forEachIndex;
    private _text = "0x";
    {_text = _text + (_hex select [floor (_address / _x) % 16, 1])} forEach [4096, 256, 16, 1];
    _texts pushBack [_text, _before call _noise, _middle, (14 - _before - count _middle) call _noise];
} forEach _rows;
[_codes, _codes find _answer, _rows, _effects, _texts]

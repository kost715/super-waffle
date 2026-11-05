// [amount] -> "1 875 $": thousands separated, the currency of PMC Bank (CBA PMCB_currency).
params [["_amount", 0, [0]]];
private _digits = toArray ((abs _amount) toFixed 0);
private _out = [];
{
    if (_forEachIndex > 0 && {(count _digits - _forEachIndex) % 3 == 0}) then {_out pushBack 32};
    _out pushBack _x;
} forEach _digits;
format ["%1%2 %3", ["", "-"] select (_amount < 0), toString _out, missionNamespace getVariable ["PMCB_currency", "$"]]

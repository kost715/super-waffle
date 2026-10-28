// [entries] -> text. Client (Zeus). Journal entries as semicolon-separated lines with
// a header: copied to the clipboard and written to this machine's RPT.
params [["_entries", [], [[]]]];
private _nl = toString [13, 10];
private _lines = [localize "STR_PMCB_EXPORT_HEADER"];
{
    _x params ["_n", "_time", "_account", "_accountName", "_op", "_amount", "_after", "_actorUid", "_actorName", "_mission"];
    _lines pushBack ([str _n, _time, format ["%1 (%2)", _accountName, _account], localize ("STR_PMCB_OP_" + _op),
        _amount toFixed 0, _after toFixed 0, _actorName, _actorUid, _mission] joinString ";");
} forEach _entries;
private _text = _lines joinString _nl;
copyToClipboard _text;
diag_log text "[PMCB] ---- journal export begins ----";
{diag_log text _x} forEach _lines;
diag_log text "[PMCB] ---- journal export ends ----";
["STR_PMCB_EXPORTED", [count _entries]] call PMCB_fnc_notify;
_text

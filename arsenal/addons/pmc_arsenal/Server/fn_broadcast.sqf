// [storageID, [[class, amount], ...], isAdd, exceptOwners] -> nothing. Server.
// Updates the counts shown to everyone browsing the storage. Display only:
// each client receives just the tabs it may take from.
params ["_id", "_rows", "_add", ["_except", []]];
if (_rows isEqualTo []) exitWith {};
private _mode = ["UpdateItemRemove", "UpdateItemAdd"] select _add;
{
    private _owner = _x;
    private _session = _y;
    if ((_session get "storage") == _id && {!(_owner in _except)}) then {
        private _tabs = _session get "tabs";
        {
            _x params ["_class", "_amount"];
            private _tab = _class call PMCA_fnc_arsenal_itemType;
            if (_tab in _tabs && {_amount != 0}) then {[_mode, [_tab, _class, _amount, true]] remoteExecCall ["PMCA_fnc_arsenal", _owner]};
        } forEach _rows;
    };
} forEach PMCA_sessions;

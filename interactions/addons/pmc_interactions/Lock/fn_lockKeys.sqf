// -> the five key classes set in CBA (PMCI_lockKey1-5), "" for an empty slot.
private _keys = [];
for "_k" from 1 to 5 do {
    private _class = missionNamespace getVariable [format ["PMCI_lockKey%1", _k], ""];
    if !(_class isEqualType "") then {_class = ""};
    _keys pushBack ((_class splitString " ""'") joinString "");
};
_keys

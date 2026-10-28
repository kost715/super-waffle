// [storageID, rows] -> nothing. Server -> Zeus: the storage's stock; opens the stock
// window or refreshes it.
params [["_id", "", [""]], ["_rows", [], [[]]]];
if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {};
private _open = !isNil "PMCA_stockUi" && {(PMCA_stockUi getOrDefault ["id", ""]) == _id} && {!isNull (uiNamespace getVariable ["PMCA_stockDisplay", displayNull])};
if (_open) then {
    PMCA_stockUi set ["rows", _rows];
    ["draw"] call PMCA_fnc_stockUi;
} else {
    PMCA_stockUi = createHashMapFromArray [["id", _id], ["rows", _rows], ["filter", "all"]];
    createDialog "PMCA_RscStock";
};

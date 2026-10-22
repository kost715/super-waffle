// Called only for an established legacy founder or a new base/name purchase.
// isRemoteExecuted stays true inside a legitimate request's call chain; only a
// client remote-executing this function directly (no calling function) is refused.
params ["_uid"];
if (!isServer || {isRemoteExecuted && {!isNil "_fnc_scriptNameParent"} && {_fnc_scriptNameParent == _fnc_scriptName}} || {!(missionNamespace getVariable ["ALSPMC_companiesReady", false])}) exitWith {createHashMap};
private _company = [_uid] call ALSPMC_fnc_companyOf;
if (count _company > 0) exitWith {_company};
private _id = "pmc_" + _uid;
_company = createHashMapFromArray [["id", _id], ["owner", _uid],
    ["members", createHashMapFromArray [[_uid, "owner"]]], ["balance", 0],
    ["debt", 0], ["reserve", 0], ["seconds", 0], ["ledger", []],
    ["receipts", []], ["revision", 0]];
ALSPMC_companies set [_id, _company];
call ALSPMC_fnc_companySave;
_company

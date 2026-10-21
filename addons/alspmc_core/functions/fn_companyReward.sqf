// Server settlement only; not registered as an RPC. Native jobs never enter here.
params ["_id", "_qid", "_amount", "_actor"];
if (!isServer || {isRemoteExecuted} || {!(missionNamespace getVariable ["ALSPMC_companiesReady", false])}) exitWith {false};
private _c = ALSPMC_companies getOrDefault [_id, createHashMap];
if (count _c == 0 || {_qid <= 0} || {_amount < 0} || {_amount != floor _amount}) exitWith {false};
if (_qid in (_c get "receipts")) exitWith {true};
if ((_c get "balance") + _amount > 10000000) exitWith {false};
(_c get "receipts") pushBack _qid;
_c set ["balance", (_c get "balance") + _amount];
_c set ["revision", (_c get "revision") + 1];
private _ledger = _c get "ledger";
_ledger insert [0, [[date, _actor, _amount, "contract", str _qid]]]; _c set ["ledger", _ledger select [0,100]];
call ALSPMC_fnc_companySave;
true

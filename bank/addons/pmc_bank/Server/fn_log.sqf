// [account, account name, operation, amount, balance after, actor UID, actor name]
// -> nothing. Server. Appends a journal entry; the oldest entries beyond the CBA
// setting PMCB_logLimit are dropped.
params ["_account", "_accountName", "_op", "_amount", "_balance", "_actorUid", "_actorName"];
private _two = {[str _this, "0" + str _this] select (_this < 10)};
(systemTime select [0, 6]) params ["_y", "_mo", "_d", "_h", "_mi", "_s"];
private _time = format ["%1-%2-%3 %4:%5:%6", _y, _mo call _two, _d call _two, _h call _two, _mi call _two, _s call _two];
PMCB_seq = PMCB_seq + 1;
PMCB_log pushBack [PMCB_seq, _time, _account, _accountName, _op, _amount, _balance, _actorUid, _actorName, format ["%1 (%2)", missionName, worldName]];
private _limit = round (missionNamespace getVariable ["PMCB_logLimit", 2000]);
if (count PMCB_log > _limit) then {PMCB_log deleteRange [0, count PMCB_log - _limit]};
PMCB_dirty = true;

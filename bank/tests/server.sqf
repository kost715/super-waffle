// Bank checks in SQF-VM: banknotes, balances, ATM operations, Zeus modules,
// journal and persistence. The shipped functions run unchanged through the opcode
// adapter in vm_compat.sqf; the ATM window itself is not exercised.
call compile preprocessFileLineNumbers "tests/vm_compat.sqf";
TEST_count = 0;
TEST_fnc_assert = {
    params ["_ok", "_label"];
    if (!_ok) then {diag_log ("TEST_FAIL: " + _label); exitcode__ 1};
    TEST_count = TEST_count + 1;
    diag_log ("TEST_PASS: " + _label);
};
{
    missionNamespace setVariable ["PMCB_fnc_" + _x, ("pmc_bank/Common/fn_" + _x + ".sqf") call TEST_fnc_load];
} forEach ["notes", "noteValue", "compose", "noteCounts", "money", "requestOwner"];
{
    missionNamespace setVariable ["PMCB_fnc_" + _x, ("pmc_bank/Server/fn_" + _x + ".sqf") call TEST_fnc_load];
} forEach ["serverInit", "serverLoad", "save", "caller", "isZeus", "atmNear", "ensure", "log", "apply", "parseComposition",
    "state", "push", "pushGroup", "requestState", "closed", "withdraw", "depositStart", "depositSettle", "registerAtm",
    "moduleAtm", "zeusAdjust", "zeusTreasurer", "zeusAtm", "zeusLog"];
{
    missionNamespace setVariable ["PMCB_fnc_" + _x, ("pmc_bank/Client/fn_" + _x + ".sqf") call TEST_fnc_load];
} forEach ["receive", "receiveLog", "give", "take", "notify", "export", "atmInit", "moduleZeusAdd", "moduleZeusJournal"];
PMCB_fnc_settings = "pmc_bank/Init/fn_settings.sqf" call TEST_fnc_load;
// The window is not exercised: its draw calls are recorded only.
TEST_draws = 0;
PMCB_fnc_ui = {TEST_draws = TEST_draws + 1};

TEST_settings = [];
CBA_fnc_addSetting = {
    params ["_name", "_type", "_title", "_category", "_value", ["_global", 0], ["_script", {}]];
    TEST_settings pushBack [_name, _type, _value, _global];
    missionNamespace setVariable [_name, if (_type == "SLIDER") then {_value select 2} else {_value}];
};

TEST_fnc_sent = {
    params ["_fn", ["_first", nil], ["_target", -1]];
    TEST_messages select {
        private _remote = _x select 1;
        (_remote select 0) == _fn && {_target == -1 || {(_remote select 1) isEqualTo _target}} && {
            isNil "_first" || {((_x select 0) param [0, ""]) isEqualTo _first}}
    }
};
TEST_fnc_as = {TEST_isRemoteExecuted = true; TEST_remoteOwner = _this};
TEST_fnc_unit = {
    params ["_owner", "_uid", "_name", "_pos"];
    private _u = "B_Soldier_F" createVehicle _pos;
    _u setPos _pos;
    _u setVariable ["TEST_class", "B_Soldier_F"];
    _u setVariable ["TEST_owner", _owner];
    _u setVariable ["TEST_uid", _uid];
    _u setVariable ["TEST_name", _name];
    _u setVariable ["TEST_player", true];
    _u
};
TEST_fnc_lastState = {
    params ["_owner"];
    private _all = ["PMCB_fnc_receive", nil, _owner] call TEST_fnc_sent;
    if (_all isEqualTo []) then {[]} else {((_all select (count _all - 1)) select 0) select 0}
};
TEST_fnc_personal = {((PMCB_accounts get _this) select 0)};
TEST_notesSetting = "Money_100:100, Money_50 : 50,Money_20:20, Money_Coins:5, Nope_Item:1000, FirstAidKit:abc, Money_20:30";
TEST_fnc_fresh = {
    PMCB_accounts = nil;
    PMCB_notesSource = nil;
    profileNamespace setVariable ["PMCB_bank_v1", nil];
    TEST_settings = [];
    call PMCB_fnc_settings;
    PMCB_notes = TEST_notesSetting;
    PMCB_startBalance = 500;
    TEST_isRemoteExecuted = false;
    TEST_remoteOwner = 2;
    TEST_messages = [];
    TEST_onSleep = {};
    TEST_atm = "Land_Atm_01_F" createVehicle [0, 0, 0];
    TEST_atm setVariable ["TEST_class", "Land_Atm_01_F"];
    TEST_player = [3, "76561100000000001", "Ivan", [2, 0, 0]] call TEST_fnc_unit;
    TEST_other = [5, "76561100000000002", "Petr", [0, 2, 0]] call TEST_fnc_unit;
    TEST_zeus = [4, "76561100000000009", "Zeus", [500, 0, 0]] call TEST_fnc_unit;
    TEST_zeus setVariable ["TEST_curator", TEST_atm];
    call PMCB_fnc_serverLoad;
    [TEST_atm] call PMCB_fnc_registerAtm;
    TEST_messages = [];
};

// --- Settings and banknotes -------------------------------------------------------
call TEST_fnc_fresh;
private _names = TEST_settings apply {_x select 0};
[_names isEqualTo ["PMCB_notes", "PMCB_currency", "PMCB_groupName", "PMCB_startBalance", "PMCB_logLimit"] && {(TEST_settings findIf {(_x select 3) != 1}) < 0},
    "settings: banknotes, currency, group name, starting balance and journal size, forced by the server"] call TEST_fnc_assert;
private _arpi = [1000, 500, 200, 100, 50, 25, 5] apply {[format ["ar_money_%1dollar", _x], _x]};
private _defaultNotes = PMCB_notes;
PMCB_notes = (TEST_settings select {(_x select 0) == "PMCB_notes"}) select 0 select 2;
[(call PMCB_fnc_notes) isEqualTo _arpi, "the default banknotes are the ARPI ones, 5 to 1000"] call TEST_fnc_assert;
[([1985, _arpi] call PMCB_fnc_compose) isEqualTo [["ar_money_1000dollar", 1], ["ar_money_500dollar", 1], ["ar_money_200dollar", 2], ["ar_money_50dollar", 1], ["ar_money_25dollar", 1], ["ar_money_5dollar", 2]] && {
    ([1983, _arpi] call PMCB_fnc_compose) isEqualTo []}, "with ARPI notes any multiple of 5 can be paid"] call TEST_fnc_assert;
PMCB_notes = _defaultNotes;
private _notes = call PMCB_fnc_notes;
[_notes isEqualTo [["Money_100", 100], ["Money_50", 50], ["Money_20", 20], ["Money_Coins", 5]],
    "banknotes are read from the setting largest first; unknown classes, bad and repeated values are skipped"] call TEST_fnc_assert;
[(["MONEY_50"] call PMCB_fnc_noteValue) == 50 && {(["FirstAidKit"] call PMCB_fnc_noteValue) == 0}, "a banknote's value is found whatever the case"] call TEST_fnc_assert;
[([12500] call PMCB_fnc_money) == "12 500 $" && {([0] call PMCB_fnc_money) == "0 $"} && {([-1500] call PMCB_fnc_money) == "-1 500 $"}, "amounts are written with spaces and the currency"] call TEST_fnc_assert;

// --- Choosing banknotes -------------------------------------------------------------
[([385, _notes] call PMCB_fnc_compose) isEqualTo [["Money_100", 3], ["Money_50", 1], ["Money_20", 1], ["Money_Coins", 3]], "the fewest notes, largest first"] call TEST_fnc_assert;
private _pair = [["Note50", 50], ["Note20", 20]];
[([60, _pair] call PMCB_fnc_compose) isEqualTo [["Note20", 3]] && {([110, _pair] call PMCB_fnc_compose) isEqualTo [["Note50", 1], ["Note20", 3]]},
    "amounts greedy cannot pay (60 with 50/20) are still found"] call TEST_fnc_assert;
[([7, _notes] call PMCB_fnc_compose) isEqualTo [] && {([0, _notes] call PMCB_fnc_compose) isEqualTo []} && {([12.5, _notes] call PMCB_fnc_compose) isEqualTo []},
    "amounts the notes cannot make, zero and fractions give nothing"] call TEST_fnc_assert;
[([1000000, _notes] call PMCB_fnc_compose) isEqualTo [["Money_100", 10000]], "large amounts are fast"] call TEST_fnc_assert;

// --- ATMs ------------------------------------------------------------------------------
[TEST_atm getVariable ["PMCB_atm", false] && {count (["PMCB_fnc_atmInit"] call TEST_fnc_sent) == 0}, "an ATM is registered once"] call TEST_fnc_assert;
private _second = "Land_Atm_01_F" createVehicle [50, 0, 0];
[_second] call PMCB_fnc_registerAtm;
private _init = ["PMCB_fnc_atmInit"] call TEST_fnc_sent;
[count _init == 1 && {((_init select 0) select 0) isEqualTo [_second, true]} && {(((_init select 0) select 1) select 2) isEqualTo _second},
    "the ATM action goes to every client, joining players included"] call TEST_fnc_assert;
TEST_messages = [];
[_second, false] call PMCB_fnc_registerAtm;
[!(_second getVariable ["PMCB_atm", true]) && {(((["PMCB_fnc_atmInit"] call TEST_fnc_sent) select 0) select 0) isEqualTo [_second, false]},
    "an ATM can be turned back into an object; the JIP entry is replaced"] call TEST_fnc_assert;

// --- Opening the ATM -------------------------------------------------------------------
3 call TEST_fnc_as;
[TEST_player, TEST_atm] call PMCB_fnc_requestState;
private _state = 3 call TEST_fnc_lastState;
[_state isEqualTo [500, 0, false, false, [], [], "STR_PMCB_SET_GROUP_DEFAULT"], "first use opens a personal account with the starting balance"] call TEST_fnc_assert;
[(PMCB_accounts get "76561100000000001") isEqualTo [500, "Ivan"] && {3 in PMCB_viewers}, "the account keeps the player's name; the screen gets updates"] call TEST_fnc_assert;
TEST_messages = [];
TEST_other setPos [20, 0, 0];
5 call TEST_fnc_as;
[TEST_other, TEST_atm] call PMCB_fnc_requestState;
[count (["PMCB_fnc_notify", "STR_PMCB_ERR_FAR", 5] call TEST_fnc_sent) == 1 && {!("76561100000000002" in PMCB_accounts)}, "a player farther than 5 m is refused"] call TEST_fnc_assert;
TEST_messages = [];
[TEST_player, TEST_atm] call PMCB_fnc_requestState;
[TEST_messages isEqualTo [], "a client cannot act for another player's unit"] call TEST_fnc_assert;
TEST_other setPos [0, 2, 0];

// --- Withdrawals ----------------------------------------------------------------------------
TEST_messages = [];
3 call TEST_fnc_as;
[TEST_player, TEST_atm, "personal", [["Money_100", 3], ["money_50", 1], ["Money_20", 1], ["Money_Coins", 2]]] call PMCB_fnc_withdraw;
private _give = ["PMCB_fnc_give", nil, 3] call TEST_fnc_sent;
[("76561100000000001" call TEST_fnc_personal) == 120 && {count _give == 1} && {
    (((_give select 0) select 0) select 0) isEqualTo [["Money_100", 3], ["Money_50", 1], ["Money_20", 1], ["Money_Coins", 2]]},
    "380 is charged first, then exactly these notes are handed out"] call TEST_fnc_assert;
private _entry = PMCB_log select (count PMCB_log - 1);
[(_entry select [1, 9]) isEqualTo ["2026-10-29 09:05:07", "76561100000000001", "Ivan", "withdraw", 380, 120, "76561100000000001", "Ivan", "TestMission (Altis)"],
    "the withdrawal is journalled with time, account, amount, balance, who and mission"] call TEST_fnc_assert;
[((3 call TEST_fnc_lastState) select 0) == 120, "the screen gets the new balance"] call TEST_fnc_assert;
TEST_messages = [];
[TEST_player, TEST_atm, "personal", [["Money_100", 2]]] call PMCB_fnc_withdraw;
[count (["PMCB_fnc_notify", "STR_PMCB_ERR_FUNDS", 3] call TEST_fnc_sent) == 1 && {("76561100000000001" call TEST_fnc_personal) == 120} && {
    (["PMCB_fnc_give"] call TEST_fnc_sent) isEqualTo []}, "more than the balance is refused"] call TEST_fnc_assert;
{
    TEST_messages = [];
    [TEST_player, TEST_atm, "personal", _x] call PMCB_fnc_withdraw;
    [count (["PMCB_fnc_notify", "STR_PMCB_ERR_AMOUNT", 3] call TEST_fnc_sent) == 1, format ["a bad request is refused: %1", _x]] call TEST_fnc_assert;
} forEach [[], [["FirstAidKit", 1]], [["Money_20", 1.5]], [["Money_20", 0]], [["Money_20", -2]], [["Money_20", 1], ["bad"]]];
TEST_messages = [];
TEST_player setPos [20, 0, 0];
[TEST_player, TEST_atm, "personal", [["Money_20", 1]]] call PMCB_fnc_withdraw;
[count (["PMCB_fnc_notify", "STR_PMCB_ERR_FAR", 3] call TEST_fnc_sent) == 1 && {("76561100000000001" call TEST_fnc_personal) == 120}, "nothing is paid out away from the ATM"] call TEST_fnc_assert;
TEST_player setPos [2, 0, 0];
TEST_messages = [];
[TEST_player, TEST_atm, "group", [["Money_20", 1]]] call PMCB_fnc_withdraw;
[count (["PMCB_fnc_notify", "STR_PMCB_ERR_NOT_TREASURER", 3] call TEST_fnc_sent) == 1, "only treasurers withdraw from the group's account"] call TEST_fnc_assert;

// --- Handing out notes on the client ---------------------------------------------------------
TEST_hasInterface = true;
TEST_isRemoteExecuted = true;
TEST_remoteOwner = 2;
player setVariable ["TEST_inv", []];
player setVariable ["TEST_invMags", []];
player setVariable ["TEST_capacity", 4];
TEST_created = [];
[[["Money_100", 3], ["Money_Coins", 2]]] call PMCB_fnc_give;
private _ground = TEST_created select {(_x getVariable ["TEST_class", ""]) == "GroundWeaponHolder"};
[(player getVariable "TEST_inv") isEqualTo ["Money_100", "Money_100", "Money_100"] && {(player getVariable "TEST_invMags") isEqualTo ["Money_Coins"]} && {
    count _ground == 1} && {((_ground select 0) getVariable ["TEST_mags", []]) isEqualTo [["Money_Coins", 1]]},
    "notes go into the inventory as items or magazines; what does not fit is left on the ground"] call TEST_fnc_assert;
TEST_remoteOwner = 7;
player setVariable ["TEST_inv", []];
[[["Money_100", 1]]] call PMCB_fnc_give;
[(player getVariable "TEST_inv") isEqualTo [], "only the server can hand out notes"] call TEST_fnc_assert;
TEST_remoteOwner = 2;
TEST_messages = [];
player setVariable ["TEST_inv", ["Money_100", "Money_50", "FirstAidKit"]];
player setVariable ["TEST_invMags", ["Money_Coins"]];
[12, [["Money_100", 1], ["Money_Coins", 1]]] call PMCB_fnc_take;
[(player getVariable "TEST_inv") isEqualTo ["Money_50", "FirstAidKit"] && {(player getVariable "TEST_invMags") isEqualTo []} && {
    (((["PMCB_fnc_depositSettle", 12, 2] call TEST_fnc_sent) select 0) select 0) isEqualTo [12]},
    "for a deposit the client hands the notes over and reports back"] call TEST_fnc_assert;
TEST_hasInterface = false;

// --- Deposits ------------------------------------------------------------------------------------
TEST_player setVariable ["TEST_inv", ["Money_100", "Money_100", "FirstAidKit"]];
TEST_player setVariable ["TEST_invMags", ["Money_Coins", "Money_Coins", "Money_Coins"]];
TEST_messages = [];
3 call TEST_fnc_as;
[TEST_player, TEST_atm, "group", [["Money_100", 2], ["Money_Coins", 3]]] call PMCB_fnc_depositStart;
private _take = ["PMCB_fnc_take", nil, 3] call TEST_fnc_sent;
[count _take == 1 && {(((_take select 0) select 0) select 1) isEqualTo [["Money_100", 2], ["Money_Coins", 3]]} && {PMCB_group == 0},
    "a deposit asks the player's machine for the notes; nothing is credited yet"] call TEST_fnc_assert;
private _token = ((_take select 0) select 0) select 0;
TEST_messages = [];
[TEST_player, TEST_atm, "personal", [["Money_100", 1]]] call PMCB_fnc_depositStart;
[count (["PMCB_fnc_notify", "STR_PMCB_ERR_BUSY", 3] call TEST_fnc_sent) == 1, "one deposit at a time per player"] call TEST_fnc_assert;
TEST_player setVariable ["TEST_inv", ["FirstAidKit"]];
TEST_player setVariable ["TEST_invMags", []];
TEST_messages = [];
[_token + 1] call PMCB_fnc_depositSettle;
[PMCB_group == 0, "a report with the wrong token is ignored"] call TEST_fnc_assert;
5 call TEST_fnc_as;
[TEST_other, TEST_atm] call PMCB_fnc_requestState;
3 call TEST_fnc_as;
TEST_messages = [];
[_token] call PMCB_fnc_depositSettle;
[PMCB_group == 215 && {count (["PMCB_fnc_notify", "STR_PMCB_DONE_DEPOSIT", 3] call TEST_fnc_sent) == 1}, "notes that left the inventory are credited to the group"] call TEST_fnc_assert;
[((5 call TEST_fnc_lastState) select 1) == 215, "other open ATM screens see the group's new balance"] call TEST_fnc_assert;
// Claims the server cannot see are not credited.
TEST_player setVariable ["TEST_inv", ["Money_100", "Money_50"]];
[TEST_player, TEST_atm, "personal", [["Money_100", 1], ["Money_50", 1]]] call PMCB_fnc_depositStart;
_token = ((((["PMCB_fnc_take", nil, 3] call TEST_fnc_sent) select 0) select 0)) select 0;
TEST_player setVariable ["TEST_inv", ["Money_100"]];
TEST_messages = [];
private _t0 = TEST_realTime;
[_token] call PMCB_fnc_depositSettle;
[("76561100000000001" call TEST_fnc_personal) == 170 && {TEST_realTime - _t0 >= 5}, "only what really left the inventory is credited, after waiting for it"] call TEST_fnc_assert;
[TEST_player, TEST_atm, "personal", [["Money_100", 1]]] call PMCB_fnc_depositStart;
_token = ((((["PMCB_fnc_take", nil, 3] call TEST_fnc_sent) select 0) select 0)) select 0;
TEST_messages = [];
[_token] call PMCB_fnc_depositSettle;
[("76561100000000001" call TEST_fnc_personal) == 170 && {count (["PMCB_fnc_notify", "STR_PMCB_ERR_NOTHING", 3] call TEST_fnc_sent) == 1}, "notes still carried are not credited"] call TEST_fnc_assert;
// The inventory change reaches the server during the wait.
[TEST_player, TEST_atm, "personal", [["Money_100", 1]]] call PMCB_fnc_depositStart;
_token = ((((["PMCB_fnc_take", nil, 3] call TEST_fnc_sent) select 0) select 0)) select 0;
TEST_onSleep = {TEST_player setVariable ["TEST_inv", []]};
[_token] call PMCB_fnc_depositSettle;
TEST_onSleep = {};
[("76561100000000001" call TEST_fnc_personal) == 270, "a removal that syncs late is credited"] call TEST_fnc_assert;
TEST_messages = [];
[TEST_player, TEST_atm, "personal", [["Money_100", 1]]] call PMCB_fnc_depositStart;
[count (["PMCB_fnc_notify", "STR_PMCB_ERR_NOT_CARRIED", 3] call TEST_fnc_sent) == 1, "notes the player does not carry cannot be paid in"] call TEST_fnc_assert;

// --- Zeus -----------------------------------------------------------------------------------------
TEST_messages = [];
3 call TEST_fnc_as;
[TEST_player, 1000] call PMCB_fnc_zeusAdjust;
[PMCB_group == 215 && {TEST_messages isEqualTo []}, "only a Zeus can create money"] call TEST_fnc_assert;
4 call TEST_fnc_as;
[TEST_zeus, 1000] call PMCB_fnc_zeusAdjust;
[PMCB_group == 1215 && {count (["PMCB_fnc_notify", "STR_PMCB_DONE_ZEUS_ADD", 4] call TEST_fnc_sent) == 1}, "Zeus adds to the group's account from nothing"] call TEST_fnc_assert;
TEST_messages = [];
[TEST_zeus, -5000] call PMCB_fnc_zeusAdjust;
[PMCB_group == 1215 && {count (["PMCB_fnc_notify", "STR_PMCB_ERR_GROUP_FUNDS", 4] call TEST_fnc_sent) == 1}, "Zeus cannot remove more than the balance"] call TEST_fnc_assert;
[TEST_zeus, -215] call PMCB_fnc_zeusAdjust;
[TEST_zeus, 0.5] call PMCB_fnc_zeusAdjust;
[PMCB_group == 1000, "Zeus removes into nothing; fractions are refused"] call TEST_fnc_assert;
TEST_messages = [];
[TEST_zeus, TEST_player] call PMCB_fnc_zeusTreasurer;
["76561100000000001" in PMCB_treasurers && {count (["PMCB_fnc_notify", "STR_PMCB_DONE_TREASURER_ADD"] call TEST_fnc_sent) == 2} && {
    ((3 call TEST_fnc_lastState) select 2)}, "Zeus appoints a treasurer; both are told and the ATM screen updates"] call TEST_fnc_assert;
3 call TEST_fnc_as;
TEST_messages = [];
[TEST_player, TEST_atm, "group", [["Money_100", 4]]] call PMCB_fnc_withdraw;
[PMCB_group == 600 && {count (["PMCB_fnc_give", nil, 3] call TEST_fnc_sent) == 1}, "a treasurer withdraws from the group's account"] call TEST_fnc_assert;
private _hist = 3 call TEST_fnc_lastState;
[((_hist select 5) apply {_x select 1}) isEqualTo ["withdraw", "deposit"] && {((_hist select 4) apply {_x select 1}) isEqualTo ["deposit", "deposit", "withdraw"]},
    "players see deposits and withdrawals, newest first, never Zeus operations"] call TEST_fnc_assert;
4 call TEST_fnc_as;
[TEST_zeus, TEST_player] call PMCB_fnc_zeusTreasurer;
[!("76561100000000001" in PMCB_treasurers), "the same module takes the right away again"] call TEST_fnc_assert;
TEST_messages = [];
private _crate = "Land_Atm_01_F" createVehicle [10, 10, 0];
[TEST_zeus, _crate] call PMCB_fnc_zeusTreasurer;
private _ai = [2, "76561100000000077", "Bot", [3, 3, 0]] call TEST_fnc_unit;
_ai setVariable ["TEST_player", false];
[TEST_zeus, _ai] call PMCB_fnc_zeusTreasurer;
[count (["PMCB_fnc_notify", "STR_PMCB_ERR_NOT_PLAYER", 4] call TEST_fnc_sent) == 2 && {!("76561100000000077" in PMCB_treasurers)}, "a treasurer must be a player"] call TEST_fnc_assert;
[TEST_zeus, _crate] call PMCB_fnc_zeusAtm;
[_crate getVariable ["PMCB_atm", false], "Zeus makes an object an ATM"] call TEST_fnc_assert;
[TEST_zeus, _crate] call PMCB_fnc_zeusAtm;
[!(_crate getVariable ["PMCB_atm", true]), "and turns it back"] call TEST_fnc_assert;
TEST_messages = [];
[TEST_zeus, TEST_other] call PMCB_fnc_zeusAtm;
[count (["PMCB_fnc_notify", "STR_PMCB_ERR_NO_OBJECT", 4] call TEST_fnc_sent) == 1 && {!(TEST_other getVariable ["PMCB_atm", false])}, "a unit is not made an ATM"] call TEST_fnc_assert;
TEST_messages = [];
[TEST_zeus] call PMCB_fnc_zeusLog;
private _journal = ((["PMCB_fnc_receiveLog", nil, 4] call TEST_fnc_sent) select 0) select 0;
_journal = _journal select 0;
[count _journal == count PMCB_log && {((_journal select 0) select 0) == PMCB_seq} && {
    ((_journal apply {_x select 4}) arrayIntersect ["zeus_add", "zeus_remove", "treasurer_add", "treasurer_remove"]) isEqualTo ["treasurer_remove", "treasurer_add", "zeus_remove", "zeus_add"]},
    "Zeus gets the whole journal, newest first, with Zeus operations"] call TEST_fnc_assert;
TEST_messages = [];
3 call TEST_fnc_as;
[TEST_player] call PMCB_fnc_zeusLog;
[TEST_messages isEqualTo [], "players cannot read the journal"] call TEST_fnc_assert;

// --- Export (Zeus client) ------------------------------------------------------------------------
TEST_hasInterface = true;
TEST_isRemoteExecuted = false;
private _text = [[_journal select 0, _journal select 1]] call PMCB_fnc_export;
private _lines = _text splitString toString [13, 10];
[count _lines == 3 && {(_lines select 0) == "STR_PMCB_EXPORT_HEADER"} && {TEST_clipboard isEqualTo _text} && {
    ((_lines select 1) splitString ";") select 0 == str PMCB_seq}, "export: a header and one line per operation, copied to the clipboard"] call TEST_fnc_assert;
TEST_hasInterface = false;

// --- Window updates (client side) -----------------------------------------------------------------
TEST_hasInterface = true;
TEST_isRemoteExecuted = true;
TEST_remoteOwner = 2;
PMCB_ui = createHashMapFromArray [["screen", "loading"], ["state", []]];
[[1, 2, false, false, [], [], "G"]] call PMCB_fnc_receive;
[(PMCB_ui get "screen") == "main" && {(PMCB_ui get "state") isEqualTo [1, 2, false, false, [], [], "G"]}, "the window shows the balances once they arrive"] call TEST_fnc_assert;
TEST_remoteOwner = 9;
[[9, 9, true, true, [], [], "X"]] call PMCB_fnc_receive;
[((PMCB_ui get "state") select 0) == 1, "only the server updates the window"] call TEST_fnc_assert;
TEST_remoteOwner = 2;
PMCB_ui = nil;
TEST_dialogs = [];
[[[1]]] call PMCB_fnc_receiveLog;
[TEST_dialogs isEqualTo ["PMCB_RscATM"] && {(PMCB_ui get "screen") == "zeus"}, "the journal opens a window of its own from the Zeus module"] call TEST_fnc_assert;
PMCB_ui = nil;
TEST_dialogs = [];
private _logic = "Logic" createVehicle [0, 0, 0];
[_logic, [], true] call PMCB_fnc_moduleZeusAdd;
[TEST_dialogs isEqualTo ["PMCB_RscAmount"] && {PMCB_amountSign == 1} && {isNull _logic}, "the add module asks Zeus for the amount"] call TEST_fnc_assert;
TEST_isRemoteExecuted = false;
TEST_hasInterface = false;

// --- Journal size and persistence ---------------------------------------------------------------
PMCB_logLimit = 5;
4 call TEST_fnc_as;
for "_i" from 1 to 4 do {[TEST_zeus, 10] call PMCB_fnc_zeusAdjust};
[count PMCB_log == 5 && {((PMCB_log select 4) select 0) == PMCB_seq} && {((PMCB_log select 0) select 0) == PMCB_seq - 4}, "the journal keeps the newest entries up to its size"] call TEST_fnc_assert;
PMCB_logLimit = 2000;
TEST_profilesSaved = 0;
[call PMCB_fnc_save && {TEST_profilesSaved == 1} && {!PMCB_dirty}, "save writes the profile"] call TEST_fnc_assert;
private _before = [PMCB_group, PMCB_accounts get "76561100000000001", +PMCB_log, PMCB_seq];
PMCB_accounts = nil;
PMCB_treasurers = nil;
4 call TEST_fnc_as;
call PMCB_fnc_serverLoad;
[[PMCB_group, PMCB_accounts get "76561100000000001", PMCB_log, PMCB_seq] isEqualTo _before, "balances and the journal survive a restart"] call TEST_fnc_assert;
[TEST_zeus, TEST_other] call PMCB_fnc_zeusTreasurer;
call PMCB_fnc_save;
PMCB_accounts = nil;
call PMCB_fnc_serverLoad;
["76561100000000002" in PMCB_treasurers, "treasurers survive a restart"] call TEST_fnc_assert;
private _bad = [1, 100, [["uid", -5, "x"]], [], [], 0];
profileNamespace setVariable ["PMCB_bank_v1", _bad];
PMCB_accounts = nil;
call PMCB_fnc_serverLoad;
[PMCB_saveBlocked && {count PMCB_accounts == 0} && {!(call PMCB_fnc_save)} && {(profileNamespace getVariable "PMCB_bank_v1") isEqualTo _bad},
    "damaged data is not loaded and never overwritten"] call TEST_fnc_assert;
profileNamespace setVariable ["PMCB_bank_v1", nil];

// --- Server init, disconnects, Eden module ---------------------------------------------------------
call TEST_fnc_fresh;
TEST_missionHandlers = [];
TEST_deferSpawn = true;
call PMCB_fnc_serverInit;
TEST_deferSpawn = false;
[count TEST_missionHandlers == 2 && {count TEST_deferred == 1}, "server init installs disconnect and end handlers and the save loop"] call TEST_fnc_assert;
TEST_deferred = [];
3 call TEST_fnc_as;
[TEST_player, TEST_atm] call PMCB_fnc_requestState;
TEST_player setVariable ["TEST_inv", ["Money_20"]];
[TEST_player, TEST_atm, "personal", [["Money_20", 1]]] call PMCB_fnc_depositStart;
[0, "uid", "name", false, 3] call (((TEST_missionHandlers select {(_x select 0) == "PlayerDisconnected"}) select 0) select 1);
[!(3 in PMCB_viewers) && {!(3 in PMCB_pending)}, "a leaving player's screen and pending deposit are dropped"] call TEST_fnc_assert;
5 call TEST_fnc_as;
[TEST_other, TEST_atm] call PMCB_fnc_requestState;
[] call PMCB_fnc_closed;
[!(5 in PMCB_viewers), "a closed screen gets no more updates"] call TEST_fnc_assert;
private _module = "Logic" createVehicle [0, 0, 0];
_module setVariable ["TEST_class", "Logic"];
private _atmA = "Land_Atm_01_F" createVehicle [30, 0, 0];
_atmA setVariable ["TEST_class", "Land_Atm_01_F"];
_module setVariable ["TEST_synced", [_atmA, TEST_other, _module]];
[_module, [], true] call PMCB_fnc_moduleAtm;
[_atmA getVariable ["PMCB_atm", false] && {!(TEST_other getVariable ["PMCB_atm", false])}, "objects synchronised with the Eden module become ATMs; units do not"] call TEST_fnc_assert;

diag_log format ["TEST_COMPLETE: %1 assertions", TEST_count];

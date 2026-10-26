// Upgrade an existing phone-era base, without charging or changing its cargo.
call TEST_fnc_reset;
["p1","alspmc_pmc"] call ALS_fnc_licGrant;
[player,"h_100_100"] call ALSPMC_fnc_buyBase;
private _wallet = ["p1"] call ALS_fnc_moneyGet;
private _cargo = ALS_biz get "h_100_100";
call ALSPMC_fnc_terminalInit;
private _station = ALSPMC_terminals get "h_100_100";
private _computer = _station select 0;
private _objects = +(_station select 1);
[!isNull _computer && {count _objects == 4}, "old base receives one complete desktop workspace"] call TEST_fnc_assert;
[(count ALSPMC_terminalsPublic) == 1, "workspace published for clients and JIP"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo _wallet, "old base computer is free"] call TEST_fnc_assert;
[(ALS_biz get "h_100_100") isEqualTo _cargo, "computer installation preserves native warehouse cargo"] call TEST_fnc_assert;
[(count ALS_furniture) == 0, "free workspace is not native furniture for resale"] call TEST_fnc_assert;
[(["h_100_100"] call ALSPMC_fnc_terminalEnsure) == _computer && {((ALSPMC_terminals get "h_100_100") select 1) isEqualTo _objects}, "repeated ensure cannot duplicate a computer"] call TEST_fnc_assert;
[isNull (["h_110_100"] call ALSPMC_fnc_terminalEnsure), "ordinary property does not receive a PMC workstation"] call TEST_fnc_assert;
[[player,_computer] call ALSPMC_fnc_terminalCanUse, "nearby founder can use registered computer"] call TEST_fnc_assert;

// A physical terminal must not introduce a second set of data or commands.
[[player,"name","Рубеж ПК" call TEST_fnc_bytes,101,_computer] call ALSPMC_fnc_desktopDo, "desktop renames through the original phone controller"] call TEST_fnc_assert;
private _desktop = player getVariable "ALSPMC_desktopState";
private _phone = player getVariable "ALSPMC_phoneState";
[(_desktop get "name") isEqualTo (_phone get "name") && {(_desktop get "name") isEqualTo ("Рубеж ПК" call TEST_fnc_bytes)}, "desktop and phone share exact Cyrillic PMC name"] call TEST_fnc_assert;
[(_desktop get "valid") && {(_desktop get "terminalKey") == "h_100_100"} && {(_desktop get "reply") == 101}, "desktop reply includes terminal authorization and transaction acknowledgement"] call TEST_fnc_assert;
[[player,"lock","h_100_100",102,_computer] call ALSPMC_fnc_desktopDo, "desktop uses native door locking"] call TEST_fnc_assert;
[[player,"unlock","h_100_100",103] call ALSPMC_fnc_phoneDo, "phone can unlock a door locked from the desktop"] call TEST_fnc_assert;
[player,"status","",0,_computer] call ALSPMC_fnc_desktopDo;
_desktop = player getVariable "ALSPMC_desktopState";
[!(((_desktop get "bases") select 0) get "locked"), "next desktop refresh reflects phone change"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo _wallet, "desktop naming and door operations do not charge"] call TEST_fnc_assert;

// Public object tags alone must not authorize a client-supplied terminal.
private _fake = "Land_PCSet_01_screen_F" createVehicle [100,100,0];
_fake setVariable ["ALSPMC_terminalKey","h_100_100"];
[!([player,"name","Подмена" call TEST_fnc_bytes,104,_fake] call ALSPMC_fnc_desktopDo), "forged screen cannot submit desktop commands"] call TEST_fnc_assert;
deleteVehicle _fake;
player setPos [120,100,0];
[!([player,"name","Далеко" call TEST_fnc_bytes,105,_computer] call ALSPMC_fnc_desktopDo), "desktop commands require physical proximity"] call TEST_fnc_assert;
player setPos [100,100,0];
player setVariable ["ALS_uid","p2"];
[!([player,"lock","h_100_100",106,_computer] call ALSPMC_fnc_desktopDo), "unrelated visitor cannot manage a base computer"] call TEST_fnc_assert;
player setVariable ["ALS_uid","p1"];
TEST_isRemoteExecuted = true;
TEST_remoteOwner = 7;
[!([player,"name","Чужой" call TEST_fnc_bytes,107,_computer] call ALSPMC_fnc_desktopDo), "remote caller cannot operate another player's computer session"] call TEST_fnc_assert;
TEST_isRemoteExecuted = false;
[(ALSPMC_names get "p1") isEqualTo ("Рубеж ПК" call TEST_fnc_bytes), "rejected desktop requests cannot change company name"] call TEST_fnc_assert;

// Native company permissions are reused on the server and client.
ALS_companies set ["co_1",createHashMapFromArray [["members",["p1","p2"]]]];
ALS_owned set ["h_100_100","co_1"];
call ALS_fnc_housePublish;
player setVariable ["ALS_uid","p2"];
player setVariable ["ALS_company","co_1"];
[[player,_computer] call ALSPMC_fnc_terminalCanUse, "native company member can use company base computer"] call TEST_fnc_assert;
TEST_isServer = false;
[[player,_computer] call ALSPMC_fnc_terminalCanUse, "client action uses native company ownership mirror"] call TEST_fnc_assert;
player setVariable ["ALS_company","-"];
[!([player,_computer] call ALSPMC_fnc_terminalCanUse), "client hides computer action from unrelated player"] call TEST_fnc_assert;
TEST_isServer = true;
player setVariable ["ALS_uid","p1"];
ALS_owned set ["h_100_100","p1"];

// Restoring saved layouts does not generate a second station or charge money.
private _savedLayout = ["alspmc_workstations_v1",[]] call ALS_fnc_dbGet;
{deleteVehicle _x} forEach _objects;
call ALSPMC_fnc_terminalInit;
_station = ALSPMC_terminals get "h_100_100";
_computer = _station select 0;
_objects = +(_station select 1);
[!isNull _computer && {count ALSPMC_terminals == 1}, "restart restores exactly one station"] call TEST_fnc_assert;
[["alspmc_workstations_v1",[]] call ALS_fnc_dbGet isEqualTo _savedLayout, "station restores original saved position and direction"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo _wallet, "restoring computer does not charge"] call TEST_fnc_assert;
deleteVehicle (_objects select 0);
["h_100_100"] call ALSPMC_fnc_terminalEnsure;
[(_objects findIf {!isNull _x}) < 0, "repair removes all remaining pieces of incomplete station"] call TEST_fnc_assert;
_station = ALSPMC_terminals get "h_100_100";
_computer = _station select 0;
_objects = +(_station select 1);
[(count _objects) == 4 && {(_objects findIf {isNull _x}) < 0}, "partial deletion reconstructs complete station"] call TEST_fnc_assert;
ALSPMC_terminalRetry set ["h_100_100",-1];
deleteVehicle _computer;
call ALSPMC_fnc_terminalSync;
_station = ALSPMC_terminals get "h_100_100";
_computer = _station select 0;
[!isNull _computer, "periodic reconciliation repairs deleted screen"] call TEST_fnc_assert;

// Native sale removes workspace and its layout, but keeps the name.
_objects = +(_station select 1);
ALSPMC_nativeHouseSell = TEST_nativeSell;
ALS_fnc_houseSell = {_this call ALSPMC_fnc_sellHouse};
[[player,"sell","h_100_100",108,_computer] call ALSPMC_fnc_desktopDo, "base sale works through desktop and native sale wrapper"] call TEST_fnc_assert;
[(_objects findIf {!isNull _x}) < 0 && {count ALSPMC_terminals == 0}, "sale removes physical workspace"] call TEST_fnc_assert;
[["alspmc_workstations_v1",[]] call ALS_fnc_dbGet isEqualTo [], "sale removes saved workspace layout"] call TEST_fnc_assert;
[!((player getVariable "ALSPMC_desktopState") get "valid"), "selling the active computer invalidates desktop session"] call TEST_fnc_assert;
[(ALSPMC_names get "p1") isEqualTo ("Рубеж ПК" call TEST_fnc_bytes), "desktop sale preserves PMC name"] call TEST_fnc_assert;

// New purchases also receive the computer without a second charge.
[[player,"h_110_100"] call ALSPMC_fnc_buyBase, "new base purchase succeeds with workstation enabled"] call TEST_fnc_assert;
["h_110_100" in ALSPMC_terminals, "new base immediately receives computer"] call TEST_fnc_assert;
_objects = +((ALSPMC_terminals get "h_110_100") select 1);
ALS_owned deleteAt "h_110_100";
call ALSPMC_fnc_reconcile;
[(_objects findIf {!isNull _x}) < 0 && {count ALSPMC_workstations == 0}, "external ownership removal clears computer and layout"] call TEST_fnc_assert;

call TEST_fnc_reset;
private _badLayout = [["h_100_100",[[100,100],0]]];
["alspmc_workstations_v1",_badLayout] call ALS_fnc_dbSet;
call ALSPMC_fnc_terminalInit;
[!ALSPMC_workstationsReady && {ALSPMC_ready}, "corrupt workspace layout disables spawning while phone remains ready"] call TEST_fnc_assert;
["alspmc_workstations_v1",[]] call ALS_fnc_dbSet;
[["alspmc_workstations_v1",[]] call ALS_fnc_dbGet isEqualTo _badLayout, "corrupt workspace layout is preserved by native DB guard"] call TEST_fnc_assert;

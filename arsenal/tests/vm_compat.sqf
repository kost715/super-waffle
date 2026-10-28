// SQF-VM lacks the inventory, network and scheduler commands the arsenal uses.
// Compiled opcodes are adapted to the fixtures below; application code is unchanged.
TEST_isServer = true;
TEST_isRemoteExecuted = false;
TEST_remoteOwner = 2;
TEST_messages = [];
TEST_missionHandlers = [];
TEST_profilesSaved = 0;
TEST_realTime = 1000;
TEST_canSuspend = false;
TEST_sleeps = 0;
TEST_onSleep = {};
TEST_deferSpawn = false;
TEST_deferred = [];

TEST_fnc_getDefault = {
    params ["_compatMap", "_compatArgs"];
    if !((_compatArgs select 0) in _compatMap) exitWith {_compatArgs select 1};
    _compatMap get (_compatArgs select 0)
};
TEST_fnc_setVariable = {
    params ["_compatTarget", "_compatArgs"];
    _compatTarget setVariable (_compatArgs select [0, 2]);
};
// VM keeps a nil-valued key after setVariable [name, nil]; Arma removes it.
TEST_fnc_getVariable = {
    params ["_compatTarget", "_compatArgs"];
    if (_compatArgs isEqualType "") exitWith {_compatTarget getVariable _compatArgs};
    private _compatValue = _compatTarget getVariable _compatArgs;
    if (isNil "_compatValue") exitWith {_compatArgs select 1};
    _compatValue
};
TEST_fnc_toPairs = {
    params ["_compatMap", "_compatOption"];
    (keys _compatMap) apply {[_x, _compatMap get _x]}
};
TEST_fnc_values = {private _compatMap = _this; (keys _compatMap) apply {_compatMap get _x}};
TEST_fnc_forEach = {
    params ["_compatCode", "_compatCollection"];
    if (_compatCollection isEqualType []) exitWith {_compatCode forEach _compatCollection};
    {
        private _compatKey = _x;
        private _compatValue = _compatCollection get _compatKey;
        private _x = _compatKey;
        private _y = _compatValue;
        call _compatCode;
    } forEach (keys _compatCollection);
};
TEST_fnc_remote = {TEST_messages pushBack +_this; 0};
TEST_fnc_owner = {_this getVariable ["TEST_owner", 2]};
TEST_fnc_typeOf = {_this getVariable ["TEST_class", ""]};
TEST_fnc_isKindOf = {
    params ["_compatLeft", "_compatRight"];
    private _compatRoot = configFile >> "CfgVehicles";
    private _compatParent = _compatRight;
    if (_compatRight isEqualType []) then {_compatParent = _compatRight select 0; _compatRoot = _compatRight select 1};
    private _compatClass = if (_compatLeft isEqualType objNull) then {_compatLeft getVariable ["TEST_class", ""]} else {_compatLeft};
    if (_compatClass == "") exitWith {false};
    private _compatCfg = _compatRoot >> _compatClass;
    private _compatFound = false;
    while {isClass _compatCfg && {!_compatFound}} do {
        _compatFound = (toLower configName _compatCfg) == toLower _compatParent;
        _compatCfg = inheritsFrom _compatCfg;
    };
    _compatFound
};
// VM's isNil {code} loses its stack when the code ends after a skipped exitWith.
TEST_fnc_isNil = {
    if (_this isEqualType {}) exitWith {private _compatResult = call _this; isNil "_compatResult"};
    isNil _this
};
TEST_fnc_noParent = {_this getVariable ["TEST_parent", objNull]};
TEST_fnc_missionHandler = {TEST_missionHandlers pushBack _this; count TEST_missionHandlers - 1};
// Scheduler: spawned code runs at once with canSuspend true; sleep advances the
// clock and runs TEST_onSleep, which tests use to deliver late inventory updates.
TEST_fnc_spawn = {
    params ["_compatArgs", "_compatCode"];
    if (TEST_deferSpawn) exitWith {TEST_deferred pushBack [_compatArgs, _compatCode]; scriptNull};
    private _compatWas = TEST_canSuspend;
    TEST_canSuspend = true;
    _compatArgs call _compatCode;
    TEST_canSuspend = _compatWas;
    scriptNull
};
TEST_fnc_sleep = {
    TEST_realTime = TEST_realTime + _this;
    TEST_sleeps = TEST_sleeps + 1;
    call TEST_onSleep;
};
// Unit inventory: the loadout array itself. Container inventory: magazines
// [[class, rounds]...], items/backpacks [[class, count]...], weapons in the
// weaponsItemsCargo format, and nested [class, object] containers.
TEST_fnc_getLoadout = {+(_this getVariable ["TEST_loadout", [[],[],[],[],[],[],"","",[],["","","","","",""]]])};
TEST_fnc_magsAmmo = {+(_this getVariable ["TEST_mags", []])};
TEST_fnc_pairsCargo = {
    params ["_compatObject", "_compatVar"];
    private _compatPairs = _compatObject getVariable [_compatVar, []];
    [_compatPairs apply {_x select 0}, _compatPairs apply {_x select 1}]
};
TEST_fnc_itemCargo = {[_this, "TEST_items"] call TEST_fnc_pairsCargo};
TEST_fnc_backpackCargo = {[_this, "TEST_packs"] call TEST_fnc_pairsCargo};
TEST_fnc_weaponsCargo = {+(_this getVariable ["TEST_weapons", []])};
TEST_fnc_containers = {+(_this getVariable ["TEST_containers", []])};
TEST_fnc_clearMags = {_this setVariable ["TEST_mags", []]};
TEST_fnc_clearItems = {_this setVariable ["TEST_items", []]; _this setVariable ["TEST_containers", []]};
TEST_fnc_clearWeapons = {_this setVariable ["TEST_weapons", []]};
TEST_fnc_clearPacks = {_this setVariable ["TEST_packs", []]; _this setVariable ["TEST_containers", []]};
TEST_fnc_addPairs = {
    params ["_compatObject", "_compatVar", "_compatClass", "_compatCount"];
    private _compatPairs = _compatObject getVariable [_compatVar, []];
    private _compatAt = _compatPairs findIf {(_x select 0) == _compatClass};
    if (_compatAt < 0) then {_compatPairs pushBack [_compatClass, _compatCount]} else {
        (_compatPairs select _compatAt) set [1, ((_compatPairs select _compatAt) select 1) + _compatCount];
    };
    _compatObject setVariable [_compatVar, _compatPairs];
};
TEST_fnc_addItemCargo = {[_this select 0, "TEST_items", (_this select 1) select 0, (_this select 1) select 1] call TEST_fnc_addPairs};
TEST_fnc_addPackCargo = {[_this select 0, "TEST_packs", (_this select 1) select 0, (_this select 1) select 1] call TEST_fnc_addPairs};
TEST_fnc_addWeaponCargo = {
    params ["_compatObject", "_compatSpec"];
    private _compatWeapons = _compatObject getVariable ["TEST_weapons", []];
    for "_compatI" from 1 to (_compatSpec select 1) do {_compatWeapons pushBack [_compatSpec select 0, "", "", "", [], [], ""]};
    _compatObject setVariable ["TEST_weapons", _compatWeapons];
};
TEST_fnc_addMagAmmo = {
    params ["_compatObject", "_compatSpec"];
    private _compatMags = _compatObject getVariable ["TEST_mags", []];
    for "_compatI" from 1 to (_compatSpec select 1) do {_compatMags pushBack [_compatSpec select 0, _compatSpec select 2]};
    _compatObject setVariable ["TEST_mags", _compatMags];
};
TEST_fnc_lockInventory = {(_this select 0) setVariable ["TEST_locked", _this select 1]};
TEST_fnc_lockedInventory = {_this getVariable ["TEST_locked", false]};

TEST_fnc_compatCode = {
    private _compatOut = [];
    {
        private _compatLine = _x;
        if ((_compatLine select [0, 6]) == "PUSH {") then {
            private _compatNested = call compile (_compatLine select [5]);
            _compatLine = "PUSH " + str (_compatNested call TEST_fnc_compatCode);
        };
        private _compatCall = {_compatOut append ["GETVARIABLE " + _this, "CALLBINARY call"]};
        private _compatPair = {_compatOut append ["MAKEARRAY 2", "GETVARIABLE " + _this, "CALLBINARY call"]};
        switch (_compatLine) do {
            case "CALLNULAR isserver": {_compatOut pushBack "GETVARIABLE TEST_isServer"};
            case "CALLNULAR hasinterface": {_compatOut pushBack "PUSH false"};
            case "CALLNULAR isremoteexecuted": {_compatOut pushBack "GETVARIABLE TEST_isRemoteExecuted"};
            case "CALLNULAR remoteexecutedowner": {_compatOut pushBack "GETVARIABLE TEST_remoteOwner"};
            case "CALLNULAR clientowner": {_compatOut pushBack "PUSH 2"};
            case "CALLNULAR cansuspend": {_compatOut pushBack "GETVARIABLE TEST_canSuspend"};
            case "CALLNULAR diag_ticktime": {_compatOut pushBack "GETVARIABLE TEST_realTime"};
            case "CALLNULAR saveprofilenamespace": {_compatOut append ["GETVARIABLE TEST_profilesSaved", "PUSH 1", "CALLBINARY +", "ASSIGNTO TEST_profilesSaved"]};
            case "CALLBINARY getordefault": {"TEST_fnc_getDefault" call _compatPair};
            case "CALLBINARY toarray": {"TEST_fnc_toPairs" call _compatPair};
            case "CALLBINARY setvariable": {"TEST_fnc_setVariable" call _compatPair};
            case "CALLBINARY getvariable": {"TEST_fnc_getVariable" call _compatPair};
            case "CALLBINARY foreach": {"TEST_fnc_forEach" call _compatPair};
            case "CALLBINARY remoteexec";
            case "CALLBINARY remoteexeccall": {"TEST_fnc_remote" call _compatPair};
            case "CALLBINARY iskindof": {"TEST_fnc_isKindOf" call _compatPair};
            case "CALLBINARY spawn": {"TEST_fnc_spawn" call _compatPair};
            case "CALLBINARY lockinventory": {"TEST_fnc_lockInventory" call _compatPair};
            case "CALLBINARY additemcargoglobal": {"TEST_fnc_addItemCargo" call _compatPair};
            case "CALLBINARY addbackpackcargoglobal": {"TEST_fnc_addPackCargo" call _compatPair};
            case "CALLBINARY addweaponcargoglobal": {"TEST_fnc_addWeaponCargo" call _compatPair};
            case "CALLBINARY addmagazineammocargo": {"TEST_fnc_addMagAmmo" call _compatPair};
            case "CALLUNARY isnil": {"TEST_fnc_isNil" call _compatCall};
            case "CALLUNARY values": {"TEST_fnc_values" call _compatCall};
            case "CALLUNARY owner": {"TEST_fnc_owner" call _compatCall};
            case "CALLUNARY typeof": {"TEST_fnc_typeOf" call _compatCall};
            case "CALLUNARY objectparent": {"TEST_fnc_noParent" call _compatCall};
            case "CALLUNARY addmissioneventhandler": {"TEST_fnc_missionHandler" call _compatCall};
            case "CALLUNARY sleep": {"TEST_fnc_sleep" call _compatCall};
            case "CALLUNARY getunitloadout": {"TEST_fnc_getLoadout" call _compatCall};
            case "CALLUNARY magazinesammocargo": {"TEST_fnc_magsAmmo" call _compatCall};
            case "CALLUNARY getitemcargo": {"TEST_fnc_itemCargo" call _compatCall};
            case "CALLUNARY getbackpackcargo": {"TEST_fnc_backpackCargo" call _compatCall};
            case "CALLUNARY weaponsitemscargo": {"TEST_fnc_weaponsCargo" call _compatCall};
            case "CALLUNARY everycontainer": {"TEST_fnc_containers" call _compatCall};
            case "CALLUNARY clearmagazinecargoglobal": {"TEST_fnc_clearMags" call _compatCall};
            case "CALLUNARY clearitemcargoglobal": {"TEST_fnc_clearItems" call _compatCall};
            case "CALLUNARY clearweaponcargoglobal": {"TEST_fnc_clearWeapons" call _compatCall};
            case "CALLUNARY clearbackpackcargoglobal": {"TEST_fnc_clearPacks" call _compatCall};
            case "CALLUNARY lockedinventory": {"TEST_fnc_lockedInventory" call _compatCall};
            case "CALLUNARY toloweransi": {_compatOut pushBack "CALLUNARY tolower"};
            default {_compatOut pushBack _compatLine};
        };
    } forEach (assembly__ _this);
    // VM's assembler expects quoted identifiers although assembly__ omits them.
    _compatOut = _compatOut apply {
        private _space = _x find " ";
        private _op = if (_space < 0) then {_x} else {_x select [0, _space]};
        if (_op in ["GETVARIABLE", "ASSIGNTO", "ASSIGNTOLOCAL"]) then {
            _op + " " + str (_x select [_space + 1])
        } else {_x}
    };
    fromAssembly__ _compatOut
};
TEST_fnc_load = {(compile preprocessFileLineNumbers _this) call TEST_fnc_compatCode};

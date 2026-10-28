// SQF-VM lacks the UI, network and scheduler commands the interactions use.
// Compiled opcodes are adapted to the fixtures below; application code is unchanged.
TEST_isServer = true;
TEST_hasInterface = false;
TEST_systemTime = [2026, 10, 29, 9, 5, 7, 0];
TEST_clipboard = "";
TEST_dialogs = [];
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
// SQF-VM's inheritsFrom returns the enclosing class, not the parent, so fixture
// classes list their kinds in TEST_kinds[] (inherited by subclasses).
TEST_fnc_isKindOf = {
    params ["_compatLeft", "_compatRight"];
    private _compatRoot = configFile >> "CfgVehicles";
    private _compatParent = _compatRight;
    if (_compatRight isEqualType []) then {_compatParent = _compatRight select 0; _compatRoot = _compatRight select 1};
    private _compatClass = if (_compatLeft isEqualType objNull) then {_compatLeft getVariable ["TEST_class", ""]} else {_compatLeft};
    if (_compatClass == "" || {!isClass (_compatRoot >> _compatClass)}) exitWith {false};
    toLower _compatClass == toLower _compatParent || {
        (getArray (_compatRoot >> _compatClass >> "TEST_kinds")) findIf {toLower _x == toLower _compatParent} >= 0}
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
TEST_fnc_isPack = {getNumber (configFile >> "CfgVehicles" >> _this >> "isBackpack") == 1};
TEST_fnc_clearItems = {
    _this setVariable ["TEST_items", []];
    _this setVariable ["TEST_containers", (_this getVariable ["TEST_containers", []]) select {(_x select 0) call TEST_fnc_isPack}];
};
TEST_fnc_clearWeapons = {_this setVariable ["TEST_weapons", []]};
TEST_fnc_clearPacks = {
    _this setVariable ["TEST_packs", []];
    _this setVariable ["TEST_containers", (_this getVariable ["TEST_containers", []]) select {!((_x select 0) call TEST_fnc_isPack)}];
};
// Uniforms, vests and backpacks added to cargo become container objects of their own.
TEST_fnc_addContainers = {
    params ["_compatObject", "_compatClass", "_compatCount"];
    private _compatType = getNumber (configFile >> "CfgWeapons" >> _compatClass >> "ItemInfo" >> "type");
    if !(_compatType in [701, 801] || {_compatClass call TEST_fnc_isPack}) exitWith {};
    private _compatList = _compatObject getVariable ["TEST_containers", []];
    for "_compatI" from 1 to _compatCount do {
        private _compatNew = _compatClass createVehicle [0, 0, 0];
        _compatNew setVariable ["TEST_class", _compatClass];
        _compatList pushBack [_compatClass, _compatNew];
    };
    _compatObject setVariable ["TEST_containers", _compatList];
};
TEST_fnc_addPairs = {
    params ["_compatObject", "_compatVar", "_compatClass", "_compatCount"];
    private _compatPairs = _compatObject getVariable [_compatVar, []];
    private _compatAt = _compatPairs findIf {(_x select 0) == _compatClass};
    if (_compatAt < 0) then {_compatPairs pushBack [_compatClass, _compatCount]} else {
        (_compatPairs select _compatAt) set [1, ((_compatPairs select _compatAt) select 1) + _compatCount];
    };
    _compatObject setVariable [_compatVar, _compatPairs];
};
TEST_fnc_addItemCargo = {
    [_this select 0, "TEST_items", (_this select 1) select 0, (_this select 1) select 1] call TEST_fnc_addPairs;
    [_this select 0, (_this select 1) select 0, (_this select 1) select 1] call TEST_fnc_addContainers;
};
TEST_fnc_addPackCargo = {
    [_this select 0, "TEST_packs", (_this select 1) select 0, (_this select 1) select 1] call TEST_fnc_addPairs;
    [_this select 0, (_this select 1) select 0, (_this select 1) select 1] call TEST_fnc_addContainers;
};
TEST_fnc_addWeaponItems = {
    params ["_compatObject", "_compatSpec"];
    private _compatWeapons = _compatObject getVariable ["TEST_weapons", []];
    for "_compatI" from 1 to (_compatSpec select 1) do {_compatWeapons pushBack +(_compatSpec select 0)};
    _compatObject setVariable ["TEST_weapons", _compatWeapons];
};
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
// Units: side via TEST_side (group is the unit itself); Zeus, locality and Eden sync via variables.
TEST_fnc_identity = {_this};
TEST_fnc_side = {_this getVariable ["TEST_side", west]};
TEST_fnc_local = {_this getVariable ["TEST_local", true]};
TEST_fnc_attachedTo = {_this getVariable ["TEST_attachedTo", objNull]};
TEST_fnc_synced = {_this getVariable ["TEST_synced", []]};
TEST_fnc_curator = {_this getVariable ["TEST_curator", objNull]};
// Files: TEST_files maps a path to its text; missing files read as "".
TEST_files = createHashMap;
TEST_filePatching = false;
TEST_parseFails = false;
// Arma reports reading a missing file as a script error; record any such read.
TEST_missingReads = [];
TEST_fnc_fileExists = {_this in TEST_files};
TEST_fnc_loadFile = {if (_this in TEST_files) then {TEST_files get _this} else {TEST_missingReads pushBack _this; ""}};
// Arma's parseSimpleArray takes plain data only: comments make it fail.
TEST_fnc_parseSimple = {
    if (TEST_parseFails || {_this == ""} || {(_this find (toString [47, 47])) >= 0}) exitWith {[]};
    call compile _this
};
// Players: UID, name and player flag via variables. Unit inventory: TEST_inv
// (item classes) and TEST_invMags (magazine classes), at most TEST_capacity pieces.
TEST_fnc_uid = {_this getVariable ["TEST_uid", ""]};
TEST_fnc_name = {_this getVariable ["TEST_name", "Unit"]};
TEST_fnc_isPlayer = {_this getVariable ["TEST_player", false]};
TEST_fnc_items = {+(_this getVariable ["TEST_inv", []])};
TEST_fnc_mags = {+(_this getVariable ["TEST_invMags", []])};
TEST_fnc_canAdd = {
    params ["_compatUnit"];
    count (_compatUnit getVariable ["TEST_inv", []]) + count (_compatUnit getVariable ["TEST_invMags", []]) < (_compatUnit getVariable ["TEST_capacity", 100])
};
TEST_fnc_invAdd = {
    params ["_compatUnit", "_compatClass", "_compatVar"];
    if !([_compatUnit] call TEST_fnc_canAdd) exitWith {};
    private _compatList = _compatUnit getVariable [_compatVar, []];
    _compatList pushBack _compatClass;
    _compatUnit setVariable [_compatVar, _compatList];
};
TEST_fnc_invRemove = {
    params ["_compatUnit", "_compatClass", "_compatVar"];
    private _compatList = _compatUnit getVariable [_compatVar, []];
    private _compatAt = _compatList findIf {toLower _x == toLower _compatClass};
    if (_compatAt >= 0) then {_compatList deleteAt _compatAt};
    _compatUnit setVariable [_compatVar, _compatList];
};
TEST_fnc_addItem = {[_this select 0, _this select 1, "TEST_inv"] call TEST_fnc_invAdd};
TEST_fnc_addMagazine = {[_this select 0, _this select 1, "TEST_invMags"] call TEST_fnc_invAdd};
TEST_fnc_removeItem = {[_this select 0, _this select 1, "TEST_inv"] call TEST_fnc_invRemove};
TEST_fnc_removeMagazine = {[_this select 0, _this select 1, "TEST_invMags"] call TEST_fnc_invRemove};
TEST_fnc_createVehicleArray = {
    private _compatObject = (_this select 0) createVehicle (_this select 1);
    _compatObject setVariable ["TEST_class", _this select 0];
    TEST_created pushBack _compatObject;
    _compatObject
};
TEST_created = [];
TEST_fnc_addMagCargo = {[_this select 0, "TEST_mags", (_this select 1) select 0, (_this select 1) select 1] call TEST_fnc_addPairs};
TEST_fnc_clipboard = {TEST_clipboard = _this};
TEST_fnc_createDialog = {TEST_dialogs pushBack _this; true};
// SQF-VM's inheritsFrom returns the enclosing class: fixture classes name their parent
// in TEST_parent instead. Displays are plain null objects; findDisplay finds nothing
// unless TEST_zeusOpen is set.
TEST_null = objNull;
TEST_zeusOpen = false;
TEST_closed = 0;
TEST_fnc_inheritsFrom = {
    private _compatParent = getText (_this >> "TEST_parent");
    if (_compatParent == "") exitWith {configFile >> "TEST_NoSuchClass"};
    private _compatRoot = configFile >> "ace_medical_treatment_actions";
    if !(isClass (_compatRoot >> configName _this)) then {_compatRoot = configFile >> "ACE_Repair" >> "Actions"};
    _compatRoot >> _compatParent
};
TEST_fnc_findDisplay = {if (TEST_zeusOpen && {_this == 312}) then {player} else {objNull}};
TEST_fnc_closeDialog = {TEST_closed = TEST_closed + 1};
TEST_fnc_speed = {_this getVariable ["TEST_speed", 0]};
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
            case "CALLNULAR hasinterface": {_compatOut pushBack "GETVARIABLE TEST_hasInterface"};
            case "CALLNULAR systemtime": {_compatOut pushBack "GETVARIABLE TEST_systemTime"};
            case "CALLNULAR missionname": {_compatOut pushBack "PUSH ""TestMission"""};
            case "CALLNULAR worldname": {_compatOut pushBack "PUSH ""Altis"""};
            case "CALLNULAR dialog": {_compatOut pushBack "PUSH false"};
            case "CALLNULAR displaynull": {_compatOut pushBack "GETVARIABLE TEST_null"};
            case "CALLUNARY inheritsfrom": {"TEST_fnc_inheritsFrom" call _compatCall};
            case "CALLUNARY finddisplay": {"TEST_fnc_findDisplay" call _compatCall};
            case "CALLUNARY closedialog": {"TEST_fnc_closeDialog" call _compatCall};
            case "CALLUNARY speed": {"TEST_fnc_speed" call _compatCall};
            case "CALLUNARY getplayeruid": {"TEST_fnc_uid" call _compatCall};
            case "CALLUNARY name": {"TEST_fnc_name" call _compatCall};
            case "CALLUNARY isplayer": {"TEST_fnc_isPlayer" call _compatCall};
            case "CALLUNARY items": {"TEST_fnc_items" call _compatCall};
            case "CALLUNARY magazines": {"TEST_fnc_mags" call _compatCall};
            case "CALLBINARY canadd": {"TEST_fnc_canAdd" call _compatPair};
            case "CALLBINARY additem": {"TEST_fnc_addItem" call _compatPair};
            case "CALLBINARY addmagazine": {"TEST_fnc_addMagazine" call _compatPair};
            case "CALLBINARY removeitem": {"TEST_fnc_removeItem" call _compatPair};
            case "CALLBINARY removemagazine": {"TEST_fnc_removeMagazine" call _compatPair};
            case "CALLUNARY createvehicle": {"TEST_fnc_createVehicleArray" call _compatCall};
            // Flat fixture world: ATL and the VM position coincide.
            case "CALLUNARY getposatl": {_compatOut pushBack "CALLUNARY getpos"};
            case "CALLBINARY addmagazinecargoglobal": {"TEST_fnc_addMagCargo" call _compatPair};
            case "CALLUNARY copytoclipboard": {"TEST_fnc_clipboard" call _compatCall};
            case "CALLUNARY createdialog": {"TEST_fnc_createDialog" call _compatCall};
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
            case "CALLBINARY addweaponwithattachmentscargoglobal": {"TEST_fnc_addWeaponItems" call _compatPair};
            case "CALLUNARY group": {"TEST_fnc_identity" call _compatCall};
            case "CALLUNARY loadfile": {"TEST_fnc_loadFile" call _compatCall};
            case "CALLUNARY fileexists": {"TEST_fnc_fileExists" call _compatCall};
            case "CALLUNARY parsesimplearray": {"TEST_fnc_parseSimple" call _compatCall};
            case "CALLNULAR isfilepatchingenabled": {_compatOut pushBack "GETVARIABLE TEST_filePatching"};
            case "CALLUNARY side": {"TEST_fnc_side" call _compatCall};
            case "CALLUNARY local": {"TEST_fnc_local" call _compatCall};
            case "CALLUNARY attachedto": {"TEST_fnc_attachedTo" call _compatCall};
            case "CALLUNARY synchronizedobjects": {"TEST_fnc_synced" call _compatCall};
            case "CALLUNARY getassignedcuratorlogic": {"TEST_fnc_curator" call _compatCall};
            // Mission strings are checked in the stringtable; the VM keeps the keys.
            case "CALLUNARY localize": {"TEST_fnc_identity" call _compatCall};
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

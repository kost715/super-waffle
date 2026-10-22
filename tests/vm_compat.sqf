// SQF-VM 2026.04 lacks several Arma operators. Adapt compiled opcodes, not
// application branches, and record the compatibility surface explicitly.
TEST_isServer = true;
TEST_hasInterface = false;
TEST_isRemoteExecuted = false;
TEST_remoteOwner = 2;
TEST_messages = [];
TEST_published = [];
TEST_profilesSaved = 0;
TEST_date = [2035,6,24,8,14];
TEST_worldVehicles = [];
TEST_emptyArray = [];
TEST_players = [player];
TEST_missionHandlers = [];
TEST_spatialOccupied = false;
TEST_noTarget = false;
TEST_realTime = 1000;
TEST_driveCalls = [];
TEST_attackCalls = [];
TEST_nearForces = [];
TEST_randomQueue = [];
TEST_fnc_random = {
    if (TEST_randomQueue isEqualTo []) exitWith {random _this};
    private _compatDraw = TEST_randomQueue deleteAt 0;
    _compatDraw * _this
};

TEST_fnc_getDefault = {
    params ["_compatMap", "_compatArgs"];
    if !((_compatArgs select 0) in _compatMap) exitWith {_compatArgs select 1};
    _compatMap get (_compatArgs select 0)
};
TEST_fnc_setVariable = {
    params ["_compatTarget", "_compatArgs"];
    _compatTarget setVariable (_compatArgs select [0,2]);
};
// VM retains a nil-valued key after setVariable [...,nil]. Arma removes it,
// so subsequent getVariable [name,default] must return that default.
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
TEST_fnc_remote = {TEST_messages pushBack _this; 0};
TEST_fnc_publish = {TEST_published pushBack _this};
TEST_fnc_isPlayer = {_this getVariable ["TEST_player", false]};
TEST_fnc_owner = {_this getVariable ["TEST_owner", 2]};
// Text rendering is outside the transaction fixture. Keep the localization
// key visible in recorded messages; the browser/XML tests check actual text.
TEST_fnc_localize = {_this};
// Finite fixtures only; VM lacks the engine finite predicate.
TEST_fnc_finite = {_this == _this && {abs _this < 1e38}};
TEST_fnc_name = {"Test " + (_this getVariable ["ALS_uid","NPC"])};
TEST_fnc_grid = {"001001"};
// SQF-VM's C++ char is signed; Arma/browser UTF-8 transport uses 0..255 bytes.
TEST_fnc_bytes = {(toArray _this) apply {if (_x < 0) then {_x + 256} else {_x}}};
// The VM has no geometry/physics. Keep VM objects for identity and deletion,
// adapt its createVehicle array signature, and supply fixture model bounds.
TEST_fnc_createVehicle = {
    private _compatObject = (_this select 0) createVehicle (_this select 1);
    _compatObject setVariable ["TEST_class", _this select 0];
    _compatObject
};
TEST_fnc_bounds = {
    if ((_this getVariable ["TEST_class", ""]) == "Land_TableDesk_F") exitWith {[[-0.6,-0.35,0],[0.6,0.35,0.75]]};
    [[-0.12,-0.1,-0.03],[0.12,0.1,0.25]]
};
TEST_fnc_simulation = {(_this select 0) setVariable ["TEST_simulation", _this select 1]};
TEST_fnc_damage = {(_this select 0) setVariable ["TEST_damage", _this select 1]};
TEST_fnc_setPosASL = {(_this select 0) setPos (_this select 1)};
TEST_fnc_setDir = {(_this select 0) setVariable ["TEST_dir", _this select 1]};
// JSON/CEF boundaries for the native-phone integration fixture. Packet lookup
// supplies decoded test messages; serialization emits the native Push result
// for the real HTML browser check. This does not emulate Arma's CEF engine.
TEST_fnc_fromJSON = {
    if !(_this in TEST_jsonPackets) exitWith {createHashMap};
    TEST_jsonPackets get _this
};
TEST_fnc_toJSON = {
    if (isNil "_this") exitWith {"null"};
    if (_this isEqualType "") exitWith {
        private _compatEscaped = (toArray _this) apply {
            switch (_x) do {
                case 34: {toString [92,34]};
                case 92: {toString [92,92]};
                case 10: {toString [92,110]};
                case 13: {toString [92,114]};
                case 9: {toString [92,116]};
                default {toString [_x]};
            }
        };
        toString [34] + (_compatEscaped joinString "") + toString [34]
    };
    if (_this isEqualType []) exitWith {"[" + ((_this apply {_x call TEST_fnc_toJSON}) joinString ",") + "]"};
    if (_this isEqualType createHashMap) exitWith {
        private _compatMap = _this;
        "{" + (((keys _compatMap) apply {(_x call TEST_fnc_toJSON) + ":" + ((_compatMap get _x) call TEST_fnc_toJSON)}) joinString ",") + "}"
    };
    str _this
};
TEST_fnc_webAction = {TEST_webCalls pushBack _this; true};
TEST_fnc_addPVEH = {0};
TEST_fnc_positionATL = {getPos _this};
TEST_fnc_vehicle = {_this};
TEST_fnc_players = {TEST_players};
// Headless clients are the only fixture entities enumerated by class.
TEST_fnc_entities = {if (_this isEqualTo "HeadlessClient_F") then {TEST_players select {(_x getVariable ["TEST_class", ""]) == "HeadlessClient_F"}} else {[]}};
// 0.7.1 hostages/defenders: captive state, nearby units, all groups and class checks.
TEST_nearEntities = [];
TEST_fnc_captive = {_this getVariable ["TEST_captive", false]};
TEST_fnc_setCaptive = {(_this select 0) setVariable ["TEST_captive", _this select 1]};
TEST_fnc_nearEntities = {
    private _compatCenter = _this select 0;
    private _compatRadius = (_this select 1) select 1;
    TEST_nearEntities select {!isNull _x && {(_x distance _compatCenter) <= _compatRadius}}
};
TEST_fnc_allGroups = {_this apply {_x select 0}};
TEST_fnc_isKindOf = {
    params ["_compatLeft", "_compatParent"];
    private _compatClass = if (_compatLeft isEqualType objNull) then {_compatLeft getVariable ["TEST_class", ""]} else {_compatLeft};
    private _compatCfg = configFile >> "CfgVehicles" >> _compatClass;
    private _compatFound = false;
    while {isClass _compatCfg && {!_compatFound}} do {
        _compatFound = (configName _compatCfg) == _compatParent;
        _compatCfg = inheritsFrom _compatCfg;
    };
    _compatFound
};
TEST_fnc_noParent = {objNull};
TEST_fnc_typeOf = {_this getVariable ["TEST_class", ""]};
TEST_fnc_configOf = {configFile >> "CfgVehicles" >> (_this getVariable ["TEST_class", ""])};
TEST_fnc_fuel = {0.8};
TEST_fnc_plate = {"TEST 42"};
// AI, world geometry, event delivery and physics are engine boundaries. Keep
// object identity/death/deletion real in the VM; tests call the captured server
// kill callback explicitly. Native acceptance/result/payment code is unchanged.
TEST_groupMembers = [];
TEST_friendships = createHashMap;
TEST_fnc_createGroup = {
    private _compatGroup = createGroup (_this select 0);
    TEST_groupMembers pushBack [_compatGroup, []];
    _compatGroup
};
TEST_fnc_createUnit = {
    if (TEST_noTarget) exitWith {objNull};
    private _compatArgs = _this select 1;
    private _compatObject = (_compatArgs select 0) createVehicle (_compatArgs select 1);
    _compatObject setVariable ["TEST_class", _compatArgs select 0];
    _compatObject setVariable ["TEST_group", _this select 0];
    private _compatIndex = TEST_groupMembers findIf {(_x select 0) isEqualTo (_this select 0)};
    if (_compatIndex >= 0) then {((TEST_groupMembers select _compatIndex) select 1) pushBack _compatObject};
    _compatObject
};
TEST_fnc_units = {private _compatGroup = _this; ((TEST_groupMembers select {(_x select 0) isEqualTo _compatGroup}) param [0, [grpNull,[]]]) select 1};
TEST_fnc_getFriend = {private _compatKey = str _this; if (_compatKey in TEST_friendships) then {TEST_friendships get _compatKey} else {1}};
TEST_fnc_setFriend = {TEST_friendships set [str [_this select 0, (_this select 1) select 0], (_this select 1) select 1]};
TEST_fnc_ratingAdd = {(_this select 0) setVariable ["TEST_rating", ((_this select 0) getVariable ["TEST_rating",0]) + (_this select 1)]};
TEST_fnc_addEH = {(_this select 0) setVariable ["TEST_" + ((_this select 1) select 0), (_this select 1) select 1]; 0};
TEST_fnc_uniform = {_this getVariable ["TEST_uniform", ""]};
TEST_fnc_forceUniform = {(_this select 0) setVariable ["TEST_uniform", _this select 1]};
TEST_fnc_enginePair = {};
TEST_fnc_missionHandler = {TEST_missionHandlers pushBack _this; count TEST_missionHandlers - 1};
TEST_fnc_pointAt = {
    params ["_compatOrigin", "_compatPolar"];
    [(_compatOrigin select 0) + sin (_compatPolar select 1) * (_compatPolar select 0),
     (_compatOrigin select 1) + cos (_compatPolar select 1) * (_compatPolar select 0), 0]
};
TEST_fnc_nearestObjects = {
    if (TEST_spatialOccupied) exitWith {[player]};
    if (("CAManBase" in (_this select 1)) || {"LandVehicle" in (_this select 1)}) exitWith {TEST_nearForces};
    []
};
TEST_fnc_identity = {_this};
TEST_playerGroup = createGroup civilian;
TEST_fnc_group = {
    private _compatGroup = [_this,["TEST_group",grpNull]] call TEST_fnc_getVariable;
    if (isNull _compatGroup && {_this isEqualTo player || {_this getVariable ["TEST_player",false]}}) then {TEST_playerGroup} else {_compatGroup}
};
TEST_fnc_leader = {player};
TEST_fnc_driver = {_this getVariable ["TEST_driver", objNull]};
TEST_fnc_moveDriver = {(_this select 1) setVariable ["TEST_driver", _this select 0]};
TEST_fnc_moveGunner = {(_this select 1) setVariable ["TEST_gunner", _this select 0]};
TEST_fnc_join = {
    private _compatGroup = _this select 1;
    {
        private _compatUnit = _x;
        {_x set [1, (_x select 1) - [_compatUnit]]} forEach TEST_groupMembers;
        _compatUnit setVariable ["TEST_group", _compatGroup];
        private _compatIndex = TEST_groupMembers findIf {(_x select 0) isEqualTo _compatGroup};
        if (_compatIndex >= 0) then {((TEST_groupMembers select _compatIndex) select 1) pushBack _compatUnit};
    } forEach (_this select 0);
};
TEST_fnc_magazines = {_this getVariable ["TEST_magazines", []]};
TEST_fnc_clearWeapons = {_this setVariable ["TEST_weapons", []]; _this setVariable ["TEST_magazines", []]};
TEST_fnc_addWeapon = {
    params ["_compatUnit", "_compatWeapon"];
    private _compatWeapons = _compatUnit getVariable ["TEST_weapons", []];
    _compatWeapons pushBack _compatWeapon;
    _compatUnit setVariable ["TEST_weapons", _compatWeapons];
};
TEST_fnc_addMagazines = {
    params ["_compatUnit", "_compatSpec"];
    private _compatMags = _compatUnit getVariable ["TEST_magazines", []];
    for "_compatI" from 1 to (_compatSpec select 1) do {_compatMags pushBack (_compatSpec select 0)};
    _compatUnit setVariable ["TEST_magazines", _compatMags];
};
TEST_fnc_removeMagazine = {
    params ["_compatUnit", "_compatMag"];
    _compatUnit setVariable ["TEST_magazines", (_compatUnit getVariable ["TEST_magazines", []]) - [_compatMag]];
};
TEST_fnc_createMine = {
    private _compatMine = "APERSMine" createVehicle (_this select 1);
    _compatMine setVariable ["TEST_mineActive", true];
    _compatMine
};
TEST_fnc_mineActive = {_this getVariable ["TEST_mineActive", false]};
TEST_fnc_insert = {
    params ["_compatArray", "_compatArgs"];
    private _compatAt = _compatArgs select 0;
    // VM omits Arma's optional range length; specify it explicitly.
    private _compatTail = _compatArray select [_compatAt, count _compatArray - _compatAt];
    _compatArray resize _compatAt;
    _compatArray append (_compatArgs select 1);
    _compatArray append _compatTail;
};
TEST_fnc_trim = {
    private _compatChars = toArray _this;
    private _compatStart = 0;
    private _compatEnd = count _compatChars;
    while {_compatStart < _compatEnd && {(_compatChars select _compatStart) <= 32}} do {_compatStart = _compatStart + 1};
    while {_compatEnd > _compatStart && {(_compatChars select (_compatEnd - 1)) <= 32}} do {_compatEnd = _compatEnd - 1};
    if (_compatEnd == _compatStart) exitWith {""};
    _this select [_compatStart, _compatEnd - _compatStart]
};

TEST_fnc_compatCode = {
    private _compatOut = [];
    {
        private _compatLine = _x;
        if ((_compatLine select [0, 6]) == "PUSH {") then {
            private _compatNested = call compile (_compatLine select [5]);
            _compatLine = "PUSH " + str (_compatNested call TEST_fnc_compatCode);
        };
        switch (_compatLine) do {
            case "CALLNULAR isserver": {_compatOut pushBack "GETVARIABLE TEST_isServer"};
            case "CALLNULAR hasinterface": {_compatOut pushBack "GETVARIABLE TEST_hasInterface"};
            case "CALLNULAR isremoteexecuted": {_compatOut pushBack "GETVARIABLE TEST_isRemoteExecuted"};
            case "CALLNULAR remoteexecutedowner": {_compatOut pushBack "GETVARIABLE TEST_remoteOwner"};
            case "CALLBINARY getordefault": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_getDefault", "CALLBINARY call"]};
            case "CALLBINARY toarray": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_toPairs", "CALLBINARY call"]};
            case "CALLBINARY setvariable": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_setVariable", "CALLBINARY call"]};
            case "CALLBINARY getvariable": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_getVariable", "CALLBINARY call"]};
            case "CALLUNARY values": {_compatOut append ["GETVARIABLE TEST_fnc_values", "CALLBINARY call"]};
            case "CALLBINARY foreach": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_forEach", "CALLBINARY call"]};
            case "CALLBINARY remoteexec";
            case "CALLBINARY remoteexeccall": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_remote", "CALLBINARY call"]};
            case "CALLUNARY publicvariable": {_compatOut append ["GETVARIABLE TEST_fnc_publish", "CALLBINARY call"]};
            case "CALLUNARY isplayer": {_compatOut append ["GETVARIABLE TEST_fnc_isPlayer", "CALLBINARY call"]};
            case "CALLUNARY owner": {_compatOut append ["GETVARIABLE TEST_fnc_owner", "CALLBINARY call"]};
            case "CALLUNARY finite": {_compatOut append ["GETVARIABLE TEST_fnc_finite", "CALLBINARY call"]};
            case "CALLUNARY name": {_compatOut append ["GETVARIABLE TEST_fnc_name", "CALLBINARY call"]};
            case "CALLUNARY localize": {_compatOut append ["GETVARIABLE TEST_fnc_localize", "CALLBINARY call"]};
            case "CALLUNARY mapgridposition": {_compatOut append ["GETVARIABLE TEST_fnc_grid", "CALLBINARY call"]};
            case "CALLUNARY toarray": {_compatOut append ["GETVARIABLE TEST_fnc_bytes", "CALLBINARY call"]};
            case "CALLUNARY fromjson": {_compatOut append ["GETVARIABLE TEST_fnc_fromJSON", "CALLBINARY call"]};
            case "CALLUNARY tojson": {_compatOut append ["GETVARIABLE TEST_fnc_toJSON", "CALLBINARY call"]};
            case "CALLUNARY typeof": {_compatOut append ["GETVARIABLE TEST_fnc_typeOf", "CALLBINARY call"]};
            case "CALLUNARY configof": {_compatOut append ["GETVARIABLE TEST_fnc_configOf", "CALLBINARY call"]};
            case "CALLUNARY fuel": {_compatOut append ["GETVARIABLE TEST_fnc_fuel", "CALLBINARY call"]};
            case "CALLUNARY getplatenumber": {_compatOut append ["GETVARIABLE TEST_fnc_plate", "CALLBINARY call"]};
            case "CALLUNARY getposatl": {_compatOut append ["GETVARIABLE TEST_fnc_positionATL", "CALLBINARY call"]};
            case "CALLUNARY vehicle": {_compatOut append ["GETVARIABLE TEST_fnc_vehicle", "CALLBINARY call"]};
            case "CALLUNARY trim": {_compatOut append ["GETVARIABLE TEST_fnc_trim", "CALLBINARY call"]};
            case "CALLBINARY ctrlwebbrowseraction": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_webAction", "CALLBINARY call"]};
            case "CALLBINARY addpublicvariableeventhandler": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_addPVEH", "CALLBINARY call"]};
            case "CALLNULAR date": {_compatOut pushBack "GETVARIABLE TEST_date"};
            case "CALLNULAR daytime": {_compatOut pushBack "PUSH 8.23"};
            case "CALLNULAR servertime": {_compatOut pushBack "PUSH 100"};
            case "CALLNULAR vehicles": {_compatOut pushBack "GETVARIABLE TEST_worldVehicles"};
            case "CALLNULAR allplayers": {_compatOut append ["PUSH 0", "GETVARIABLE TEST_fnc_players", "CALLBINARY call"]};
            case "CALLUNARY entities": {_compatOut append ["GETVARIABLE TEST_fnc_entities", "CALLBINARY call"]};
            case "CALLUNARY items": {_compatOut append ["GETVARIABLE TEST_fnc_entities", "CALLBINARY call"]};
            case "CALLUNARY objectparent": {_compatOut append ["GETVARIABLE TEST_fnc_noParent", "CALLBINARY call"]};
            case "CALLNULAR customwaypointposition": {_compatOut pushBack "GETVARIABLE TEST_emptyArray"};
            case "CALLUNARY createvehicle": {_compatOut append ["GETVARIABLE TEST_fnc_createVehicle", "CALLBINARY call"]};
            case "CALLUNARY boundingboxreal": {_compatOut append ["GETVARIABLE TEST_fnc_bounds", "CALLBINARY call"]};
            case "CALLBINARY enablesimulationglobal": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_simulation", "CALLBINARY call"]};
            case "CALLBINARY allowdamage": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_damage", "CALLBINARY call"]};
            case "CALLBINARY setposasl": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_setPosASL", "CALLBINARY call"]};
            case "CALLBINARY setdir": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_setDir", "CALLBINARY call"]};
            case "CALLUNARY creategroup": {_compatOut append ["GETVARIABLE TEST_fnc_createGroup", "CALLBINARY call"]};
            case "CALLBINARY createunit": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_createUnit", "CALLBINARY call"]};
            case "CALLBINARY setbehaviour";
            case "CALLBINARY setcombatmode";
            case "CALLBINARY setskill";
            case "CALLBINARY disableai": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_enginePair", "CALLBINARY call"]};
            case "CALLBINARY setcaptive": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_setCaptive", "CALLBINARY call"]};
            case "CALLUNARY captive": {_compatOut append ["GETVARIABLE TEST_fnc_captive", "CALLBINARY call"]};
            case "CALLBINARY nearentities": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_nearEntities", "CALLBINARY call"]};
            case "CALLNULAR allgroups": {_compatOut append ["GETVARIABLE TEST_groupMembers", "GETVARIABLE TEST_fnc_allGroups", "CALLBINARY call"]};
            case "CALLBINARY iskindof": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_isKindOf", "CALLBINARY call"]};
            case "CALLBINARY playmovenow": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_enginePair", "CALLBINARY call"]};
            // Flat fixture terrain: ASL and ATL coincide.
            case "CALLUNARY getposasl": {_compatOut append ["GETVARIABLE TEST_fnc_positionATL", "CALLBINARY call"]};
            case "CALLBINARY addrating": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_ratingAdd", "CALLBINARY call"]};
            case "CALLBINARY addeventhandler": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_addEH", "CALLBINARY call"]};
            case "CALLBINARY getfriend": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_getFriend", "CALLBINARY call"]};
            case "CALLBINARY setfriend": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_setFriend", "CALLBINARY call"]};
            case "CALLUNARY units": {_compatOut append ["GETVARIABLE TEST_fnc_units", "CALLBINARY call"]};
            case "CALLUNARY toloweransi": {_compatOut pushBack "CALLUNARY tolower"};
            case "CALLUNARY createcenter": {_compatOut append ["GETVARIABLE TEST_fnc_identity", "CALLBINARY call"]};
            case "CALLUNARY uniform": {_compatOut append ["GETVARIABLE TEST_fnc_uniform", "CALLBINARY call"]};
            case "CALLUNARY removeheadgear";
            case "CALLUNARY removegoggles";
            case "CALLUNARY removevest": {_compatOut append ["GETVARIABLE TEST_fnc_enginePair", "CALLBINARY call"]};
            case "CALLBINARY forceadduniform": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_forceUniform", "CALLBINARY call"]};
            case "CALLUNARY addmissioneventhandler": {_compatOut append ["GETVARIABLE TEST_fnc_missionHandler", "CALLBINARY call"]};
            case "CALLBINARY insert": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_insert", "CALLBINARY call"]};
            case "CALLBINARY getpos": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_pointAt", "CALLBINARY call"]};
            case "CALLNULAR worldsize": {_compatOut pushBack "PUSH 30000"};
            case "CALLUNARY nearestobjects": {_compatOut append ["GETVARIABLE TEST_fnc_nearestObjects", "CALLBINARY call"]};
            case "CALLNULAR diag_ticktime": {_compatOut pushBack "GETVARIABLE TEST_realTime"};
            case "CALLUNARY random": {_compatOut append ["GETVARIABLE TEST_fnc_random", "CALLBINARY call"]};
            case "CALLUNARY asltoatl";
            case "CALLUNARY surfacenormal": {_compatOut append ["GETVARIABLE TEST_fnc_identity", "CALLBINARY call"]};
            case "CALLUNARY group": {_compatOut append ["GETVARIABLE TEST_fnc_group", "CALLBINARY call"]};
            case "CALLUNARY leader": {_compatOut append ["GETVARIABLE TEST_fnc_leader", "CALLBINARY call"]};
            case "CALLUNARY driver": {_compatOut append ["GETVARIABLE TEST_fnc_driver", "CALLBINARY call"]};
            case "CALLBINARY moveindriver": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_moveDriver", "CALLBINARY call"]};
            case "CALLBINARY moveingunner": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_moveGunner", "CALLBINARY call"]};
            case "CALLBINARY joinsilent": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_join", "CALLBINARY call"]};
            case "CALLUNARY magazines": {_compatOut append ["GETVARIABLE TEST_fnc_magazines", "CALLBINARY call"]};
            case "CALLUNARY removeallweapons": {_compatOut append ["GETVARIABLE TEST_fnc_clearWeapons", "CALLBINARY call"]};
            case "CALLUNARY removebackpack": {_compatOut append ["GETVARIABLE TEST_fnc_enginePair", "CALLBINARY call"]};
            case "CALLBINARY addweapon": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_addWeapon", "CALLBINARY call"]};
            case "CALLBINARY addmagazines": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_addMagazines", "CALLBINARY call"]};
            case "CALLBINARY removemagazine": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_removeMagazine", "CALLBINARY call"]};
            case "CALLUNARY createmine": {_compatOut append ["GETVARIABLE TEST_fnc_createMine", "CALLBINARY call"]};
            case "CALLUNARY mineactive": {_compatOut append ["GETVARIABLE TEST_fnc_mineActive", "CALLBINARY call"]};
            case "CALLBINARY setposatl": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_setPosASL", "CALLBINARY call"]};
            case "CALLBINARY selectweapon";
            case "CALLBINARY allowfleeing";
            case "CALLBINARY lock";
            case "CALLBINARY attachto";
            case "CALLBINARY setvectorup";
            case "CALLBINARY limitspeed";
            case "CALLBINARY reveal";
            case "CALLBINARY dotarget";
            case "CALLBINARY dofire": {_compatOut append ["MAKEARRAY 2", "GETVARIABLE TEST_fnc_enginePair", "CALLBINARY call"]};
            case "CALLNULAR saveprofilenamespace": {_compatOut append ["GETVARIABLE TEST_profilesSaved", "PUSH 1", "CALLBINARY +", "ASSIGNTO TEST_profilesSaved"]};
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

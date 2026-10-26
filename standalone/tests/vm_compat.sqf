// Self-contained modeled engine boundaries. No original-mod functions loaded.
T_server = true; T_interface = false; T_remote = true; T_owner = 2;
T_multiplayer = true; T_adminOwners = [];
T_messages = []; T_relations = createHashMap; T_groups = []; T_spawnFails = false;
T_rendered = 0; T_nullDisplay = objNull;
T_fnc_default = {params ["_map","_args"]; if ((_args select 0) in _map) then {_map get (_args select 0)} else {_args select 1}};
T_fnc_setVar = {params ["_target","_args"]; _target setVariable (_args select [0,2])};
T_fnc_player = {_this getVariable ["T_player",false]};
T_fnc_owner = {_this getVariable ["T_owner",2]};
T_fnc_uid = {_this getVariable ["T_uid",""]};
T_fnc_admin = {if (_this in T_adminOwners) then {2} else {0}};
T_fnc_remote = {T_messages pushBack _this; 0};
T_fnc_group = {_this getVariable ["T_group",grpNull]};
T_fnc_createGroup = {private _side=if (_this isEqualType []) then {_this select 0} else {_this};private _g=createGroup _side;T_groups pushBack [_g,[]];_g};
T_fnc_createUnit = {
    if (T_spawnFails) exitWith {objNull};
    params ["_g","_args"];
    private _u=(_args select 0) createVehicle (_args select 1);
    _u setVariable ["T_group",_g];
    private _i=T_groups findIf {(_x select 0) isEqualTo _g};
    if (_i>=0) then {((T_groups select _i) select 1) pushBack _u};
    _u
};
T_fnc_units = {private _g=_this;private _i=T_groups findIf {(_x select 0) isEqualTo _g};if (_i<0) then {[]} else {((T_groups select _i) select 1) select {!isNull _x}}};
T_fnc_setFriend = {T_relations set [str [_this select 0,(_this select 1) select 0],(_this select 1) select 1]};
T_fnc_getFriend = {private _key=str _this;if (_key in T_relations) then {T_relations get _key} else {1}};
T_fnc_pair = {};
T_fnc_pos = {(_this select 0) setPos (_this select 1)};
T_fnc_freePos = {_this select 0};
T_fnc_createVehicle = {(_this select 0) createVehicle (_this select 1)};
T_fnc_rate = {(_this select 0) setVariable ["T_rating",_this select 1]};
T_fnc_eh = {0};
T_fnc_name = {"Fixture"};
T_fnc_compile = {
    private _out=[];
    {
        private _line=_x;
        if ((_line select [0,6])=="PUSH {") then {
            private _code=call compile (_line select [5,count _line - 5]);
            _line="PUSH "+str (_code call T_fnc_compile);
        };
        switch (_line) do {
            case "CALLNULAR isserver": {_out pushBack "GETVARIABLE T_server"};
            case "CALLNULAR hasinterface": {_out pushBack "GETVARIABLE T_interface"};
            case "CALLNULAR isremoteexecuted": {_out pushBack "GETVARIABLE T_remote"};
            case "CALLNULAR remoteexecutedowner": {_out pushBack "GETVARIABLE T_owner"};
            case "CALLNULAR ismultiplayer": {_out pushBack "GETVARIABLE T_multiplayer"};
            case "CALLNULAR displaynull": {_out pushBack "GETVARIABLE T_nullDisplay"};
            case "CALLBINARY getordefault": {_out append ["MAKEARRAY 2","GETVARIABLE T_fnc_default","CALLBINARY call"]};
            case "CALLBINARY setvariable": {_out append ["MAKEARRAY 2","GETVARIABLE T_fnc_setVar","CALLBINARY call"]};
            case "CALLUNARY getplayeruid": {_out append ["GETVARIABLE T_fnc_uid","CALLBINARY call"]};
            case "CALLUNARY owner": {_out append ["GETVARIABLE T_fnc_owner","CALLBINARY call"]};
            case "CALLUNARY admin": {_out append ["GETVARIABLE T_fnc_admin","CALLBINARY call"]};
            case "CALLUNARY isplayer": {_out append ["GETVARIABLE T_fnc_player","CALLBINARY call"]};
            case "CALLUNARY group": {_out append ["GETVARIABLE T_fnc_group","CALLBINARY call"]};
            case "CALLUNARY name": {_out append ["GETVARIABLE T_fnc_name","CALLBINARY call"]};
            case "CALLUNARY creategroup": {_out append ["GETVARIABLE T_fnc_createGroup","CALLBINARY call"]};
            case "CALLBINARY createunit": {_out append ["MAKEARRAY 2","GETVARIABLE T_fnc_createUnit","CALLBINARY call"]};
            case "CALLUNARY createvehicle": {_out append ["GETVARIABLE T_fnc_createVehicle","CALLBINARY call"]};
            case "CALLUNARY units": {_out append ["GETVARIABLE T_fnc_units","CALLBINARY call"]};
            case "CALLBINARY setfriend": {_out append ["MAKEARRAY 2","GETVARIABLE T_fnc_setFriend","CALLBINARY call"]};
            case "CALLBINARY getfriend": {_out append ["MAKEARRAY 2","GETVARIABLE T_fnc_getFriend","CALLBINARY call"]};
            case "CALLBINARY remoteexeccall": {_out append ["MAKEARRAY 2","GETVARIABLE T_fnc_remote","CALLBINARY call"]};
            case "CALLBINARY setposatl": {_out append ["MAKEARRAY 2","GETVARIABLE T_fnc_pos","CALLBINARY call"]};
            case "CALLBINARY findemptyposition": {_out append ["MAKEARRAY 2","GETVARIABLE T_fnc_freePos","CALLBINARY call"]};
            case "CALLBINARY addrating": {_out append ["MAKEARRAY 2","GETVARIABLE T_fnc_rate","CALLBINARY call"]};
            case "CALLBINARY addeventhandler": {_out append ["MAKEARRAY 2","GETVARIABLE T_fnc_eh","CALLBINARY call"]};
            case "CALLUNARY removeallweapons": {_out append ["GETVARIABLE T_fnc_pair","CALLBINARY call"]};
            case "CALLBINARY setbehaviour";
            case "CALLBINARY setcombatmode";
            case "CALLBINARY setskill";
            case "CALLBINARY disableai";
            case "CALLBINARY allowfleeing": {_out append ["MAKEARRAY 2","GETVARIABLE T_fnc_pair","CALLBINARY call"]};
            default {_out pushBack _line};
        };
    } forEach (assembly__ _this);
    _out=_out apply {
        private _at=_x find " ";private _op=if (_at<0) then {_x} else {_x select [0,_at]};
        if (_op in ["GETVARIABLE","ASSIGNTO","ASSIGNTOLOCAL"]) then {_op+" "+str (_x select [_at+1,count _x-_at-1])} else {_x}
    };
    fromAssembly__ _out
};
T_fnc_load = {(compile preprocessFileLineNumbers _this) call T_fnc_compile};

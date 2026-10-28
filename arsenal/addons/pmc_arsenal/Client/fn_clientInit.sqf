#include "..\JNA\defineCommon.inc"
// postInit, players: arsenal display hooks shared by every storage object.
if (!hasInterface || {missionNamespace getVariable ["PMCA_clientReady", false]}) exitWith {};
// No member/guest limits in this mod: a unit sees and takes what its storage holds.
pmca_minItemMember = EMPTY_ARRAY apply {-1};
//preload the ammobox so you dont need to wait the first time
["Preload"] call PMCA_fnc_arsenal;

//add open event
[missionNamespace, "arsenalOpened", {
    disableSerialization;
    UINamespace setVariable ["arsenalDisplay",(_this select 0)];

    //spawn this to make sure it doesnt freeze the game
    [] spawn {
        disableSerialization;
        private _type = UINamespace getVariable ["pmca_ui_type",""];
        // A Virtual Arsenal opened by the mission or another mod stays untouched.
        switch (_type) do {
            case "containerArsenal": {["CustomInit", [uiNamespace getVariable "arsenalDisplay"]] call PMCA_fnc_vehicleArsenal};
            case "arsenal": {["CustomInit", [uiNamespace getVariable "arsenalDisplay"]] call PMCA_fnc_arsenal};
        };
    };
}] call BIS_fnc_addScriptedEventHandler;

//add close event: the server settles stock from what this unit or container holds now
[missionNamespace, "arsenalClosed", {
    private _type = UINamespace getVariable ["pmca_ui_type",""];

    if(_type isEqualTo "arsenal")then{
        [getUnitLoadout player] remoteExecCall ["PMCA_fnc_arsenal_requestClose",2];
    };

    if(_type isEqualTo "containerArsenal")then{
        private _claim = +(missionNamespace getVariable ["pmca_va_loadout", []]);
        ["Close"] call PMCA_fnc_vehicleArsenal;
        [_claim] remoteExecCall ["PMCA_fnc_arsenal_requestClose",2];
    };
    UINamespace setVariable ["pmca_ui_type",""];
}] call BIS_fnc_addScriptedEventHandler;
PMCA_clientReady = true;

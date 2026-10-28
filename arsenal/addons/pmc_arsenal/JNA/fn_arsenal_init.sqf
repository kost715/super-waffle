#include "defineCommon.inc"
#include "..\script_component.hpp"
/*
    Author: Jeroen Notenbomer; per-object storages: LifeSim PMC project

    Client. Adds the arsenal actions to a storage object. Sent by
    PMCA_fnc_registerStorage to every client (JIP included); runs once per object.
*/
params [["_object", objNull, [objNull]]];
if (!hasInterface || {isNull _object} || {_object getVariable ["PMCA_actionsAdded", false]}) exitWith {};
_object setVariable ["PMCA_actionsAdded", true];

//add arsenal button
_object addAction [
    (format ["<img image='%1' size='1.6' shadow=2/>", STR_ACTION_ICON_ARSENAL] + format["<t size='1'> %1</t>", (localize "STR_A3_Arsenal")]),
    PMCA_fnc_arsenal_handleAction,
    [],
    6,
    true,
    false,
    "",
    "alive _target && {_target distance _this < 5} && {vehicle player == player}"
];

//add vehicle/box filling button
_object addAction [
	("<img image='" + QPATHTOFOLDER(Pictures\unloadvehicle.paa) + "' size='1.6' shadow=2/>" + format["<t size='1'> %1</t>", localize "STR_PMCA_ACT_CONTAINER_OPEN"]),
    {
		private _object = _this select 0;

		private _script =  {
			params ["_object"];

			//check if player is looking at some object
			private _objectSelected = cursorObject;
			if(isnull _objectSelected)exitWith{hint localize "STR_PMCA_ACT_CONTAINER_SELECTERROR1"; };

			//check if object is in range
			if(_object distance cursorObject > 50) exitWith {hint localize "STR_PMCA_ACT_CONTAINER_SELECTERROR2";};

			//check if object has inventory
			private _className = typeOf _objectSelected;
			private _tb = getNumber (configFile >> "CfgVehicles" >> _className >> "transportmaxbackpacks");
			private _tm = getNumber (configFile >> "CfgVehicles" >> _className >> "transportmaxmagazines");
			private _tw = getNumber (configFile >> "CfgVehicles" >> _className >> "transportmaxweapons");
			if !(_tb > 0  || _tm > 0 || _tw > 0) exitWith{hint localize "STR_PMCA_ACT_CONTAINER_SELECTERROR3";};

			//set type and object to use later
			UINamespace setVariable ["pmca_ui_type", "containerArsenal"];
			UINamespace setVariable ["pmca_ui_object",_object];
			UINamespace setVariable ["pmca_ui_object_selected",_objectSelected];

            //start loading screen and timer to close it if something breaks
			["PMCA_fnc_arsenal", "Loading Nutz™ Arsenal"] call bis_fnc_startloadingscreen;
			[] spawn {
				uisleep 10;
				private _ids = missionnamespace getvariable ["BIS_fnc_startLoadingScreen_ids",[]];
				if("PMCA_fnc_arsenal" in _ids)then{
					private _display =  uiNamespace getVariable ["arsenalDisplay","No display"];
					titleText["ERROR DURING LOADING ARSENAL", "PLAIN"];
					_display closedisplay 2;
					["PMCA_fnc_arsenal"] call BIS_fnc_endLoadingScreen;
				};
			};

            //request server to open arsenal for the selected container
            [player, _object, "container", _objectSelected] remoteExecCall ["PMCA_fnc_arsenal_requestOpen",2];
		};
		private _conditionActive = {
			params ["_object"];
			alive player;
		};
		private _conditionColor = {
			params ["_object"];

			!isnull cursorObject
			&&{
				_object distance cursorObject < 10;
			}&&{
				//check if object has inventory
				private _className = typeOf cursorObject;
				private _tb = getNumber (configFile >> "CfgVehicles" >> _className >> "transportmaxbackpacks");
				private _tm = getNumber (configFile >> "CfgVehicles" >> _className >> "transportmaxmagazines");
				private _tw = getNumber (configFile >> "CfgVehicles" >> _className >> "transportmaxweapons");
				if (_tb > 0  || _tm > 0 || _tw > 0) then {true;} else {false;};

			}//return
		};

        hint parseText format ["<t size='1.2'>%1</t><br/>%2", localize "STR_PMCA_vehArsenal_header", localize "STR_PMCA_vehArsenal_desc"];

		[_script,_conditionActive,_conditionColor,_object] call PMCA_fnc_common_addActionSelect;
	},
    [],
    6,
    true,
    false,
    "",
    "alive _target && {_target distance _this < 5 && {vehicle player == player}}"
];

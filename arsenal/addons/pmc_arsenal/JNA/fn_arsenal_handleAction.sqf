/**
	Handler for when the 'Arsenal' action is taken.
	
	Usage:
		_thing addAction ["Action", PMCA_fnc_arsenal_handleAction];
		(added by PMCA_fnc_arsenal_init to every registered storage object)
	
	Params:
		Same as any 'addAction' handler
**/

params ["_object"];
if (!(missionNamespace getVariable ["PMCA_clientReady", false]) || {!isNull (uiNamespace getVariable ["arsenalDisplay", displayNull])}) exitWith {};

//start loading screen
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

//save proper ammo because BIS arsenal rearms it, and I will over write it back again
missionNamespace setVariable ["pmca_magazines_init",  [
	magazinesAmmoCargo (uniformContainer player),
	magazinesAmmoCargo (vestContainer player),
	magazinesAmmoCargo (backpackContainer player)
]];

//Save attachments in containers, because BIS arsenal removes them
_attachmentsContainers = [[],[],[]];
{
	_container = _x;
	_weaponAtt = weaponsItemsCargo _x;
	_attachments = [];

	if!(isNil "_weaponAtt")then{

		{
			_atts = [_x select 1,_x select 2,_x select 3,_x select 6];
			_atts = _atts - [""];
			_attachments = _attachments + _atts;
		} forEach _weaponAtt;
		_attachmentsContainers set [_foreachindex,_attachments];
	}
} forEach [uniformContainer player,vestContainer player,backpackContainer player];
missionNamespace setVariable ["pmca_containerCargo_init", _attachmentsContainers];

//set type
UINamespace setVariable ["pmca_ui_type","arsenal"];
UINamespace setVariable ["pmca_ui_object",_object];

//request server to open arsenal; the loadout only tells it how long to wait for sync
[player, _object, "arsenal", objNull, getUnitLoadout player] remoteExecCall ["PMCA_fnc_arsenal_requestOpen",2];
// Own local marker follows the native job mirror, even with phone/PC closed.
private _job = player getVariable ["ALS_coopJob", createHashMap];
if !(_job getOrDefault ["alspmc", false]) exitWith {
    if (missionNamespace getVariable ["ALSPMC_questMarkerOn", false]) then {
        deleteMarkerLocal "ALSPMC_contractTarget";
        deleteMarkerLocal "ALSPMC_contractDestination";
        deleteMarkerLocal "ALSPMC_contractSector";
        ALSPMC_questMarkerOn = false;
    };
};
private _pos = _job getOrDefault ["pos", []];
if (count _pos != 3) exitWith {};
if !(missionNamespace getVariable ["ALSPMC_questMarkerOn", false]) then {
    createMarkerLocal ["ALSPMC_contractTarget", _pos];
    "ALSPMC_contractTarget" setMarkerTypeLocal "mil_objective";
    "ALSPMC_contractTarget" setMarkerColorLocal "ColorRed";
    "ALSPMC_contractTarget" setMarkerTextLocal (localize "STR_ALSPMC_quest_target");
    ALSPMC_questMarkerOn = true;
};
"ALSPMC_contractTarget" setMarkerPosLocal _pos;
"ALSPMC_contractTarget" setMarkerTextLocal (if ((_job getOrDefault ["routeTotal", 0]) > 0) then {
    (localize "STR_ALSPMC_contract_patrol_point") + " " + str (((_job getOrDefault ["routeDone", 0]) + 1) min (_job get "routeTotal")) + "/" + str (_job get "routeTotal")
} else {localize "STR_ALSPMC_quest_target"});
private _destination = _job getOrDefault ["destination", []];
deleteMarkerLocal "ALSPMC_contractDestination";
if (_destination isNotEqualTo []) then {
    createMarkerLocal ["ALSPMC_contractDestination", _destination];
    "ALSPMC_contractDestination" setMarkerTypeLocal "mil_end";
    "ALSPMC_contractDestination" setMarkerColorLocal "ColorGUER";
    "ALSPMC_contractDestination" setMarkerTextLocal (localize "STR_ALSPMC_contract_destination");
};
private _sector = _job getOrDefault ["sector", []];
deleteMarkerLocal "ALSPMC_contractSector";
if (count _sector == 2) then {
    createMarkerLocal ["ALSPMC_contractSector", _sector select 0];
    "ALSPMC_contractSector" setMarkerShapeLocal "ELLIPSE";
    "ALSPMC_contractSector" setMarkerSizeLocal [_sector select 1, _sector select 1];
    "ALSPMC_contractSector" setMarkerColorLocal "ColorYellow";
    "ALSPMC_contractSector" setMarkerAlphaLocal 0.2;
};

// Opt-in through our own missions; inert in unrelated missions.
private _s1 = getNumber (missionConfigFile >> "PMCS_Prototype" >> "enabled") == 1;
private _s2 = getNumber (missionConfigFile >> "PMCS_S2" >> "enabled") == 1;
if (!_s1 && {!_s2}) exitWith {};
if (isClass (configFile >> "CfgPatches" >> "als_main")) exitWith {
    diag_log "[PMCS] disable LifeSim and the old addon for this standalone test";
    if (hasInterface) then {hint localize "STR_PMCS_OLD_MOD"};
};
if (_s2) exitWith {
    if (isServer) then {call PMCS_fnc_s2ServerInit};
    if (hasInterface) then {
        [] spawn {
            private _deadline = diag_tickTime + 60;
            waitUntil {sleep 0.1; (!isNull player && {missionNamespace getVariable ["PMCS2_ready", false]}) || {diag_tickTime > _deadline}};
            if (isNull player || {!(missionNamespace getVariable ["PMCS2_ready", false])}) exitWith {
                hint localize "STR_PMCS_BOOT_TIMEOUT";
                diag_log "[PMCS S2] client startup timeout; check server RPT and matching mod/mission";
            };
            call PMCS_fnc_s2ClientInit;
        };
    };
};
if (isServer) then {call PMCS_fnc_serverInit};
if (hasInterface) then {
    [] spawn {
        private _deadline = diag_tickTime + 60;
        waitUntil {sleep 0.1; (!isNull player && {missionNamespace getVariable ["PMCS_ready", false]}) || {diag_tickTime > _deadline}};
        if (isNull player || {!(missionNamespace getVariable ["PMCS_ready", false])}) exitWith {
            hint localize "STR_PMCS_BOOT_TIMEOUT";
            diag_log "[PMCS S1] client startup timeout; check server RPT and matching mod/mission";
        };
        call PMCS_fnc_clientInit;
    };
};

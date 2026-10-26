[] spawn {
    waitUntil {sleep 0.1; missionNamespace getVariable ["ALS_ready", false]};

    // The English fallback in config is safe even before this initialization.
    private _license = ALS_licenses getOrDefault ["alspmc_pmc", []];
    if (_license isNotEqualTo []) then {
        _license set [0, localize "STR_ALSPMC_license_name"];
        _license set [4, localize "STR_ALSPMC_license_desc"];
    };

    if (isServer) then {call ALSPMC_fnc_serverInit};
    if (hasInterface) then {
        waitUntil {
            sleep 0.1;
            !isNull player && {
                missionNamespace getVariable ["ALSPMC_ready", false]
            }
        };
        call ALSPMC_fnc_clientInit;
    };
};

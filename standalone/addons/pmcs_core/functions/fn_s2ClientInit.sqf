if (!hasInterface || {missionNamespace getVariable ["PMCS2_clientStarted", false]}) exitWith {};
PMCS2_clientStarted = true;
uiNamespace setVariable ["PMCS2_state", createHashMap];
[] spawn {
    private _lastPoll = -10;
    while {true} do {
        if (!isNull player && {alive player}) then {
            // New unit after each respawn: console action and a test rifle.
            if !(player getVariable ["PMCS2_ready", false]) then {
                player setVariable ["PMCS2_ready", true];
                player addAction [localize "STR_PMCS2_OPEN", {call PMCS_fnc_s2Open}, nil, 0.5, false, true];
                if (primaryWeapon player == "") then {
                    player addMagazines ["30Rnd_65x39_caseless_mag", 6];
                    player addWeapon "arifle_MX_F";
                };
            };
            // Units of this group local here (player and its bots): rating stays
            // fixed, so a hit on an "ally" never turns them into renegades, and
            // their shots are reported for demasking.
            {
                if (local _x && {!(_x getVariable ["PMCS2_handlers", false])}) then {
                    _x setVariable ["PMCS2_handlers", true];
                    _x addEventHandler ["HandleRating", {0}];
                    _x addEventHandler ["Fired", {
                        if (diag_tickTime - (missionNamespace getVariable ["PMCS2_firedSent", -1e9]) >= 2) then {
                            PMCS2_firedSent = diag_tickTime;
                            [player] remoteExecCall ["PMCS_fnc_s2Event", 2];
                        };
                    }];
                };
            } forEach units group player;
        };
        if (!isNull (uiNamespace getVariable ["PMCS2_console", displayNull]) && {diag_tickTime - _lastPoll >= 1}) then {
            _lastPoll = diag_tickTime;
            [player, "status", ""] remoteExecCall ["PMCS_fnc_s2Request", 2];
        };
        sleep 0.5;
    };
};

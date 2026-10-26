if (!hasInterface || {missionNamespace getVariable ["PMCS_clientStarted", false]}) exitWith {};
PMCS_clientStarted = true; PMCS_sequence = 0;
PMCS_clientPrefix = str systemTimeUTC;
uiNamespace setVariable ["PMCS_state", createHashMap];
uiNamespace setVariable ["PMCS_pending", []];
[] spawn {
    disableSerialization;
    private _lastPoll = -10;
    while {true} do {
        {
            private _pc = _x;
            if (!isNull _pc && {!(_pc getVariable ["PMCS_actionAdded",false])}) then {
                _pc setVariable ["PMCS_actionAdded",true];
                _pc addAction [localize "STR_PMCS_OPEN", {params ["_target"]; [_target] call PMCS_fnc_openConsole},
                    nil, 2, true, true, "", "alive _this && {_this distance _target <= 4}", 3.5];
            };
        } forEach (missionNamespace getVariable ["PMCS_terminalPublic", []]);
        private _display = uiNamespace getVariable ["PMCS_console", displayNull];
        if (!isNull _display) then {
            private _pc = uiNamespace getVariable ["PMCS_computer", objNull];
            if (isNull _pc || {!alive player} || {player distance _pc > 4.5}) then {_display closeDisplay 2} else {
                if (diag_tickTime - _lastPoll >= 1) then {
                    _lastPoll = diag_tickTime;
                    [player,"","","status",-1,[],_pc] remoteExecCall ["PMCS_fnc_request",2];
                };
                private _pending = uiNamespace getVariable ["PMCS_pending", []];
                if (_pending isNotEqualTo [] && {diag_tickTime - (_pending select 1) > 10}) then {
                    uiNamespace setVariable ["PMCS_pending", []];
                    uiNamespace setVariable ["PMCS_localNotice", "STR_PMCS_TIMEOUT"];
                    call PMCS_fnc_renderConsole;
                };
            };
        };
        sleep 0.25;
    };
};

// LifeSim's staffed NPCs (clerks, clinic staff, shopkeepers, police posts) are
// mortal CIVILIAN units, and contract enemies are hostile to CIVILIAN. Near an
// operation they surrender as hostages: AI does not fire on captives. Native
// NPCs killed by contract enemies anyway reopen soon after the operation.
// Players' own crimes keep LifeSim's normal 30-minute rule.
params ["_action", ["_job", createHashMap], ["_args", []]];
if (!isServer || {isRemoteExecuted && {!isNil "_fnc_scriptNameParent"} && {_fnc_scriptNameParent == _fnc_scriptName}}) exitWith {false};
if (isNil "ALSPMC_hostages") then {ALSPMC_hostages = []};
if (isNil "ALSPMC_npcCasualties") then {ALSPMC_npcCasualties = []};
private _radius = (getNumber (configFile >> "ALSPMC_Settings" >> "contractHostageRadius")) max 100 min 1000;
private _hold = {
    params ["_unit", "_on"];
    if (_on) then {_unit setVariable ["ALSPMC_hostage", true]; ALSPMC_hostages pushBackUnique _unit} else {
        _unit setVariable ["ALSPMC_hostage", nil];
    };
    // LifeSim itself surrenders civilians through ACE captives; its own
    // behaviour scripts already leave surrendering units alone.
    if (!isNil "ace_captives_fnc_setSurrendered") then {[_unit, _on] call ace_captives_fnc_setSurrendered} else {
        _unit setCaptive _on;
        if (_on) then {_unit playMoveNow "AmovPercMstpSsurWnonDnon"} else {[_unit, ""] remoteExec ["switchMove", 0]};
    };
};
switch (_action) do {
    case "killed": {
        _args params ["_dead", "_killer", ["_instigator", objNull]];
        private _id = _dead getVariable "ALS_npc";
        if (isNil "_id") exitWith {};
        private _by = if (isNull _instigator) then {_killer} else {_instigator};
        private _qid = _by getVariable ["ALSPMC_contractEnemy", (vehicle _by) getVariable ["ALSPMC_contractEnemy", -1]];
        if (_qid isEqualType 0 && {_qid > 0}) then {ALSPMC_npcCasualties pushBack [_id, _qid]};
    };
    case "tick": {
        {
            private _enemy = _x select 0;
            if (!isNull _enemy && {alive _enemy}) then {
                {
                    if (alive _x && {!isPlayer _x} && {!isNil {_x getVariable "ALS_npc"}} && {
                        !(_x getVariable ["ALSPMC_hostage", false])
                    } && {!captive _x}) then {[_x, true] call _hold};
                } forEach (_enemy nearEntities [["CAManBase"], _radius]);
            };
        } forEach (_job getOrDefault ["alspmcEnemies", []]);
    };
    case "release": {
        // Shorten LifeSim's 30-minute closure only for this operation's casualties.
        private _qid = _job getOrDefault ["alspmcQuestId", -1];
        private _spots = missionNamespace getVariable ["ALS_npcSpots", createHashMap];
        private _delay = (getNumber (configFile >> "ALSPMC_Settings" >> "contractNpcRespawnSeconds")) max 30 min 1800;
        ALSPMC_npcCasualties = ALSPMC_npcCasualties select {
            _x params ["_id", "_by"];
            if (_by != _qid) then {true} else {
                private _spot = _spots getOrDefault [_id, createHashMap];
                if (count _spot > 0) then {
                    _spot set ["deadAt", ((_spot getOrDefault ["deadAt", time]) min (time - 1800 + _delay)) max 0];
                };
                false
            }
        };
    };
};
// Release hostages once no living enemy of any running operation is near.
private _enemies = [];
{
    {if (!isNull (_x select 0) && {alive (_x select 0)}) then {_enemies pushBack (_x select 0)}} forEach (_y getOrDefault ["alspmcEnemies", []]);
} forEach ALS_coopJobs;
ALSPMC_hostages = ALSPMC_hostages select {
    private _unit = _x;
    if (isNull _unit || {!alive _unit}) then {false} else {
        private _near = (_enemies findIf {_x distance _unit <= _radius + 50}) >= 0;
        if (!_near) then {[_unit, false] call _hold};
        _near
    }
};
true

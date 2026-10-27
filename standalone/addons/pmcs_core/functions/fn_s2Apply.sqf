// Bring a player's group to [colour, captive]. A side change moves the whole
// group (player first, so the player stays leader) into a new server-created
// group of that side. Captive is set on each machine for its local units.
params ["_p", "_r", "_want"];
_want params ["_color", "_captive", "_reason"];
private _sides = createHashMapFromArray [["west", west], ["east", east], ["guer", resistance], ["civ", civilian]];
private _side = _sides get _color;
private _uid = _r get "uid";
private _g = group _p;
private _sideChanged = side _g != _side;
if (_sideChanged) then {
    private _new = createGroup [_side, true];
    if (isNull _new) exitWith {
        _sideChanged = false;
        [format ["group limit: cannot create %1 group for %2", _color, _uid]] call PMCS_fnc_s2Log;
    };
    _new setVariable ["PMCS2_uid", _uid, true];
    private _settings = [formation _g, combatMode _g, behaviour leader _g];
    ([_p] + ((units _g) - [_p])) joinSilent _new;
    _g = _new;
    // Group settings and bot follow orders are lost with the old group.
    ([_g] + _settings) remoteExecCall ["PMCS_fnc_s2Regroup", owner _p];
};
if (_sideChanged && {side group _p != _side}) exitWith {
    [format ["side change for %1 to %2 did not take effect", _uid, _color]] call PMCS_fnc_s2Log;
};
private _now = diag_tickTime;
private _captiveChanged = !((captive _p) isEqualTo _captive);
// Captive replicates with a delay: resend at most every 3 seconds.
if (_captiveChanged && {_now - (_r get "captiveSentAt") >= 3}) then {
    _r set ["captiveSentAt", _now];
    [_g, _captive] remoteExecCall ["PMCS_fnc_s2Captive", 0];
};
private _stateChanged = _sideChanged || {!((_r get "captive") isEqualTo _captive)};
if (_stateChanged || {(_r get "reason") != _reason}) then {
    [format ["state %1: %2 captive=%3 -> %4 captive=%5 (%6)", _uid, _r get "color", _r get "captive", _color, _captive, _reason]] call PMCS_fnc_s2Log;
};
_r set ["color", _color]; _r set ["captive", _captive]; _r set ["reason", _reason];
if (_stateChanged) then {
    _r set ["changedAt", _now]; _r set ["firstShot", -1]; _r set ["lastShot", -1];
    // Optional: make nearby test posts re-evaluate this group at once instead
    // of keeping their old picture of its side.
    if (PMCS2_settings get "forget") then {
        {
            private _post = _y select 0;
            if (!isNull _post) then {{_post forgetTarget _x; _post reveal [_x, 1.5]} forEach units _g};
        } forEach PMCS2_posts;
    };
    [_p] call PMCS_fnc_s2Send;
};

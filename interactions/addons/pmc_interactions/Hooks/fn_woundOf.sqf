// [open wounds of one body part, ACE wound class names] -> [wound type, size 0-2], or
// ["", 0] when nothing there bleeds. Pure. Picks the wound ACE's bandage goes for first:
// the one losing the most blood (amount x bleeding). An ACE wound is [class ID, amount,
// bleeding, damage]; the class ID is 10 x type index + size (minor, medium, large).
params ["_wounds", "_classNames"];
private _best = ["", 0];
private _most = 0;
{
    _x params ["_classID", "_amount", "_bleeding"];
    if (_amount * _bleeding > _most) then {
        _most = _amount * _bleeding;
        _best = [_classNames param [floor (_classID / 10), ""], 0 max ((_classID % 10) min 2)];
    };
} forEach _wounds;
_best

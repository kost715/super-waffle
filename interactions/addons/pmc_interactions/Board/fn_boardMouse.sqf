// Client -> [x, y]: the mouse in scene pixels (the 1024 x 512 scene picture), from the
// scene's screen rectangle that PMCI_fnc_boardLayout stored.
(PMCI_board getOrDefault ["sceneScreen", [0, 0, 1, 1]]) params ["_sx", "_sy", "_w", "_h"];
getMousePosition params ["_mx", "_my"];
[(_mx - _sx) / _w * 1024, (_my - _sy) / _h * 512]

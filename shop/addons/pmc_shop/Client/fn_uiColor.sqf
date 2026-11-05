// [name] -> RGBA colour of the laptop's look (the ION site, desktop A).
params ["_name"];
if (isNil "PMCS_colors") then {
    PMCS_colors = createHashMapFromArray [
        ["screen", [0.933, 0.941, 0.925, 1]], ["white", [1, 1, 1, 1]], ["panel", [0.969, 0.973, 0.961, 1]],
        ["line", [0.839, 0.851, 0.824, 1]], ["tabs", [0.851, 0.863, 0.839, 1]], ["navy", [0.122, 0.165, 0.2, 1]],
        ["navy2", [0.071, 0.102, 0.129, 1]], ["navyText", [0.78, 0.816, 0.847, 1]], ["navyMuted", [0.624, 0.69, 0.749, 1]],
        ["orange", [0.851, 0.51, 0.169, 1]], ["orangeDark", [0.71, 0.337, 0.11, 1]], ["orangePale", [0.984, 0.918, 0.867, 1]],
        ["text", [0.114, 0.129, 0.145, 1]], ["grey", [0.29, 0.314, 0.337, 1]], ["green", [0.184, 0.373, 0.165, 1]],
        ["red", [0.62, 0.16, 0.12, 1]], ["photo", [0.949, 0.953, 0.937, 1]], ["bezel", [0.09, 0.094, 0.102, 1]],
        ["desk", [0.122, 0.165, 0.2, 1]], ["dim", [0, 0, 0, 0.72]], ["clear", [0, 0, 0, 0]], ["iconSel", [0.231, 0.322, 0.4, 0.85]]
    ];
};
+(PMCS_colors getOrDefault [_name, [1, 0, 1, 1]])

// [] -> an empty market (nothing changed from the catalog): the catalog's box discount.
createHashMapFromArray [["items", createHashMap], ["custom", createHashMap], ["cats", createHashMap], ["global", 0],
    ["box", (call PMCS_fnc_catalog) get "boxDiscount"], ["log", []]]

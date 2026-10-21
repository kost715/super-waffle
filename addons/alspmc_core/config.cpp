class CfgPatches {
    class alspmc_core {
        name = "LifeSim PMC - Headquarters";
        author = "LifeSim PMC project";
        requiredVersion = 2.20;
        requiredAddons[] = {"als_main", "cba_main"};
        units[] = {};
        weapons[] = {};
    };
};

// Native licInit and licPush enumerate this class on every machine.
class ALS_Licenses {
    class alspmc_pmc {
        name = "PMC establishment license";
        desc = "Establish a PMC and buy a vacant warehouse as its base.";
        price = 1;
        rank = 0;
        covers[] = {};
    };
};

class ALSPMC_Settings {
    basePrice = 1;
    allowedTypes[] = {"Industrial"};
    terminalDesk = "Land_TableDesk_F";
    terminalScreen = "Land_PCSet_01_screen_F";
    terminalCase = "Land_PCSet_01_case_F";
    terminalKeyboard = "Land_PCSet_01_keyboard_F";
    questPay = 1000;
    questMinDistance = 600;
    questMaxDistance = 6000;
    contractMinBaseDistance = 2000;
    questTimeout = 1800;
    ratingThresholds[] = {0, 100, 300, 700, 1300};
    contractPoolSeconds = 600;
    contractPoolGovernment = 4;
    contractPoolPrivate = 2;
    contractPatrolPoints = 4;
    contractPatrolPointRadius = 35;
    contractAttackChance = 0.65;
    contractMineChance = 0.8;
    contractDutySeconds = 600;
    contractSurveySeconds = 60;
    contractSectorRadius = 250;
    contractReadyRadius = 150;
    contractPermanentCasualties = 0;
    contractRewardMultipliers[] = {1, 1.5, 2, 3, 4};
};

class ALSPMC_ContractRewards {
    class gov_bandits {reward = 4000; xp = 10;};
    class gov_convoy {reward = 5000; xp = 15;};
    class gov_guard {reward = 4500; xp = 10;};
    class gov_base {reward = 18000; xp = 25;};
    class gov_patrol {reward = 10000; xp = 15;};
    class gov_sector {reward = 3500; xp = 10;};
    class gov_mines {reward = 3000; xp = 10;};
    class private_convoy {reward = 4500; xp = 15;};
    class private_guard {reward = 4000; xp = 10;};
    class private_vip {reward = 6000; xp = 15;};
};

class CfgFunctions {
    class ALSPMC {
        tag = "ALSPMC";
        class Core {
            file = "\alspmc_core\functions";
            class postInit {postInit = 1;};
            class serverInit {};
            class clientInit {};
            class clientTick {};
            class buyBase {};
            class requestAllowed {};
            class message {};
            class stateSet {};
            class save {};
            class reconcile {};
            class applyValues {};
            class sellHouse {};
            class phoneMsg {};
            class phoneBridge {};
            class phoneDo {};
            class phoneSync {};
            class normalizeName {};
            class setName {};
            class markBase {};
            class terminalInit {};
            class terminalSync {};
            class terminalEnsure {};
            class terminalRemove {};
            class terminalFindSpot {};
            class terminalCanUse {};
            class desktopOpen {};
            class desktopTick {};
            class desktopDo {};
            class desktopView {};
            class questInit {};
            class questSave {};
            class questDo {};
            class questState {};
            class questSite {};
            class questScenario {};
            class questKilled {};
            class questMarker {};
            class contractInit {};
            class contractSave {};
            class contractCatalog {};
            class contractProfile {};
            class contractSites {};
            class contractPlan {};
            class contractBase {};
            class contractFar {};
            class contractTeam {};
            class contractAttack {};
            class contractEquip {};
            class contractReady {};
            class contractScenario {};
            class contractTick {};
            class contractMirror {};
            class contractEnd {};
            class contractAssets {};
            class contractBoss {};
            class contractHostility {};
            class contractOffers {};
            class contractGarrison {};
            class contractWarBases {};
        };
    };
};

// Add only our RPCs. Do not change the mission's global remote-exec mode.
class CfgRemoteExec {
    class Functions {
        class ALSPMC_fnc_buyBase {allowedTargets = 2; jip = 0;};
        // 0: LifeSim is usually hosted by a player, whose machine is the server.
        class ALSPMC_fnc_message {allowedTargets = 0; jip = 0;};
        class ALSPMC_fnc_stateSet {allowedTargets = 0; jip = 0;};
        class ALSPMC_fnc_phoneDo {allowedTargets = 2; jip = 0;};
        class ALSPMC_fnc_desktopDo {allowedTargets = 2; jip = 0;};
    };
};

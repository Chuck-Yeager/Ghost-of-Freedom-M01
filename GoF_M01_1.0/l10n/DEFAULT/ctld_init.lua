local INFANTRY_SQUAD = {        
    inf = 2,
    mg = 1,
    at = 4
}

local MORTAR_SQUAD = {
    mg =1,
    aa = 1,
    mortar = 5
}

ctld.preLoadTransport("1-1/A", INFANTRY_SQUAD, true)
ctld.preLoadTransport("6-6/A", INFANTRY_SQUAD, true)



local numCompaniesSpawned = 0
local NUM_RESERVE_COMPANIES = 6
local MIN_ALIVE_TANK_COUNT = 31

local RESERVE_CO_TEMPLATES = {"Russian Reserve Tank CO-1", "Russian Reserve Tank CO-2", "Russian Reserve Tank CO-3",
                              "Russian Reserve Mech Inf Platoon"}

local reserveUnits = {}

local function spawnNewCompany()
    for _, templateName in ipairs(RESERVE_CO_TEMPLATES) do
        local suffix = (numCompaniesSpawned + 1) .. "/" .. NUM_RESERVE_COMPANIES
        local alias = templateName .. " " .. suffix
        env.info("Spawning " .. alias)
        local group = SPAWN:NewWithAlias(templateName, alias):Spawn()
    end
    numCompaniesSpawned = numCompaniesSpawned + 1
end

local function checkUnitsAlive()
    if numCompaniesSpawned >= NUM_RESERVE_COMPANIES then
        return
    end

    local tankCount = 0
    local function incrementTankCountForGroup(group)
        local numAliveUnits = group:CountAliveUnits()
        local hasUnits = numAliveUnits > 0
        if hasUnits and group:GetUnit(1):GetTypeName() == "T-72B" then
            tankCount = tankCount + numAliveUnits
        end
    end

    _DATABASE:ForEachGroup(incrementTankCountForGroup)
    env.info("Found " .. tankCount .. " tanks alive")

    if tankCount < MIN_ALIVE_TANK_COUNT then
        env.info("Found fewer than " .. MIN_ALIVE_TANK_COUNT .. " tanks alive, spawning a new reserve company")
        spawnNewCompany()
    end
end

local unitAliverTimer = TIMER:New(checkUnitsAlive)
unitAliverTimer:Start(nil, 60)
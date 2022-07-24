local PRELOAD_DISMOUNT_COMPOSITIONS = {
    ["M-2 Bradley"] = {
        mortar = 5,
        at = 1,
        mg = 1
    },
    ["M1126 Stryker ICV"] = {
        inf = 2,
        mg = 1,
        at = 5,
        aa = 1
    }
}

local function contains(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local function hasKey(tab, idx)
    return tab[idx] ~= nil
end

local function groupHasDismounts(groupName)
    -- make sure the group name follows the pattern n-m/Z
    -- where n and m are numbers and Z is a letter.
    local hasDash = groupName:sub(2, 2) == "-"
    local hasSlash = groupName:sub(4, 4) == "/"
    local platoonIndex = groupName:sub(1, 1)
    local companyName = groupName:sub(5, 5)
    local inTransportGroup = contains(ctld.transportPilotNames, groupName)
    return hasDash and hasSlash and inTransportGroup
end

local function shouldPreload(group)
    local unit = group:getUnit(1)
    unitType = unit:getTypeName()
    local isAppropriateVehicle = hasKey(PRELOAD_DISMOUNT_COMPOSITIONS, unitType)
    local isAppropriateGroup = groupHasDismounts(group:getName())
    return isAppropriateVehicle and isAppropriateGroup
end

local allBlueGroundGroups = coalition.getGroups(2, Group.Category.GROUND)

for _, group in pairs(allBlueGroundGroups) do
    if shouldPreload(group) then
        env.info("Preloading " .. group:getName())
        local unitType = group:getUnit(1):getTypeName()
        local dismountComposition = PRELOAD_DISMOUNT_COMPOSITIONS[unitType]
        ctld.preLoadTransport(group:getName(), dismountComposition, true)
    end
end

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

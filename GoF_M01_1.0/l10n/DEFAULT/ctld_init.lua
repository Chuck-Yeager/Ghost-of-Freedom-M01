local PRELOAD_DISMOUNT_COMPOSITIONS = {
    ["M-2 Bradley"] = {
        inf = 3,
        at = 4
    },
    ["Stryker"] = {
        inf = 4,
        at = 5
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

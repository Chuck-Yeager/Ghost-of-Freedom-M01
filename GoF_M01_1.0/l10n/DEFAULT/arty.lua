local RU_MLRS_NAME = "Russian MLRS BTRY"
local RU_ARTY_NAMES = {"Russian 2S19 BTRY-1", "Russian 2S19 BTRY-2", "Russian 2S19 BTRY-3"}
local US_MLRS_NAME = "Blue M270 BTRY"
local US_ARTY_NAMES = {"Blue T155 BTRY", "Blue 109 BTRY"}

ARTY:SetDebugOFF()
ARTY:SetMarkAssignmentsOn()
local allArties = {}
local allRedArties = {}

-- create RU artillery
local ruArtyCount = 1
for _, unit in ipairs(RU_ARTY_NAMES) do
    local name = "msta" .. tostring(ruArtyCount)
    local arty = ARTY:New(unit, name):AddToCluster("ru_arty")
    table.insert(allArties, arty)
    table.insert(allRedArties, arty)
    ruArtyCount = ruArtyCount + 1
end

-- create RU MLRS
ru_mlrs = ARTY:New(GROUP:FindByName(RU_MLRS_NAME), "smerch"):AddToCluster("ru_mlrs")
table.insert(allRedArties, ru_mlrs)

-- create US artillery
local usArtyCount = 1
for _, unit in ipairs(US_ARTY_NAMES) do
    local name = "us" .. tostring(usArtyCount)
    local arty = ARTY:New(unit, name):AddToCluster("us_arty")
    table.insert(allArties, arty)
    usArtyCount = usArtyCount + 1
end

-- create US MLRS
us_mlrs = ARTY:New(GROUP:FindByName(US_MLRS_NAME), "m270"):AddToCluster("us_mlrs")

-- start MLRS
ru_mlrs:Start()
us_mlrs:Start()


-- start arties
for _, arty in ipairs(allArties) do
    arty:Start()
end

-- automatic red artillery
local function copyTable(sourceTable)
    tableCopy = {}
    for orig_key, orig_value in pairs(sourceTable) do
        tableCopy[orig_key] = orig_value
    end
    return tableCopy
end

local function valuesToArray(tab)
    local arr = {}
    for k, v in pairs(tab) do
        table.insert(arr, v)
    end
    return arr
end

local function keysToArray(tab)
    local arr = {}
    for k, v in pairs(tab) do
        table.insert(arr, k)
    end
    return arr
end

function selectRandom(t)
    return t[math.random(1, #t)]
end
 

local function artyDetectionStateMachine(side, arties)
    local ARTY_DETECT_STATE = {
        PREP_UNIT_ARRAYS = 0,
        FETCHING_DETECTION_UNITS = 1,
        ASSIGN_FIRE_MISSIONS = 2
    }
    

    local otherSide = nil
    if side == coalition.side.BLUE then
        otherSide = coalition.side.RED
    else
        otherSide = coalition.side.BLUE
    end

    local unitIndex = 1
    local allUnits = {}
    local detectedUnits = {}

    local state = ARTY_DETECT_STATE.PREP_UNIT_ARRAYS

    local function prepUnitArray()
        allUnits = {}
        for _, unit in pairs(_DATABASE.UNITS) do
            if unit:GetCoalition() == side then
                table.insert(allUnits, unit)
            end
        end
        state = ARTY_DETECT_STATE.FETCHING_DETECTION_UNITS
        detectedUnits = {}
        return 1
    end

    local ARTY_RANGES_BY_TYPE = {
        ["SAU Msta"] = {30, 23500},
        ["SAU Gvozdika"] = {30, 15000},
        ["Smerch"] = {20000, 70000},
        ["SAU 2-C9"] = {30, 15000},
        ["2S3 Akatsia"] = {30, 17000},
        ["T155_Firtina"] = {30, 41000},
        ["M-109"] = {30, 22000},
        ["MLRS"] = {10000, 32000},
        ["Grad-URAL"] = {5000, 19000},
        ["Uragan_BM-27"] = {11500, 35800}
    }
    
    local function isWithinRange(unit, artyGroup)
        local units = artyGroup:GetUnits()
        local artyRange = nil
        local unitIdx = 1
        while artyRange == nil and unitIdx < #units do
            local unit = units[unitIndex]
            artyRange = ARTY_RANGES_BY_TYPE[unit:GetTypeName()]
        end
        if artyRange == nil then
            return false
        end
        local minRange = artyRange[1]
        local maxRange = artyRange[2]
        local unitPos = unit:GetCoordinate()
        local artyPos = artyGroup:GetUnit(1):GetCoordinate()
        local distance = artyPos:Get2DDistance(unitPos)
        return distance >= minRange and distance <= maxRange
    end

    local function assignFireMission(arty, detectedUnitIds)
        local candidateUnitsIds = copyTable(detectedUnitIds)

        local artyGroup = GROUP:FindByName(arty.groupname)
        if not artyGroup then
            return
        end

        while #candidateUnitsIds > 0 do
            local idx = math.random(1, #candidateUnitsIds)
            local unit = detectedUnits[candidateUnitsIds[idx]]
            if isWithinRange(unit, artyGroup) then
                env.info("Assigning automatic fire mission for " .. arty.groupname .. " targeting " .. unit:GetName())
                arty:AssignTargetCoord(unit:GetCoordinate(), 100, 100, 20, 1) 
                return
            end
            table.remove(candidateUnitsIds, idx)
        end
    end

    local function fetchingDetectedUnits()
        local unit = nil
        if unitIndex > #allUnits then
            unitIndex = 1
            state = ARTY_DETECT_STATE.ASSIGN_FIRE_MISSIONS
        end

        unit = allUnits[unitIndex]
         -- only fetch units detected visually, optically, or with radar
        local detectedByThisUnit = unit:GetDetectedUnitSet(true, true, true, false, false, false)
        detectedByThisUnit:ForEachUnit(function(detectedUnit)
            if not detectedUnit:IsGround() then
                return
            end
            
            local isStopped = detectedUnit:GetVelocityMPS() < 0.01
            -- this check seems to be not needed, since GetDetectedUnitSet only returns hostiles
            local isOtherSide = detectedUnit:GetCoalition() == otherSide
            if isOtherSide and isStopped then
                local id = detectedUnit:GetID()
                if not detectedUnits[id] then
                    -- env.info("Adding unit " .. detectedUnit:GetName() .. " with ID " .. id .. " to detected units")
                    detectedUnits[id] = detectedUnit
                end
                detectedUnits[detectedUnit:GetID()] = detectedUnit
            end
        end)

        unitIndex = unitIndex + 1

        return .03
    end

    local function assignFireMissions()
        local detectedUnitIds = keysToArray(detectedUnits)
        for _, arty in ipairs(arties) do
            if arty:GetState() == "CombatReady" then
                assignFireMission(arty, detectedUnitIds)
            end
        end
        state = ARTY_DETECT_STATE.FETCHING_DETECTION_UNITS
        return 20
    end

    local stateHandlers = {
        [ARTY_DETECT_STATE.PREP_UNIT_ARRAYS] = prepUnitArray,
        [ARTY_DETECT_STATE.FETCHING_DETECTION_UNITS] = fetchingDetectedUnits,
        [ARTY_DETECT_STATE.ASSIGN_FIRE_MISSIONS] = assignFireMissions,
    }

    local function stateHandler()
        local prevState = state
        local delay = stateHandlers[state]()
        -- if prevState ~= state then
        --     env.info("AutoArty state changed from " .. prevState .. " to " .. state .. " with delay " .. delay)
        -- end
        timer.scheduleFunction(stateHandler, {}, timer.getTime() + delay)
    end

    stateHandler()

end

artyDetectionStateMachine(coalition.side.RED, allRedArties)


local RU_MLRS_NAME = "Russian MLRS BTRY"
local RU_ARTY_NAMES = {"Russian 2S19 BTRY-1", "Russian 2S19 BTRY-2", "Russian 2S19 BTRY-3"}
local US_MLRS_NAME = "Blue M270 BTRY"
local US_ARTY_NAMES = {"Blue T155 BTRY", "Blue 109 BTRY"}

ARTY:SetDebugOFF()
ARTY:SetMarkAssignmentsOn()
allArties = {}

-- create RU artillery
local ruArtyCount = 1
for _, unit in ipairs(RU_ARTY_NAMES) do
    local name = "msta" .. tostring(ruArtyCount)
    local arty = ARTY:New(unit, name):AddToCluster("ru_arty")
    table.insert(allArties, arty)
    ruArtyCount = ruArtyCount + 1
end

-- create RU MLRS
ru_mlrs = ARTY:New(GROUP:FindByName(RU_MLRS_NAME), "smerch"):AddToCluster("ru_mlrs")

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

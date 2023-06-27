import "scripts/animatedSprite"

local pd <const> = playdate
local gfx <const> = pd.graphics

class('Entity').extends("AnimatedSprite")

function Entity:init(imagetable, tickStepTable, states)
    Entity.super.init(self, imagetable)

    self.defaultTickStepTable = tickStepTable
    self.tickStepTable = tickStepTable
    self.statesTable = states
    self.yAcceleration = 1
end

-- for manual GSM updates
function Entity:updateGSM()
    if inputsForGSM then
        if pd.buttonJustPressed(pd.kButtonA) then
            self:increaseGSM()
        elseif pd.buttonJustPressed(pd.kButtonB) then
            self:decreaseGSM()
        elseif pd.buttonJustPressed(pd.kButtonDown) then
            self:setGSM()
        end
    end
end

-- increases GSM by default at 5 unless told otherwise
function Entity:increaseGSM(value)
    if value == nil then value = 5 end
    gameSpeed += 5
    self:updateTickStep()
end

-- decreases GSM by default at 5 unless told otherwise
function Entity:decreaseGSM(value)
    if value == nil then value = 5 end
    self.storedYAcceleration = self.yAcceleration
    gameSpeed -= 5
    if gameSpeed == 0 then -- for some reason, doesn't work with GSM but idk why rn 4/14/23
        self:stopTickStep()
    else
        self:updateTickStep()
    end
end

-- sets states to their value according to the tick step table
function Entity:updateStates()
    updateStates = true
end

-- set your value,
-- if value = nil then GSM will be set to default
function Entity:setGSM(value, table)
    if value == nil then value = defaultGameSpeed end
    gameSpeed = value
    return self:updateTickStep(table)
end

-- sets tickstep values to default values
function Entity:resetTickStep(table)
    for i = 1, #self.defaultTickStepTable do
        self.tickStepTable[i] = self.defaultTickStepTable[i]
    end
end

-- sets tickstep values high enough to simulate a pause,
-- couldn't figure out animatedsprite's pause function.
function Entity:stopTickStep(table)
    for i = 1, #self.tickStepTable do
        self.tickStepTable[i] = 10000
    end
    self:updateStates()
end

-- sets tickstep values in accordance to GSM
function Entity:updateTickStep(table)
    local currentTimeGSM = gameSpeed/fps
    --[[lua is being finnicky and it seems that
    the real GSM updates after all of these calculations are done
    which leads to wrong numbers and small bugs. This is a workaround.]]

    local inverseGSM = 1/currentTimeGSM
    if currentTimeGSM > 0 then
        --self:resetTickStep()
        for i = 1, #table do
            table[i] *= inverseGSM
            table[i] = math.ceil(table[i])
        end
    end
    self:updateStates()
    return table
end
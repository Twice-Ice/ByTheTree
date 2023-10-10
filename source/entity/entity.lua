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
end

-- decreases GSM by default at 5 unless told otherwise
function Entity:decreaseGSM(value)
    if value == nil then value = 5 end
    gameSpeed -= 5
end

-- set your value,
-- if value = nil then GSM will be set to default
-- value should be between >0 and 1
function Entity:setGSM(value)
    if value == nil then value = defaultGameSpeed end

    gameSpeed = value
end
import "scripts/AnimatedSprite"

local pd <const> = playdate
local gfx <const> = pd.graphics

class("Spike").extends("AnimatedSprite")

function Spike:init(player)
    -- initializations
    local SpikeTable = gfx.imagetable.new("entity/player/playerImages/slash-table-32-32")
    Spike.super.init(self, SpikeTable)
    self:setCollideRect(10, 10, 10, 10)
    self:setZIndex(ZIndexTable.Spike)


    -- starting angle/location calculations
    self.player = player
    self.angle = (pd.getCrankPosition() - 90)
    self.angleChange = 0
    self.distance = 50
    self.spikeXCoordinate = self.distance * math.cos(self.angle/(180/math.pi))
    self.spikeYCoordinate = self.distance * math.sin(self.angle/(180/math.pi))
    if self.spikeYCoordinate > ground + 5 then
        self.spikeYCoordinate -= (self.spikeYCoordinate - (ground + 5)) 
    end

    self:moveTo(realPlayerX + math.ceil(self.spikeXCoordinate), realPlayerY + math.ceil(self.spikeYCoordinate))

    self:setStates({
        {
            name = "aimSpike",
            firstFrameIndex = 1,
            framesCount = 1,
            tickStep = 0
        },
        {
            name = "spike",
            firstFrameIndex = 1,
            framesCount = 1,
            tickStep = 0
        }
    }, true, "aimSpike")
end

function Spike:update()
    self:handleState()

    -- updates player.angle to the correct angle in order to tell the player where to go when in "spike" state
    spikeAngle = self.angle
end

function Spike:handleState()
    self.currentState = self.player.currentState

    if self.currentState == "aimSpike" then
        self:handleSpikeAimInput()
    elseif self.currentState == "spike" then
        self:handleSpikeInput()
    else
        self:remove()
    end
end

function Spike:handleSpikeAimInput()
    -- the -90 is to account for the up and down of the crank being different from the numerical up and down
    self.angle = (pd.getCrankPosition() - 90)

    self.spikeXCoordinate = math.ceil(self.distance * math.cos(self.angle/(180/math.pi)))
    self.spikeYCoordinate = math.ceil(self.distance * math.sin(self.angle/(180/math.pi)))

    -- acounts for visual size of sprite - the number (5) can be changed based on the visual size of the sprite
    if self.spikeYCoordinate > ground + 5 then
        self.spikeYCoordinate -= (self.spikeYCoordinate - (ground + 5))
    end

    self:moveTo(realPlayerX + self.spikeXCoordinate, realPlayerY + self.spikeYCoordinate)

    self:setRotation(self.angle)
end

function Spike:handleSpikeInput()
    -- these values will need to be tweaked when the actual sprite for this attack is drawn in.

    local spikeXCoordinate = math.ceil(self.spikeXCoordinate / 5)
    local spikeYCoordinate = math.ceil(self.spikeYCoordinate / 5)

    self:moveTo(realPlayerX + spikeXCoordinate, realPlayerY + spikeYCoordinate)
end
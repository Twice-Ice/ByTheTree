import "scripts/AnimatedSprite"

local pd <const> = playdate
local gfx <const> = pd.graphics

class('Slash').extends("AnimatedSprite")

function Slash:init(x, direction, duration)
    local slashTable = gfx.imagetable.new("entity/player/playerImages/slash-table-32-32")
    Slash.super.init(self, slashTable)

    self.playerY = realPlayerY
    self.checkYPosition = false
    self.direction = direction
    self.spawnX = x

    self:setZIndex(ZIndexTable.Slashes)
    self:setStates({
        {
            name = "slash",
            firstFrameIndex = 1,
            framesCount = 1,
            tickStep = 0
        }
    }, true, "slash")

    pd.timer.performAfterDelay(duration, function ()
        self:remove()
    end)
end

function Slash:update()
    self:updateAnimation()
    self.playerY = realPlayerY

    if self.direction == "left" then
        self:moveTo(self.spawnX - 16, self.playerY)
        self.globalFlip = 1
    elseif self.direction == "right" then
        self:moveTo(self.spawnX + 16, self.playerY)
    elseif self.direction == "down" then
        self:moveTo(self.spawnX, self.playerY + 20)
    end
    
    if self.y == ground - 30 then
        self:remove()
    end
end
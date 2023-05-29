local pd <const> = playdate
local gfx <const> = pd.graphics

class('Bush').extends("AnimatedSprite")

function Bush:init(x, y, startLocationNum)
    local bushTable = gfx.imagetable.new("environment/environmentImages/bush-table-100-30")
    Bush.super.init(self, bushTable)
    self:moveTo(x, y)
    self:setZIndex(ZIndexTable.Bush)

    self.realX = x
    self.distanecToPlayer = self.realX - playerX

    self:setStates({
        {
            name = "bush1",
            firstFrameIndex = 1,
            framesCount = 1
        },
        {
            name = "bush2",
            firstFrameIndex = 2,
            framesCount = 1
        },
        {
            name = "bush3",
            firstFrameIndex = 3,
            framesCount = 1
        },
    }, true)
end
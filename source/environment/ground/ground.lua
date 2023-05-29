local pd <const> = playdate
local gfx <const> = pd.graphics

class('Ground').extends("AnimatedSprite")


-- most of this should be able to be coppied over to any other environmental assets if needed


function Ground:init(x, y, parallaxPercentage, zIndex, startLocationNum)
    local groundTable = gfx.imagetable.new("environment/environmentImages/groundTile-table-40-20")
    Ground.super.init(self, groundTable)
    self:moveTo(x, y)
    self:setZIndex(zIndex)

    self.y = y
    self.realX = x
    self.distanceToPlayer = self.realX - playerX
    self.parallaxPercentage = parallaxPercentage

    self:setStates({
        {
            name = "ground1",
            firstFrameIndex = 1,
            framesCount = 1,
            tickstep = 1
        },
        {
            name = "ground2",
            firstFrameIndex = 2,
            framesCount = 1,
            tickstep = 1
        },
        {
            name = "ground3",
            firstFrameIndex = 3,
            framesCount = 1,
            tickstep = 1
        },
        {
            name = "ground4",
            firstFrameIndex = 4,
            framesCount = 1,
            tickstep = 1
        }
    }, true)

    self.location = startLocationNum
    groundTileTable[self.location] = math.random(1, 4)
    self:changeGroundImage(groundTileTable[self.location])
end

function Ground:changeGroundImage(groundNumber)
    if groundNumber == 1 then
        self:changeState("ground1")
    elseif groundNumber == 2 then
        self:changeState("ground2")
    elseif groundNumber == 3 then
        self:changeState("ground3")
    elseif groundNumber == 4 then
        self:changeState("ground4")
    end
end

function Ground:loadTile(posNeg)
    if posNeg == "pos" then
        self.location += 11
    elseif posNeg == "neg" then
        self.location -= 11
    end

    if groundTileTable[self.location] == nil then
        groundTileTable[self.location] = math.random(1,4)
        self:changeGroundImage(groundTileTable[self.location])
    else
        self:changeGroundImage(groundTileTable[self.location])
    end
end

function Ground:update()
    self.distanceToPlayer = self.realX - (playerX * self.parallaxPercentage)
    self:moveTo(self.distanceToPlayer, self.y)
    
    if self.x >= 440 then
        self.realX -= 480
        self:loadTile("neg")
    elseif self.x <= -40 then
        self.realX += 480
        self:loadTile("pos")
    end
end
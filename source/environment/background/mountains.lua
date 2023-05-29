local pd <const> =  playdate
local gfx <const> = pd.graphics

class("Mountains").extends("AnimatedSprite")

function Mountains:init(x, y, startLocationNum, startMountainsType, parallaxPercentage, zIndex)
    local mountainsTable = gfx.imagetable.new("environment/environmentImages/mountainsTableTest-table-100-240")
    Mountains.super.init(self, mountainsTable)
    self:moveTo(x, y)
    self:setZIndex(zIndex)

    self:setCollideRect(0, 0, 100, 240)

    self.y = y
    self.realX = x
    self.distanceToPlayer = self.realX - playerX
    self.location = startLocationNum
    self.parallaxPercentage = parallaxPercentage

    self:setStates({
        {
            name = "mountains1A",
            firstFrameIndex = 1,
            framesCount = 1
        },
        {
            name = "mountains1B",
            firstFrameIndex = 2,
            framesCount = 1
        },
        {
            name = "mountains1C",
            firstFrameIndex = 3,
            framesCount = 1
        },
        {
            name = "mountains2A",
            firstFrameIndex = 4,
            framesCount = 1
        },
        {
            name = "mountains2B",
            firstFrameIndex = 5,
            framesCount = 1
        },
        {
            name = "mountains2C",
            firstFrameIndex = 6,
            framesCount = 1
        },
        {
            name = "mountains3A",
            firstFrameIndex = 7,
            framesCount = 1
        },
        {
            name = "mountains3B",
            firstFrameIndex = 8,
            framesCount = 1
        },
        {
            name = "mountains3C",
            firstFrameIndex = 9,
            framesCount = 1
        },
        {
            name = "mountains4A",
            firstFrameIndex = 10,
            framesCount = 1
        },
        {
            name = "mountains4B",
            firstFrameIndex = 11,
            framesCount = 1
        },
        {
            name = "mountains4C",
            firstFrameIndex = 12,
            framesCount = 1
        }
    }, true)

    self:setMountainsImage(startMountainsType)
end

-- [1, 12] only
function Mountains:setMountainsImage(mountainsNumber)
    if mountainsNumber == 1 then
        self:changeState("mountains1A")
    elseif mountainsNumber == 2 then
        self:changeState("mountains1B")
    elseif mountainsNumber == 3 then
        self:changeState("mountains1C")
    elseif mountainsNumber == 4 then
        self:changeState("mountains2A")
    elseif mountainsNumber == 5 then
        self:changeState("mountains2B")
    elseif mountainsNumber == 6 then
        self:changeState("mountains2C")
    elseif mountainsNumber == 7 then
        self:changeState("mountains3A")
    elseif mountainsNumber == 8 then
        self:changeState("mountains3B")
    elseif mountainsNumber == 9 then
        self:changeState("mountains3C")
    elseif mountainsNumber == 10 then
        self:changeState("mountains4A")
    elseif mountainsNumber == 11 then
        self:changeState("mountains4B")
    elseif mountainsNumber == 12 then
        self:changeState("mountains4C")
    end
end

function Mountains:newRightTile(tileNumber)
    local mountainsType = nil
	local currentMountainsTile = math.ceil(mountainsTileTable[tileNumber - 1]/3)

	if currentMountainsTile == 1 or currentMountainsTile == 3 then
		rng = math.random(1, 4) -- 1, 2
        if rng <= 3 then
            mountainsType = 2
        elseif rng == 4 then
            mountainsType = 1
        end
	elseif currentMountainsTile == 2 or currentMountainsTile == 4 then
		mountainsType = math.random(1, 4) -- 3, 4
        if rng <= 3 then
            mountainsType = 3
        elseif rng == 4 then
            mountainsType = 4
        end
	end

	mountainsTileTable[tileNumber] = ((mountainsType * 3) - 2) + math.random(0, 2)
    self:setMountainsImage(mountainsTileTable[tileNumber])
end

function Mountains:newLeftTile(tileNumber)
    local mountainsType = nil
	local currentMountainsTile = math.ceil(mountainsTileTable[tileNumber + 1]/3)

	if currentMountainsTile == 1 or currentMountainsTile == 2 then
		rng = math.random(1, 4) -- 1, 3
        if rng <= 3 then
            mountainsType = 3
        elseif rng == 4 then
            mountainsType = 1
        end
	elseif currentMountainsTile == 3 or currentMountainsTile == 4 then
		mountainsType = math.random(1, 4) -- 2, 4
        if rng <= 3 then
            mountainsType = 2
        elseif rng == 4 then
            mountainsType = 4
        end
	end

	mountainsTileTable[tileNumber] = ((mountainsType * 3) - 2) + math.random(0, 2)
    self:setMountainsImage(mountainsTileTable[tileNumber])
end

function Mountains:update()
    self.distanceToPlayer = self.realX - (playerX * self.parallaxPercentage)
    self:moveTo(self.distanceToPlayer, self.y)

    if self.x >= 500 then
        self.realX -= 600
        self.location -= 6
        self:setMountainsImage(mountainsTileTable[self.location])
    elseif self.x <= -100 then
        self.realX += 600
        self.location += 6
        self:setMountainsImage(mountainsTileTable[self.location])
    end
end
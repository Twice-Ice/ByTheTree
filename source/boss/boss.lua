local pd <const> = playdate
local gfx <const> = pd.graphics

class('Boss').extends('AnimatedSprite')

function Boss:init(x, y)
    local bossTable = gfx.imagetable.new("boss/bossImages/boss-table-32-32")
    Boss.super.init(self, bossTable)
    self:setZIndex(ZIndexTable.Boss)
    
    self.tickStepTable = {
        rest = 10,
        dash = 1,
        follow = 4,
        slash = 1,
        jumpSlash = 1,
        spinSlash = 1,
        teleport = 1,
        smokeBomb = 1,
        flury = 1,
        shuriken = 1,
        stompShock = 1
    }

    -- need to set up buildup for all of these attacks.
    self:setStates({
        {
            name = "rest",
            firstFrameIndex = 1,
            framesCount = 3,
            tickStep = self.tickStepTable.rest,
            yoyo = true
        },
        {
            name = "dash",
            firstFrameIndex = 9,
            framesCount = 1,
            tickStep = self.tickStepTable.dash,
        },
        {
            name = "follow",
            firstFrameIndex = 4,
            framesCount = 5,
            tickStep = self.tickStepTable.follow,
        },
        {
            name = "slash",
            firstFrameIndex = 10,
            framesCount = 1,
            tickStep = self.tickStepTable.slash,
        },
        {
            name = "jumpSlash",
            firstFrameIndex = 1,
            framesCount = 1,
            tickStep = self.tickStepTable.jumpSlash,
        },
        {
            name = "spinSlash",
            firstFrameIndex = 1,
            framesCount = 1,
            tickStep = self.tickStepTable.spinSlash,
        },
        {
            name = "teleport",
            firstFrameIndex = 8,
            framesCount = 1,
            tickStep = self.tickStepTable.teleport,
        },
        {
            name = "smokeBomb",
            firstFrameIndex = 1,
            framesCount = 1,
            tickStep = self.tickStepTable.smokeBomb,
        },
        {
            name = "flury",
            firstFrameIndex = 10,
            framesCount = 1,
            tickStep = self.tickStepTable.flury,
        },
        {
            name = "shuriken",
            firstFrameIndex = 10,
            framesCount = 1,
            tickStep = self.tickStepTable.shuriken,
        },
        {
            name = "stompShock",
            firstFrameIndex = 4,
            framesCount = 1,
            tickStep = self.tickStepTable.stompShock,
        },
    }, true, "follow")

    self.currentStage = 1

    self.realX = x
    self.distanceToPlayerX = self.realX - playerX
    self.distanceToPlayerY = self.y - realPlayerY
    self.followRangeValue = {0, 10}
    self.nextAttack = nil
    self.moveSpeed = 4

    self:setCollideRect(0, 0, 24, 32)
    self:moveTo(self.distanceToPlayerX + 200, y)
end

function Boss:update()
    self:updateLocation()

    if (self.distanceToPlayerX >= -240) and (self.distanceToPlayerX <= 240) then
        self:updateAnimation()
    end

    self:handleState()

    print4 = self.realX
    print6 = self.distanceToPlayerX
end

function Boss:handleState()
    if self.currentState == "rest" then -- all
        self:handleRestInput()
    elseif self.currentState == "dash" then 
        self:handleDashInput()
    elseif self.currentState == "follow" then -- all
        self:handleFollowInput()
    elseif self.currentState == "slash" then -- short rest
    elseif self.currentState == "jumpSlash" then -- mid rest
    elseif self.currentState == "spinSlash" then -- long rest
    elseif self.currentState == "smokeBomb" then -- teleport or slash
    elseif self.currentState == "flury" then -- long rest
    elseif self.currentState == "shuriken" then -- short rest
    elseif self.currentState == "stompShock" then -- long rest
    end
end

-- input helper functions

function Boss:updateLocation()
    self.distanceToPlayerX = self.realX - playerX
    if (self.distanceToPlayerX >= -240) and (self.distanceToPlayerX <= 240) then
        self:moveTo(self.distanceToPlayerX + 200, self.y)
    end
end

function Boss:handleRestInput()
end

function Boss:handleFollowInput()
    --Player loc = 200
    --total range = 200 <-[200]-> 400 (0 <-> 200)
    --cushion value = 65 (close), 40 (far)
    --new range = 265 <-[95]-> 360 (65 <-> 160)
    --closeness priority (close to far)
        --slash or flury, jumpSlash or stompShock, spinSlash, shuriken

        --smokeBomb can be all, but more leaning far(?)
        --teleport is part of smokeBomb, not a seperate attack. (at most, a transition animation)


    --[[ set range, then pick a random number in that range (every frame?, test this) 
        test if the you're trying to get to the location on the left or right side
        then try to get to that location]]

    local value = 95 + 65

    --value = math.random(65 + self.followRangeValue[1], 65 + self.followRangeValue[2])

    if math.abs(self.distanceToPlayerX) >= 0 and math.abs(self.distanceToPlayerX) < 65 then
        local table = {"left", "right"}
        self:changeToDashState(table[math.random(1,2)])
    else
        if math.abs(value - self.distanceToPlayerX) <= math.abs(-value - self.distanceToPlayerX) then
            if self.distanceToPlayerX < value then
                self.realX += self.moveSpeed * .9
            elseif self.distanceToPlayerX > value then
                self.realX -= self.moveSpeed
            end
        else
            if self.distanceToPlayerX < -value then
                self.realX += self.moveSpeed
            elseif self.distanceToPlayerX > -value then
                self.realX -= self.moveSpeed * .9
            end
        end
    end
end

function Boss:handleDashInput()
    
end

-- state transition functions

function Boss:changeToRandomState(stateOptionTable)
    local rng = math.random(1, #stateOptionTable)
    self:changeState(stateOptionTable[rng])
end

function Boss:changeToRestState(time)
    self:changeState("rest")

    pd.timer.performAfterDelay(time, function ()
        self:changeState("follow")    
    end)
end

function Boss:changeToFollowState()
    local attackTable = nil

    if self.currentStage == 1 then
        attackTable = {
            "slash",--
            "flury",--
            "jumpSlash"--
        }
    elseif self.currentStage == 2 then
        attackTable = {
            "slash",
            "jumpSlash",
            "spinSlash",--
            "flury",
            "stompShock"--
        }
    elseif self.currentStage == 3 then
        attackTable = {
            "slash",
            "jumpSlash",
            "spinSlash",
            "smokeBomb",--
            "flury",
            "shuriken",--
            "stompShock"
        }
    end

    local rng = math.random(1, #attackTable)

    if attackTable[rng] == "slash" or attackTable[rng] == "flury" then
        self.followRangeValue = {0, 10}
    elseif attackTable[rng] == "jumpSlash" or attackTable[rng] == "stompShock" then
        self.followRangeValue = {10, 20}
    elseif attackTable[rng] == "spinSlash" then
        self.followRangeValue = {0, 35}
    elseif attackTable[rng] == "smokeBomb" then
        self.followRangeValue = {35, 95}
    elseif attackTable[rng] == "shuriken" then
        self.followRangeValue = {85, 95}
    end

    self:changeState("follow")
end

function Boss:changeToDashState(direction)
    if direction == "left" then
        self.globalFlip = 1
    elseif direction == "right" then
        self.globalFlip = 0
    end
    self:changeState("dash")
end
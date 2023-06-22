local pd <const> = playdate
local gfx <const> = pd.graphics

class('Boss').extends('AnimatedSprite')

function Boss:init(x, y)
    local bossTable = gfx.imagetable.new("entity/boss/bossImages/boss-table-64-64")
    Boss.super.init(self, bossTable)
    self:setZIndex(ZIndexTable.Boss)
    
    self.tickStepTable = {
        idle = 10,
        dash = 1,
        follow = 4,
        slash = 4,
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
            name = "idle",
            firstFrameIndex = 1,
            framesCount = 3,
            tickStep = self.tickStepTable.idle,
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
            firstFrameIndex = 11,
            framesCount = 8,
            tickStep = self.tickStepTable.slash,
            nextAnimation = "idle"
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
    }, true, "idle")

    self.currentStage = 0

    self.realX = x
    self.distanceToPlayerX = self.realX - playerX
    self.distanceToPlayerY = self.y - realPlayerY
    self.followRangeValue = {0, 10}
    self.nextAttack = nil
    self.moveSpeed = 4
    self.attackMoveSpeed = nil
    self.attackLocation = nil
    self.attackSpeedTable = {}

    self:setCollideRect(20, 20, 20, 32)
    self:moveTo(self.distanceToPlayerX + 200, y)
    self:changeToFollowState()
    self:establishAnimationEndEvents()
end

function Boss:establishAnimationEndEvents()
    self.states["slash"].onAnimationEndEvent = function ()
        self:changeToIdleState(1500)
        self:resetCollideRect()
    end
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
    if self.currentState == "idle" then -- all
        self:handleIdleInput()
    elseif self.currentState == "dash" then 
        self:handleDashInput()
    elseif self.currentState == "follow" then -- all
        self:handleFollowInput()
    elseif self.currentState == "slash" then -- short rest
        self:handleSlashInput()
    elseif self.currentState == "jumpSlash" then -- mid rest
    elseif self.currentState == "spinSlash" then -- long rest
    elseif self.currentState == "smokeBomb" then -- teleport or slash
    elseif self.currentState == "flury" then -- long rest
    elseif self.currentState == "shuriken" then -- short rest
    elseif self.currentState == "stompShock" then -- long rest
    end
end

-- misc helper functions

function Boss:updateLocation()
    self.distanceToPlayerX = self.realX - playerX
    if (self.distanceToPlayerX >= -240) and (self.distanceToPlayerX <= 240) then
        self:moveTo(self.distanceToPlayerX + 200, self.y)
    end
end

    -- updates boss orientation to left or right depending on distance to the player
function Boss:updateOrientation()
    if self.distanceToPlayerX >= 0 then -- if the boss is on top of the player then the boss will go left, not a random direction.
        self.globalFlip = 1 -- left
    elseif self.distanceToPlayerX < 0 then
        self.globalFlip = 0 -- right
    end
end

function Boss:resetCollideRect()
    self:setCollideRect(20, 20, 20, 32)
end

-- input helper functions

function Boss:handleIdleInput()
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

    self.attackLocation = math.random(65 + self.followRangeValue[1], 65 + self.followRangeValue[2])
    print8 = self.attackLocation

    if math.abs(self.distanceToPlayerX) >= 0 and math.abs(self.distanceToPlayerX) < 65 then
        local function randomDirection()
            local direction = {"left", "right"}
            self:changeToDashState(direction[math.random(1, 2)])
        end

        if playerState == "dash" then
            if self.distanceToPlayerX < 0 then
                self:changeToDashState("right", 250)
            elseif self.distanceToPlayerX > 0 then
                self:changeToDashState("left", 250)
            else
                randomDirection()
            end
        else
            if self.distanceToPlayerX < 0 then
                self:changeToDashState("left")
            elseif self.distanceToPlayerX > 0 then
                self:changeToDashState("right")
            else
                randomDirection()
            end
        end
    elseif math.abs(self.distanceToPlayerX) >= self.attackLocation - self.moveSpeed and math.abs(self.distanceToPlayerX) <= self.attackLocation + self.moveSpeed then
        self:changeToNextAttack(self.nextAttack)
    else
        if math.abs(self.attackLocation - self.distanceToPlayerX) <= math.abs(-self.attackLocation - self.distanceToPlayerX) then
            if self.distanceToPlayerX < self.attackLocation then
                self.realX += self.moveSpeed * .9
                self.globalFlip = 0
            elseif self.distanceToPlayerX > self.attackLocation then
                self.realX -= self.moveSpeed
                self.globalFlip = 1
            end
        else
            if self.distanceToPlayerX < -self.attackLocation then
                self.realX += self.moveSpeed
                self.globalFlip = 0
            elseif self.distanceToPlayerX > -self.attackLocation then
                self.realX -= self.moveSpeed * .9
                self.globalFlip = 1
            end
        end
    end
end

function Boss:handleDashInput()
    if math.abs(self.distanceToPlayerX) >= self.attackLocation - self.moveSpeed and math.abs(self.distanceToPlayerX) <= self.attackLocation + self.moveSpeed then
        self:changeToNextAttack(self.nextAttack)
    elseif self.globalFlip == 1 then -- left
        self.realX -= self.moveSpeed * 3
    elseif self.globalFlip == 0 then -- right
        self.realX += self.moveSpeed * 3
    end
end

function Boss:handleSlashInput()
    self:setCollideRect(20, 25, 48, 10) -- need to set for left and right as well as a per frame basis.
    
    if self.globalFlip == 1 then -- left
        self.realX -= self.attackSpeedTable[self._currentFrame - 10]
    elseif self.globalFlip == 0 then -- right
        self.realX += self.attackSpeedTable[self._currentFrame - 10]
    end

    self.states.slash.onFrameChangedEvent = function (self) print(self._currentFrame - 10) end
end

-- state transition functions

function Boss:changeToRandomState(stateOptionTable)
    local rng = math.random(1, #stateOptionTable)
    self:changeState(stateOptionTable[rng])
end

function Boss:changeToIdleState(time)
    self:changeState("idle")

    pd.timer.performAfterDelay(time, function ()
        self:changeToFollowState()
    end)
end

function Boss:changeToFollowState()
    local attackTable = nil
    if self.currentStage == 0 then -- for testing purposes 
        attackTable = {
            "slash"
        }
    elseif self.currentStage == 1 then
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

    self.nextAttack = attackTable[rng]
    self:changeState("follow")
end

function Boss:changeToDashState(direction, duration)
    if duration == nil then duration = 200 end

    if direction == "left" then
        self.globalFlip = 1
    elseif direction == "right" then
        self.globalFlip = 0
    end
    pd.timer.performAfterDelay(duration, function ()
        self:changeToFollowState()
    end)
    self:changeState("dash")
end

function Boss:changeToShurikenState()
    if self.distanceToPlayerX < 0 then
        --Shuriken(self.x, "right")
        print("threw a shuriken to the right")
    elseif self.distanceToPlayerX > 0 then
        --Shuriken(self.x, "left")
        print("threw a shuriken to the left")
    end

    -- this timer should be set to the amount of frames the shuriken throwing animation frames there are times 1000/40 (1s/fps) then multiplied by the GSM
    pd.timer.performAfterDelay(500, function ()
        -- longer idle time bcs boss is farther away from player
        self:changeToIdleState(3000)
    end)
end

function Boss:changeToSlashState()
    self:updateOrientation()
    self.attackSpeedTable = {
        0, 0, 3, 5, 6, 5, 2, 2
    }

    self:changeState("slash")
end

function Boss:changeToNextAttack(attack)
    if attack == "slash" then
        self:changeToSlashState()
    elseif attack == "jumpSlash" then
        self:changeToIdleState(1000)
    elseif attack == "flury" then
        self:changeToIdleState(1000)
    elseif attack == "spinSlash" then
        self:changeToIdleState(1000)
    elseif attack == "stompShock" then
        self:changeToIdleState(1000)
    elseif attack == "smokeBomb" then
        self:changeToIdleState(1000)
    elseif attack == "shuriken" then
        self:changeToShurikenState()
        self:changeToIdleState(1000)
    end

    --print(attack)
end
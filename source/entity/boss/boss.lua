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
        stompShock = 4
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
            firstFrameIndex = 21,
            framesCount = 10,
            tickStep = self.tickStepTable.stompShock,
            nextAnimation = "idle"
        },
    }, true, "idle")

    self.currentStage = 0
    self.HP = 30
    self.isInvincible = false

    self.realX = x
    self.distanceToPlayerX = self.realX - playerX
    self.distanceToPlayerY = self.y - realPlayerY
    self.followRangeValue = {0, 10}
    self.nextAttack = nil
    self.moveSpeed = 4
    self.dashTimer = nil
    self.attackMoveSpeed = nil
    self.attackLocation = nil
    self.attackSpeedTable = {}
    self.attackRectTable = {}

    self:resetCollideRect() -- this makes it so that idle animation hitbox is in the same location in the code.
    self:moveTo(self.distanceToPlayerX + 200, y)
    self:changeToFollowState()
    self:establishAnimationEndEvents()
end

function Boss:establishAnimationEndEvents()
    self.states["slash"].onAnimationEndEvent = function ()
        self:changeToIdleState(250)
        self:resetCollideRect()
    end

    self.states["stompShock"].onAnimationEndEvent = function ()
        self:changeToIdleState(625)
        self:resetCollideRect()
    end
end

function Boss:update()
    self:handleCollisions()

    self:updateLocation()

    self:updateAnimation()

    self.doBoss = true

    if self.doBoss then
        self:handleState()
    else
        self:changeState("idle")
    end

    bossState = self.currentState
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
        self:handleStompShockInput()
    end
end

-- misc helper functions

function Boss:updateLocation()
    self.distanceToPlayerX = self.realX - playerX
    if (self.distanceToPlayerX >= -240) and (self.distanceToPlayerX <= 240) then
        self:moveTo(self.distanceToPlayerX + 200, self.y)
    end
end

function Boss:setInvincibleTrue(duration)
    -- to avoid the bug where GSM can make this timer really long
    local fakeGSM = 1
    if GSM < .5 then
        fakeGSM = 1.5
    end

    self.isInvincible = true
    pd.timer.performAfterDelay((duration * fakeGSM), function ()
        self.isInvincible = false
    end)
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
    self:setCollideRect(24, 21, 17, 26)
end

function Boss:updateAttackCollideRect(firstFrameIndex, direction)
    -- https://www.desmos.com/calculator/pv9vj8xurp -- graph showing how this all works (kinda?)
    if direction == "left" then
        -- for x you take the inverse of x, -x; add the length of the sprite table, 64; and then subtract the width of the collision rect.
        self:setCollideRect(((-self.attackRectTable[self._currentFrame - firstFrameIndex][1] + 64) - self.attackRectTable[self._currentFrame - firstFrameIndex][3]), self.attackRectTable[self._currentFrame - firstFrameIndex][2], self.attackRectTable[self._currentFrame - firstFrameIndex][3], self.attackRectTable[self._currentFrame - firstFrameIndex][4])
    elseif direction == "right" then
        self:setCollideRect(self.attackRectTable[self._currentFrame - firstFrameIndex][1], self.attackRectTable[self._currentFrame - firstFrameIndex][2], self.attackRectTable[self._currentFrame - firstFrameIndex][3], self.attackRectTable[self._currentFrame - firstFrameIndex][4])
    end
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

    if math.abs(self.distanceToPlayerX) >= 0 and math.abs(self.distanceToPlayerX) < 65 then
        local function randomDirection()
            local direction = {"left", "right"}
            self:changeToDashState(direction[math.random(1, 2)])
        end

        if playerState == "dash" or playerState == "dashJump" then
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
    elseif math.abs(self.distanceToPlayerX) >= self.attackLocation - self.moveSpeed/2 and math.abs(self.distanceToPlayerX) <= self.attackLocation + self.moveSpeed/2 then
        self:changeToNextAttack(self.nextAttack)
    else
        if math.abs(self.attackLocation - self.distanceToPlayerX) <= math.abs(-self.attackLocation - self.distanceToPlayerX) then
            if self.distanceToPlayerX < self.attackLocation then
                self.realX += (self.moveSpeed * .9) * GSM
                self.globalFlip = 0
            elseif self.distanceToPlayerX > self.attackLocation then
                self.realX -= self.moveSpeed * GSM
                self.globalFlip = 1
            end
        else
            if self.distanceToPlayerX < -self.attackLocation then
                self.realX += self.moveSpeed * GSM
                self.globalFlip = 0
            elseif self.distanceToPlayerX > -self.attackLocation then
                self.realX -= (self.moveSpeed * .9) * GSM
                self.globalFlip = 1
            end
        end
    end
end

function Boss:handleDashInput()
    if math.abs(self.distanceToPlayerX) >= self.attackLocation - ((self.moveSpeed * 3) * GSM) and math.abs(self.distanceToPlayerX) <= self.attackLocation + ((self.moveSpeed * 3) * GSM) then
        self:changeToNextAttack(self.nextAttack)
        self.dashTimer:remove() -- timer doesn't remove otherwise and you can "dash lock" the boss if you walk towards the boss while it's in an attack state
    elseif self.globalFlip == 1 then -- left
        self.realX -= (self.moveSpeed * 3) * GSM
    elseif self.globalFlip == 0 then -- right
        self.realX += (self.moveSpeed * 3) * GSM
    end
end

function Boss:handleSlashInput()
    -- turns the current selected frame into a number starting at 1, then uses that to move the correct amount of speed depending on the current animation frame.
    if self.globalFlip == 1 then -- left
        self.realX -= (self.attackSpeedTable[self._currentFrame - 10]) * GSM
        self:updateAttackCollideRect(10, "left")
    elseif self.globalFlip == 0 then -- right
        self.realX += (self.attackSpeedTable[self._currentFrame - 10]) * GSM
        self:updateAttackCollideRect(10, "right")
    end
end

function Boss:handleStompShockInput()
    if self.globalFlip == 1 then -- left
        self.realX -= (self.attackSpeedTable[self._currentFrame - 20]) * GSM
        self:updateAttackCollideRect(20, "left")
    elseif self.globalFlip == 0 then -- right
        self.realX += (self.attackSpeedTable[self._currentFrame - 20]) * GSM
        self:updateAttackCollideRect(20, "right")
    end
end

-- state transition functions

function Boss:changeToRandomState(stateOptionTable)
    local rng = math.random(1, #stateOptionTable)
    self:changeState(stateOptionTable[rng])
end

function Boss:changeToIdleState(time)
    self:changeState("idle")

    -- to avoid the bug where GSM can make this timer really long
    local fakeGSM = 1
    if GSM < .5 then
        fakeGSM = 1.5
    end

    pd.timer.performAfterDelay((time * fakeGSM), function ()
        self:changeToFollowState()
    end)
end

function Boss:changeToFollowState()
    local attackTable = nil
    if self.currentStage == 0 then -- for testing purposes 
        attackTable = {
            "stompShock",
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

    if attackTable[rng] == "slash" then
        self.followRangeValue = {5, 20}
    elseif attackTable[rng] == "flury" then
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
    self.attackLocation = math.random(65 + self.followRangeValue[1], 65 + self.followRangeValue[2])
    self:changeState("follow")
end

function Boss:changeToDashState(direction, duration)
    if duration == nil then duration = 200 end

    if direction == "left" then
        self.globalFlip = 1
    elseif direction == "right" then
        self.globalFlip = 0
    end

    -- to avoid the bug where GSM can make this timer really long
    local fakeGSM = 1
    if GSM < .5 then
        fakeGSM = 1.5
    end

    self.dashTimer = pd.timer.performAfterDelay((duration * fakeGSM), function ()
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
end

function Boss:changeToSlashState()
    self:updateOrientation()
    self.attackSpeedTable = {
        0, 0, 6, 10, 12, 5, 2, 2
    }
    self.attackRectTable = {
        {24, 21, 20, 26},
        {22, 22, 22, 25},
        {19, 23, 26, 24},
        {19, 27, 44, 10},
        {19, 27, 44, 10},
        {19, 27, 44, 10},
        {27, 25, 31, 11},
        {26, 22, 17, 25},
    }

    self:changeState("slash")
end

function Boss:changeToStompShock()
    self:updateOrientation()
    self.attackSpeedTable = {
        2.5, 3, 3, 4, 2, 3, 5, 5, 2, 1
    }
    self.attackRectTable = {
        {26, 24, 18, 23},
        {26, 23, 19, 24},
        {26, 22, 19, 25},
        {25, 20, 17, 27},
        {24, 22, 20, 25},
        {22, 29, 26, 18},
        {22, 26, 38, 21},
        {24, 27, 35, 20},
        {21, 25, 18, 22},
        {25, 24, 18, 23},
    }

    self:changeState("stompShock")
end

function Boss:changeToNextAttack(attack)
    if attack == "slash" then -- DONE
        self:changeToSlashState()
    elseif attack == "jumpSlash" then
        self:changeToIdleState(1000)
    elseif attack == "flury" then
        self:changeToIdleState(1000)
    elseif attack == "spinSlash" then
        self:changeToIdleState(1000)
    elseif attack == "stompShock" then
        self:changeToStompShock()
    elseif attack == "smokeBomb" then
        self:changeToIdleState(1000)
    elseif attack == "shuriken" then
        self:changeToShurikenState()
        self:changeToIdleState(1000)
    end

    --print(attack)
end

-- Physics Helper Functions

function Boss:applyGravity(multiplier)
    if multiplier == nil then multiplier = 1 end

    if self.y < ground then
        if self.y + ((self.yAcceleration * GSM) * multiplier) > ground then
            --prevents player from falling below ground
            self:moveBy(0, ground - self.y)
            --resets player gravity because player is now on ground
            self.yAcceleration = 1
            self.isJumping = false
            self.usedSpike = false
            self:changeToIdleState()
        elseif GSM == 0 then
            -- this little bit prevents the player from being stuck flying if they somehow get their y acceleration to be 0
            self.yAcceleration = self.storedYAcceleration
        else
            -- active gravity function
            self:moveBy(0, ((self.yAcceleration * GSM) * multiplier))
            if self.yAcceleration * (1 + ((.12 * GSM) * multiplier)) < ((self.maxFallSpeed * GSM) * multiplier) then
                -- how fast gravity increases. Higher number = more gravity
                self.yAcceleration *= 1 + ((.12 * GSM) * multiplier)
            else
                self.yAcceleration = ((self.maxFallSpeed * GSM) * multiplier) -- max player fall speed
            end
        end
    end
end

-- Collision Functions

function Boss:handleCollisions()
    local actualX, actualY, collisions, length = self:checkCollisions(self.x, self.y)
    if length > 0 then
        for index, collision in pairs(collisions) do
            local collidedObject = collision['other']
            if self.isInvincible == false then
                if collidedObject:isa(Slash) then
                    self.HP -= 1
                    self:setInvincibleTrue(350)
                    print("boss HP : " .. self.HP)
                    setShakeAmount(5)
                end
            end
        end
    end
end
import "entity/entity"

local pd <const> = playdate
local gfx <const> = pd.graphics

class('Player').extends("Entity")

function Player:init(x, y)
    local playerTable = gfx.imagetable.new("entity/player/playerImages/player-table-64-64")
    self.tickStepTable = {
        idle = {25, 15, 20},
        run = 4,
        jump = 1, -- anything that is at a value of 1 doesn't have an animation, most likely
        slash = {2, 2, 3, 1}, -- really wanna make it so that I can pass a table into here and still get it to run. gotta edit animatedSprite for that to work tho.
        airSlash = 1,
        dash = 1,
        dashJump = 1,
        aimSpike = 1,
        spike = 1
    }
    self.animationStates = {
        {
            name = "idle",
            firstFrameIndex = 1,
            framesCount = 3,
            tickStep = self.tickStepTable.idle,
            yoyo = true
        },
        {
            name = "run",
            firstFrameIndex = 4,
            framesCount = 5,
            tickStep = self.tickStepTable.run
        },
        {
            name = "jump",
            firstFrameIndex = 9,
            framesCount = 1,
            tickStep = self.tickStepTable.jump
        },
        {
            name = "slash",
            firstFrameIndex = 11,
            framesCount = 4,
            tickStep = self.tickStepTable.slash,
            nextAnimation = "idle"
        },
        {
            name = "aimSpike", -- this is where the player is mid air, time slows and the crank is used
            firstFrameIndex = 10, -- this needs to be like an inbetween for the jump and fall animations. 
            framesCount = 1,
            tickStep = self.tickStepTable.aimSpike
        },
        {
            name = "spike",
            firstFrameIndex = 1,
            framesCount = 1,
            tickStep = self.tickStepTable.spike
        }
    }
    Player.super.init(self, playerTable, self.tickStepTable, self.animationStates)
    self:moveTo(x,y)
    self:setZIndex(ZIndexTable.Player)
    self:setStates(self.animationStates, true, "idle")

    -- Player Base Stats
    self.HP = 10
    self.xVelo = 0
    self.yVelo = 0
    self.maxFallSpeed = 75
    self.runSpeed = 4
    self.jumpSpeed = 8
    self.isInvincible = false
    self.dashDirection = nil
    self.canDash = true
    self.holdJump = false
    self.usedSpike = false
    self.groundSlashDuration = 200
    self.airSlashDuration = 300
    spikeAngle = 0
    self.spikeDistance = 75
    self.bouncedSpike = false
    self.minSpikeXDistance = self.xVelo
    self.minSpikeYDistance = self.xVelo
    self.spikeX = 0
    self.spikeY = 0
    realPlayerY = self.y
    realPlayerX = self.x

    --the table that was here and optimized stuff was called a "dispach table"

    self:setCollideRect(13+8, 12+8, 22, 28)
    self:setGSM()
end

function Player:update()
    local pastX = playerX -- set previous x before any changes

        self:updateGSM()

        self:updateAnimation()

        if GSM ~= 0 then
            self:handleState()
        end

        self:updateExternalVariables()

        self:handleCollisions()

    distTraveled = pastX - playerX
    totalDistanceTraveled += math.abs(distTraveled) -- this could be bad for performance but idk
end

-- misc functions

function Player:updateExternalVariables()
    realPlayerY = self.y
    realPlayerX = self.x
    playerState = self.currentState

    print1 = currentFrame
end

function Player:setInvincibleTrue(duration)
    self.isInvincible = true
    pd.timer.performAfterDelay(duration, function ()
        self.isInvincible = false
    end)
end

function Player:resetRotation()
    if self:getRotation() ~= 0 then
        self:setRotation(0)
    end
end

function Player:yVeloRotation()
    self:setRotation(math.sin(self.yVelo/self.xVelo))
end

-- main player controler
function Player:handleState()
    playerX += (self.xVelo * GSM)
    if self.y + (self.yVelo * GSM) > ground then
        self:moveTo(self.x, ground)
    else
        self:moveBy(0, self.yVelo * GSM)
    end
    

    if self.currentState == "idle" then
        self:applyGravity()
        self:handleGroundInput()
    elseif self.currentState == "run" then
        self:applyGravity()
        self:handleGroundInput()
    elseif self.currentState == "jump" then
        self:applyGravity()
        self:handleAirInput()
    elseif self.currentState == "fall" then -- might delete later
        self:applyGravity()
        self:handleAirInput() -- same as jump
    elseif self.currentState == "slash" then
        self:applyGravity()
        self:handleSlashInput()
    
    elseif self.currentState == "aimSpike" then
        self:applyGravity()
        self:handleAimSpikeInput()
    elseif self.currentState == "spike" then
        -- the action of a spike where you shoot twards where you were aiming.
        self:handleSpikeInput()
        self:applyGravity(.5)
    -- elseif self.currentState == "dash" then
    --     self:applyGravity()
    --     self:handleDashInput()
    -- elseif self.currentState == "dashJump" then
    --     if self.isJumping then
    --         self:moveBy(0, -(self.jumpSpeed * GSM))
    --     end
    --     self:applyGravity()
    --     self:handleDashJumpInput()
    end
end

--      Input Helper Functions

function Player:handleGroundInput()
    self:resetRotation()

    if pd.buttonJustPressed(pd.kButtonA) then
        self:changeToJumpState()
    -- elseif pd.buttonJustPressed(pd.kButtonB) and self.canDash then
    --     self:changeToDashState()
    elseif pd.buttonJustPressed(pd.kButtonB) then
       self:changeToSlashState() 
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        self:doMoveX("left", self.runSpeed)
        self.globalFlip = 1

        -- animatedSprite automatically goes through the if statment of if your already in this state to not worry about doing the rest of the code.
        self:changeToRunState()
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self:doMoveX("right", self.runSpeed)
        self.globalFlip = 0
        self:changeToRunState()
    else
        self:changeToIdleState()
        self:doXDrag(1)
    end
end

function Player:handleAirInput()
    self:resetRotation()
    if pd.buttonJustPressed(pd.kButtonA) and self.y < ground - 20 then
        if self.usedSpike == false then
            self:changeToAimSpikeState()
        end
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        if self.xVelo > -self.runSpeed then
            self.xVelo -= 1
        end
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        if self.xVelo < self.runSpeed then
            self.xVelo += 1
        end
    end
end

function Player:handleSlashInput()
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self:doMoveX("left", self.runSpeed * 1.05)
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self:doMoveX("right", self.runSpeed * 1.05)
    end
end

function Player:handleDashInput()
    if self.dashDirection == "left" then
        self:doMoveX("left", self.runSpeed * 1.5)
    elseif self.dashDirection == "right" then
        self:doMoveX("right", self.runSpeed * 1.5)
    end

    -- makes dash longer if the direction is held.
    -- these timers continue after your state is changed.
    pd.timer.performAfterDelay(500 * (1/GSM), function ()
        if pd.buttonIsPressed(pd.kButtonB) then
            pd.timer.performAfterDelay(500 * (1/GSM), function ()
                if self.currentState == "dash" then
                    self:changeToIdleState()
                elseif self.currentState == "dashJump" then
                    self:changeToJumpState()
                end
                pd.timer.performAfterDelay(500, function ()
                    self.canDash = true
                end)
            end)
        else
            if self.currentState == "dash" then
                self:changeToIdleState()
            elseif self.currentState == "dashJump" then
                self:changeToJumpState()
            end
            pd.timer.performAfterDelay(500, function ()
                self.canDash = true
            end)
        end
    end)

    -- you can jump while mid dash.
    if pd.buttonJustPressed(pd.kButtonA) then
        self:changeToDashJumpState()
    end
end

function Player:handleAimSpikeInput()
    if pd.buttonJustPressed(pd.kButtonA) then
        self:setGSM()
        self:changeToSpikeState()
    elseif self.y > ground - 20 then
        self:setGSM()
        self:changeToJumpState()
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        self:doMoveX("left", self.runSpeed)
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self:doMoveX("right", self.runSpeed)
    end
end

function Player:handleSpikeInput()
    print(self.y, self.xVelo, self.yVelo, (math.atan(self.xVelo/self.yVelo)) * (180/math.pi) + 90)
    self:doXDrag(0.2)
    local angle = (-math.atan(self.xVelo/self.yVelo)) * (180/math.pi)
    if angle >= 270 or (angle >= 0 and angle <= 90) then
        self:setRotation(angle)
    else
        self:setRotation(angle + 180)
    end

    -- bounces the playerY
    if self.bouncedSpike == false then
        if self.y >= ground then
            self.yVelo /= -2
            if self.xVelo > 0 then
                self.xVelo += 3
            elseif self.xVelo < 0 then
                self.xVelo -= 0
            end
            self.bouncedSpike = true
        end
    else
        self.bouncedSpike = false
        if self.y < ground then
            self:changeToJumpState()
        else
            self:changeToIdleState()
        end
    end

    if math.abs(self.xVelo) < 0.5 and math.abs(self.yVelo) < 0.5 then
        self.bouncedSpike = false
        if self.y < ground then
            self:changeToJumpState()
        else
            self:changeToIdleState()
        end
    end
end


--State Transitions
function Player:changeToIdleState()
    self:changeState("idle")
end

function Player:changeToJumpState()
    if self.yVelo == 0 and self.y == ground then
        pd.timer.performAfterDelay(200, function ()
            if pd.buttonIsPressed(pd.kButtonA) and self.currentState == "jump" then
                self.yVelo -= 2
            elseif (not pd.buttonIsPressed(pd.kButtonA)) and self.currentState == "jump" then
                self.yVelo += .5
            end
        end)
        self.yVelo -= self.jumpSpeed
    end

    self:changeState("jump")
end

function Player:changeToFallState()
    self:changeState("fall")
end

function Player:changeToRunState()
    self:changeState("run")
end

function Player:changeToDashState()
    if pd.buttonIsPressed(pd.kButtonRight) then
        self.dashDirection = "right"
        self.globalFlip = 0
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        self.dashDirection = "left"
        self.globalFlip = 1
    end
    self.canDash = false

    self:changeState("dash")
end

function Player:changeToDashJumpState()
    if self.yVelo == 0 and self.y == ground then
        pd.timer.performAfterDelay(200, function ()
            if pd.buttonIsPressed(pd.kButtonA) and self.currentState == "jump" then
                self.yVelo -= 2
            elseif (not pd.buttonIsPressed(pd.kButtonA)) and self.currentState == "jump" then
                self.yVelo += .5
            end
        end)
        self.yVelo -= self.jumpSpeed
    end
    self:changeState("dashJump")
end

function Player:changeToAimSpikeState()
    Spike(self)
    self:setGSM(.1)
    self:changeState("aimSpike")
end

function Player:changeToSpikeState()
    self.usedSpike = true

    self.xVelo = 0
    self.yVelo = 0

    if (spikeAngle >= 0 and spikeAngle < 90) then
        self.yVelo += 7.5 * math.sin(spikeAngle/(180/math.pi))
        self.xVelo += 12 * math.cos(spikeAngle/(180/math.pi))
    elseif (spikeAngle >= 270 and spikeAngle < 360) then
        self.yVelo += 7.5 * math.sin(spikeAngle/(180/math.pi))
        self.xVelo += 12 * math.cos(spikeAngle/(180/math.pi))
    else
        self.yVelo += 4 * math.sin(spikeAngle/(180/math.pi))
        self.xVelo += 13 * math.cos(spikeAngle/(180/math.pi))
    end

    if self.xVelo > 0 then
        self.globalFlip = 0
    elseif self.xVelo < 0 then
        self.globalFlip = 1
    end

    self:changeState("spike")
end

function Player:changeToSlashState()
    if self.globalFlip == 1 then -- left
        Slash(self.x, "left", self.groundSlashDuration * (1/GSM))
    elseif self.globalFlip == 0 then -- right
        Slash(self.x, "right", self.groundSlashDuration * (1/GSM))
    end
    self:changeState("slash")
    self.currentStateNumber = 5

    
end

-- Physics Helper Functions

-- Gravity function, don't set multiplier to 0.
function Player:applyGravity(multiplier)
    if multiplier == nil then multiplier = 1 end

    --print(math.ceil(self.y), self.x, self.yVelo, self.currentState)

    local function touchGrass()
        --prevents player from falling below ground
        self:moveTo(self.x, ground)
        --resets player gravity because player is now on ground
        if self.currentState ~= "spike" then
            self.yVelo = 0
            self.usedSpike = false
            self:setRotation(0)
        end
        if self.currentState == "jump" then
            self:changeToIdleState()
        end
    end

    if self.y < ground then
        if self.y + (self.yVelo * multiplier) * GSM >= ground then -- if you're going to move past the ground.
            touchGrass()
        else -- if you're just trying to apply gravity.
            if self.yVelo < self.maxFallSpeed then
                self.yVelo += (0.75 * multiplier) * GSM
            end
        end
    else
        touchGrass()
    end
end

function Player:doXDrag(drag)
    if math.abs(self.xVelo) <= 1 * GSM then    
        self.xVelo = 0
    elseif self.xVelo > 0 then
        self.xVelo -= drag * GSM
    elseif self.xVelo < 0 then
        self.xVelo += drag * GSM
    end
end

function Player:doMoveX(direction, speed)
    if direction == "left" then
        if self.xVelo > -speed then
            self.xVelo -= 1 * GSM
        else
            self:doXDrag(1)
        end
    elseif direction == "right" then
        if self.xVelo < speed then
            self.xVelo += 1 * GSM
        else
            self:doXDrag(1)
        end
    end
end

-- Collision Functions

function Player:handleCollisions()
    local actualX, actualY, collisions, length = self:checkCollisions(self.x, self.y)
    if length > 0 then
        for index, collision in pairs(collisions) do
            local collidedObject = collision['other']
            if collidedObject:isa(Boss) then
                if self.isInvincible == false then
                    if not (self.currentState == "dash" or self.currentState == "dashJump" or self.currentState == "dashFall") then
                        local damage = nil
                        local invincibleTime = 800
                        if bossState == "slash" then
                            damage = 1
                            invincibleTime = 750
                        elseif bossState == "stompShock" then
                            damage = .25
                            invincibleTime = 200
                        else
                            damage = .5
                        end

                        if self.currentState == "aimSpike" then
                            self.HP -= damage * 1.5
                            self:setInvincibleTrue(800 * 1/GSM)
                            setShakeAmount(7)
                        else
                            self.HP -= damage
                            self:setInvincibleTrue(invincibleTime * 1/GSM)
                            setShakeAmount(5)
                        end

                        --print("player HP : " .. self.HP)
                    end
                end
            end
        end
    end
end
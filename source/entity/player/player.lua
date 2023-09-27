import "entity/entity"

local pd <const> = playdate
local gfx <const> = pd.graphics

class('Player').extends("Entity")

function Player:init(x, y)
    local playerTable = gfx.imagetable.new("entity/player/playerImages/player-table-48-48")
    self.tickStepTable = {
        idle = 10,
        run = 4,
        jump = 1, -- anything that is at a value of 1 doesn't have an animation, most likely
        slash = 1,
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
            firstFrameIndex = 10,
            framesCount = 1,
            tickStep = self.tickStepTable.jump
        },
        {
            name = "fall",
            firstFrameIndex = 11,
            framesCount = 1,
            tickStep = self.tickStepTable.jump
        },
        {
            name = "slash",
            firstFrameIndex = 1,
            framesCount = 1,
            tickStep = self.tickStepTable.slash
        },
        {
            name = "airSlash",
            firstFrameIndex = 1,
            framesCount = 1,
            tickStep = self.tickStepTable.airSlash
        },
        {
            name = "dash",
            firstFrameIndex = 9,
            framesCount = 1,
            tickStep = self.tickStepTable.dash
        },
        {
            name = "dashJump",
            firstFrameIndex = 12,
            framesCount = 1,
            tickStep = self.tickStepTable.dashJump
        },
        {
            name = "aimSpike", -- this is where the player is mid air, time slows and the crank is used
            firstFrameIndex = 14, -- this needs to be like an inbetween for the jump and fall animations. 
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
    self.minSpikeXDistance = self.xVelo
    self.minSpikeYDistance = self.xVelo
    self.spikeX = 0
    self.spikeY = 0
    self.currentStateNumber = 1
    realPlayerY = self.y
    realPlayerX = self.x

    local num = 0
    for i = self.jumpSpeed, 0, -1 do
        num += self.jumpSpeed - i
    end
    print(num)

    -- used in the player state controller as the dispatch table
    self.stateFunctionTable = {
        self.idleState, -- 1
        self.runState, -- 2
        self.jumpState, -- 3
        self.fallState, -- 4
        self.slashState, -- 5
        self.airSlashState, -- 6
        self.dashState, -- 7
        self.dashJumpState, -- 8
        self.dashFallState, -- 9 (not set up)
        self.aimSpikeState, -- 10
        self.spikeState -- 11
    }

    self:setCollideRect(13, 12, 22, 28)
    --self:setGSM()
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
    totalDistanceTraveled += math.sqrt(distTraveled^2) -- this could be bad for performance but idk
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

-- main player controler
function Player:handleState()
    playerX += (self.xVelo * GSM)
    self:moveBy(0, self.yVelo * GSM)
    return(self.stateFunctionTable[self.currentStateNumber](self))
end

-- state controller functions
function Player:idleState()
    self:applyGravity()
    self:handleGroundInput()
end

function Player:runState()
    self:applyGravity()
    self:handleGroundInput()
end

function Player:jumpState()
    self:applyGravity()
    self:handleAirInput()
end

function Player:fallState()
    self:jumpState()
end

function Player:slashState()
    --when on ground player can slash either left or right
    self:handleSlashInput()
end

function Player:airSlashState()
    -- when in air, slashes downwards.
    -- you move faster downwards if you aren't applying jump speed anymore.
    if self.isJumping then
        self:moveBy(0, -(self.jumpSpeed * GSM))
    end
    self:applyGravity()
    self:handleAirSlashInput()
end

function Player:dashState()
    -- make it so that when you're drifting you can dash out of your drift and the slash goes away as well
    -- like a spike but on the ground. for the spike you initiate it by pressing A when you're in the air.
    -- if you press A while on the ground, instead of a spike you do a dash.
    self:applyGravity()
    self:handleDashInput()
end

function Player:dashJumpState()
    if self.isJumping then
        self:moveBy(0, -(self.jumpSpeed * GSM))
    end
    self:applyGravity()
    self:handleDashJumpInput()
end

function Player:dashFallState()
    self:dashJumpState()
end

function Player:aimSpikeState()
    --when on ground you dash, when in air you "aimSpike"
    if self.isJumping then
        self:moveBy(0, -(self.jumpSpeed * GSM))
    end
    self:applyGravity()
    self:handleAimSpikeInput()
end

function Player:spikeState()
    -- the action of a spike where you shoot twards where you were aiming.
    self:handleSpikeInput()
    self:applyGravity(.5)
end

--      Input Helper Functions

function Player:handleGroundInput()
    self:resetRotation()

    if pd.buttonJustPressed(pd.kButtonA) then
        self:changeToJumpState()
    elseif pd.buttonJustPressed(pd.kButtonB) and self.canDash then
        self:changeToDashState()
    --elseif pd.buttonJustPressed() then
    --    self:changeToSlashState() 
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        self:doMoveX("left", self.runSpeed)
        self.globalFlip = 1

        -- animatedSprite automatically goes through the if statment of if your already in this state to not worry about doing the rest of the code.
        self:changeToRunState()
        
        -- this code prevents you from constantly updating this variable.
        if self.currentStateNumber ~= 2 then self.currentStateNumber = 2 end
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self:doMoveX("right", self.runSpeed)
        self.globalFlip = 0
        self:changeToRunState()
        if self.currentStateNumber ~= 2 then self.currentStateNumber = 2 end
    else
        self:changeToIdleState()
        self:doXDrag()
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
    -- faster moving in the direction of the slash
    -- slower moving away from the direction of the slash

    if self.globalFlip == 1 then -- left
        if pd.buttonIsPressed(pd.kButtonLeft) then
            playerX -= (self.xVelo * 1.15) * GSM
        elseif pd.buttonIsPressed(pd.kButtonRight) then
            playerX += (self.xVelo * .75) * GSM
        end
    elseif self.globalFlip == 0 then -- right
        if pd.buttonIsPressed(pd.kButtonLeft) then
            playerX -= (self.xVelo * .75) * GSM
        elseif pd.buttonIsPressed(pd.kButtonRight) then
            playerX += (self.xVelo * 1.15) * GSM
        end
    end
end

function Player:handleAirSlashInput()
    if pd.buttonIsPressed(pd.kButtonLeft) then
        playerX -= self.xVelo * GSM
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        playerX += self.xVelo * GSM
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

function Player:handleDashJumpInput()
    -- dash jumps are slightly slower than normal dashes.
    if self.dashDirection == "left" then
        playerX -= (self.xVelo * GSM) * 1.35
    elseif self.dashDirection == "right" then
        playerX += (self.xVelo * GSM) * 1.35
    end

    -- you can slash out of a dash if you were mid air.
    if pd.buttonJustPressed(pd.kButtonB) then
        if self.y < ground - 20 then
            self:changeToAirSlashState()
        end
    elseif pd.buttonJustPressed(pd.kButtonA) and self.y < ground - 20 then
        if self.usedSpike == false then
            self:changeToAimSpikeState()
        end
    end
end

function Player:handleAimSpikeInput()
    if pd.buttonJustPressed(pd.kButtonA) then
        self:setGSM(_, self.tickStepTable)
        self:changeToSpikeState()
    elseif self.y > ground - 20 then
        self:setGSM(_, self.tickStepTable)
        self:changeToJumpState()
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        playerX -= (self.xVelo * GSM)
        self.globalFlip = 1
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        playerX += (self.xVelo * GSM)
        self.globalFlip = 0
    end
end

function Player:handleSpikeInput()
    -- movement
    playerX += (self.spikeX * self.spikeDistance) * GSM
    -- y movement if player would fall below ground.
    if self.y + self.spikeY >= ground then
        if self.y ~= ground then
            self:moveBy(0, (self.spikeY * self.spikeDistance) - ((self.y + (self.spikeY * self.spikeDistance * GSM)) - ground))
        end
    else
        self:moveBy(0, ((self.spikeY * (self.spikeDistance)) * GSM))
    end

    -- bounces the playerY
    if self.y == ground then
        self.spikeY *= -1
        self:setRotation(self:getRotation() - 90)
    end

    self.spikeX *= .98 * GSM
    self.spikeY *= .98 * GSM
    -- https://media.discordapp.net/attachments/982141699029602337/1106751731020333106/IMG_20230512_191601.jpg?width=351&height=780 <- explanation in the form of a line graph.
    -- absolute value is so that if the numbers are negative (or not) then they are always consistent regardless of their original value (pos/neg)
    if not ((self.spikeX > math.abs(self.minSpikeXDistance) or self.spikeX < -math.abs(self.minSpikeXDistance)) or (self.spikeY > math.abs(self.minSpikeYDistance) or self.spikeY < -math.abs(self.minSpikeYDistance))) then
        self:changeToJumpState()
        self:setGSM(_, self.tickStepTable)
        self.spikeX = 0
        self.spikeY = 0
    end
end


--State Transitions
function Player:changeToIdleState()
    self:changeState("idle")
    self.currentStateNumber = 1
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
    self.currentStateNumber = 3
end

function Player:changeToFallState()
    self:changeState("fall")
    self.currentStateNumber = 4
end

function Player:changeToRunState()
    self:changeState("run")
    self.currentStateNumber = 2
end

function Player:changeToSlashState()
    if self.globalFlip == 1 then -- left
        Slash(self.x, "left", self.groundSlashDuration * (1/GSM))
    elseif self.globalFlip == 0 then -- right
        Slash(self.x, "right", self.groundSlashDuration * (1/GSM))
    end
    self:changeState("slash")
    self.currentStateNumber = 5

    pd.timer.performAfterDelay(self.groundSlashDuration * (1/GSM), function ()
        self:changeToIdleState()
    end)
end

function Player:changeToAirSlashState()
    Slash(self.x, "down", self.airSlashDuration * (1/GSM))

    self:changeState("airSlash")
    self.currentStateNumber = 6

    if self.y > ground - 30 then
       self:changeToJumpState()
    end
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
    self.currentStateNumber = 7
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
    self.currentStateNumber = 8
end

function Player:changeToAimSpikeState()
    Spike(self)
    self:setGSM(4)
    self:changeState("aimSpike")
    self.currentStateNumber = 10
end

function Player:changeToSpikeState()
    self.usedSpike = true
    self.spikeDistance = 12.5
    self.spikeX = math.cos(spikeAngle/(180/math.pi))
    self.spikeY = math.sin(spikeAngle/(180/math.pi))
    self.minSpikeXDistance = (self.spikeX / 2) * GSM
    self.minSpikeYDistance = (self.spikeY / 2) * GSM
    self:changeState("spike")
    self.currentStateNumber = 11
    self:setRotation(pd.getCrankPosition())
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
        self.yVelo = 0
        self.usedSpike = false
        self:setRotation(0)
        if self.currentState == "jump" then
            self:changeToIdleState()
        end
    end

    if self.y < ground then
        if self.y + (self.yVelo * multiplier) >= ground then -- if you're going to move past the ground.
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

function Player:doXDrag()
    if math.abs(self.xVelo) <= 1 * GSM then    
        self.xVelo = 0
    elseif self.xVelo > 0 then
        self.xVelo -= 0.7 * GSM
    elseif self.xVelo < 0 then
        self.xVelo += 0.7 * GSM
    end
end

function Player:doMoveX(direction, speed)
    if direction == "left" then
        if self.xVelo > -speed then
            self.xVelo -= 1 * GSM
        else
            self:doXDrag()
        end
    elseif direction == "right" then
        if self.xVelo < speed then
            self.xVelo += 1 * GSM
        else
            self:doXDrag()
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
                            self:setInvincibleTrue(800)
                            setShakeAmount(7)
                        else
                            self.HP -= damage
                            self:setInvincibleTrue(invincibleTime)
                            setShakeAmount(5)
                        end

                        print("player HP : " .. self.HP)
                    end
                end
            end
        end
    end
end
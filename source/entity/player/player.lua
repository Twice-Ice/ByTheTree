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
    local animationStates = {
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
            name = "dashFall",
            firstFrameIndex = 13,
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
    Player.super.init(self, playerTable, self.tickStepTable, animationStates)
    self:moveTo(x,y)
    self:setZIndex(ZIndexTable.Player)
    self:setStates(animationStates, true, "idle")

    -- Player Base Stats
    self.moveSpeed = 4
    self.jumpSpeed = 5
    self.yAcceleration = 1
    self.maxFallSpeed = 75
    self.holdJump = false
    self.isJumping = false
    self.groundSlashDuration = 200
    self.airSlashDuration = 300
    self.driftSpeed = self.moveSpeed
    spikeAngle = 0
    self.spikeDistance = 75
    self.minSpikeXDistance = self.moveSpeed
    self.minSpikeYDistance = self.moveSpeed
    self.spikeX = 0
    self.spikeY = 0
    self.currentStateNumber = 1
    realPlayerY = self.y
    realPlayerX = self.x

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

    distTraveled = pastX - playerX
    totalDistanceTraveled += math.sqrt(distTraveled^2) -- this could be bad for performance but idk
end


function Player:updateExternalVariables()
    realPlayerY = self.y
    realPlayerX = self.x

    print1 = self.currentStateNumber
end


-- main player controler
function Player:handleState()
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
    if self.isJumping then
        self:moveBy(0, -(self.jumpSpeed * GSM))
    end
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
    if pd.buttonJustPressed(pd.kButtonUp) then
        self:changeToJumpState()
    elseif pd.buttonJustPressed(pd.kButtonA) then
        self:changeToDashState()
    elseif pd.buttonJustPressed(pd.kButtonB) then
        self:changeToSlashState() 
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        self:changeToRunState("left")
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self:changeToRunState("right")
    else
        self:changeToIdleState()
    end
end

function Player:handleAirInput()
    if pd.buttonJustPressed(pd.kButtonA) then
        if self.y < ground - 25 then
            self:changeToAimSpikeState()
        end
    elseif pd.buttonJustPressed(pd.kButtonB) then
        if self.y < ground - 20 then
            self:changeToAirSlashState()
        end
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        playerX -= (self.moveSpeed * GSM)
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        playerX += (self.moveSpeed * GSM)
    end

    if ((self.yAcceleration * GSM) - self.jumpSpeed) > 0 and self.currentState ~= "fall" then
        self:changeToFallState()
    end
end

function Player:handleSlashInput()
    self.driftSpeed = self.moveSpeed * 1.25 -- player moves slightly faster durring a drift.
    if self.globalFlip == 1 then -- left
        playerX -= (self.driftSpeed * GSM)
    elseif self.globalFlip == 0 then -- right
        playerX += (self.driftSpeed * GSM)
    end
end

function Player:handleAirSlashInput()
    if self.globalFlip == 1 then -- left
        playerX -= (self.moveSpeed * GSM)
    elseif self.globalFlip == 0 then -- right
        playerX += (self.moveSpeed * GSM)
    end
end

function Player:handleDashInput()
    if self.globalFlip == 1 then -- left
        playerX -= (self.moveSpeed * GSM) * 2.25
    elseif self.globalFlip == 0 then -- right
        playerX += (self.moveSpeed * GSM) * 2.25
    end

    -- makes dash longer if the direction is held.
    -- these timers continue after your state is changed.
    pd.timer.performAfterDelay(200, function ()
        if pd.buttonIsPressed(pd.kButtonLeft) or pd.buttonIsPressed(pd.kButtonRight) then
            pd.timer.performAfterDelay(50, function ()
                if self.currentState == "dash" then
                    self:changeToIdleState()
                end
            end)
        else
            if self.currentState == "dash" then
                self:changeToIdleState()
            end
        end
    end)

    -- you can jump while mid dash.
    if pd.buttonJustPressed(pd.kButtonUp) then
        self:changeToDashJumpState()
    end
end

function Player:handleDashJumpInput()
    -- dash jumps are slightly slower than normal dashes.
    if self.globalFlip == 1 then -- left
        playerX -= (self.moveSpeed * GSM) * 2
    elseif self.globalFlip == 0 then -- right
        playerX += (self.moveSpeed * GSM) * 2
    end

    -- you can slash out of a dash if you were mid air.
    if pd.buttonJustPressed(pd.kButtonB) then
        if self.y < ground - 20 then
            self:changeToAirSlashState()
        end
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
        playerX -= (self.moveSpeed * GSM)
        self.globalFlip = 1
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        playerX += (self.moveSpeed * GSM)
        self.globalFlip = 0
    end
end

function Player:handleSpikeInput()
    -- movement
    playerX += (self.spikeX * self.spikeDistance) * GSM
    -- y movement if player would fall below ground.
    if self.y + self.spikeY >= ground then
        if self.y ~= ground then
            --self:moveBy(0, ((self.spikeY * (self.spikeDistance)) * GSM) - ground)
            self:moveBy(0, (self.spikeY * self.spikeDistance) - ((self.y + (self.spikeY * self.spikeDistance * GSM)) - ground))
        end
    else
        self:moveBy(0, ((self.spikeY * (self.spikeDistance)) * GSM))
    end

    self.spikeX *= .95 * GSM
    self.spikeY *= .95 * GSM
    -- https://media.discordapp.net/attachments/982141699029602337/1106751731020333106/IMG_20230512_191601.jpg?width=351&height=780 <- explanation in the form of a line graph.
    -- absolute value is so that if the numbers are negative (or not) then they are always consistent regardless of their original value (pos/neg)
    if not ((self.spikeX > math.abs(self.minSpikeXDistance) or self.spikeX < -math.abs(self.minSpikeXDistance)) or (self.spikeY > math.abs(self.minSpikeYDistance) or self.spikeY < -math.abs(self.minSpikeYDistance))) then
        self:changeToJumpState()
        self:setGSM()
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
    self.isJumping = true
    self:changeState("jump")
    self.currentStateNumber = 3
end

function Player:changeToFallState()
    self:changeState("fall")
    self.currentStateNumber = 4
end

function Player:changeToRunState(direction)
    if direction == "left" then
        playerX -= (self.moveSpeed * GSM)
        self.globalFlip = 1
    elseif direction == "right" then
        playerX += (self.moveSpeed * GSM)
        self.globalFlip = 0
    end
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
        self.driftSpeed = self.moveSpeed
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
    self:changeState("dash")
    self.currentStateNumber = 7
end

function Player:changeToDashJumpState()
    self.isJumping = true
    self:changeState("dashJump")
    self.currentStateNumber = 8
end

function Player:changeToAimSpikeState()
    Spike(self)
    self:setGSM(5)
    self:changeState("aimSpike")
    self.currentStateNumber = 10
end

function Player:changeToSpikeState()
    self.spikeDistance = 10
    self.spikeX = math.cos(spikeAngle/(180/math.pi))
    self.spikeY = math.sin(spikeAngle/(180/math.pi))
    self.minSpikeXDistance = (2 / self.spikeX) * GSM
    self.minSpikeYDistance = (2 / self.spikeY) * GSM
    self:changeState("spike")
    self.currentStateNumber = 11
end

--Physics Helper Functions

-- Gravity function, don't set multiplier to 0.
function Player:applyGravity(multiplier)
    if multiplier == nil then multiplier = 1 end

    if self.y < ground then
        if self.y + ((self.yAcceleration * GSM) * multiplier) > ground then
            --prevents player from falling below ground
            self:moveBy(0, ground - self.y)
            --resets player gravity because player is now on ground
            self.yAcceleration = 1
            self.isJumping = false
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
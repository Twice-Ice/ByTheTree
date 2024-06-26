import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/object"
import "CoreLibs/timer"
import "CoreLibs/crank"

import "entity/player/player"
import "entity/player/playerSlash"
import "entity/player/playerSpike"
import "entity/boss/boss"
import "environment/ground/ground"
import "environment/background/mountains"
import "environment/screenShake/screenShake"
import "scripts/AnimatedSprite"
import "entity/entity"

--local json = require 'dkjson'
--local debuggee = require 'vscode-debuggee'
--local startResult, breakerType = debuggee.start(json)
--print('debuggee start ->', startResult, breakerType)

local pd <const> = playdate
local gfx <const> = pd.graphics

-- fps variables
fps = 30
currentFrame = 1
-- if refreshrate is ever changed, change the default gamespeed to match it.
-- to slow down display just manually set fps without changing fps variable.
pd.display.setRefreshRate(fps)

-- game speed variables
defaultGameSpeed = 1 -- if defaultGameSpeed = fps then GSM = 1
gameSpeed = defaultGameSpeed
GSM = gameSpeed * fps/fps
--GSM; Game Speed Multiplier
-- higher gameSpeed means higher movement/calculations value. *everything related to movement  SHOULD be multiplied by the GSM*



-- player related variables
playerX = 0
bossState = nil
ground = 204
totalDistanceTraveled = 0
distanceTraveled = 0
--Z Index table
ZIndexTable = {
	Spike = 80,
	Ground = 70,
	Boss = 60,
	Player = 50,
	Slashes = 49,
	Mountains = 10,
}

local screenShakeSprite = ScreenShake()
function setShakeAmount(number)
	screenShakeSprite:setShakeAmount(number)
end

local function mountainsLeftTilePicker(tileNumber)
	local mountainsType = nil
	local currentMountainsTile = math.ceil(mountainsTileTable[tileNumber - 1]/3)

	if currentMountainsTile == 1 or currentMountainsTile == 3 then
		mountainsType = math.random(1, 2)
	elseif currentMountainsTile == 2 or currentMountainsTile == 4 then
		mountainsType = math.random(3, 4)
	end

	return ((mountainsType * 3) - 2) + math.random(0, 2)
end

local function mountainsRightTilePicker(tileNumber)
	local mountainsType = nil
	local currentMountainsTile = math.ceil(mountainsTileTable[tileNumber + 1]/3)

	if currentMountainsTile == 1 or currentMountainsTile == 2 then
		mountainsType = math.random(1, 2)
        if mountainsType == 2 then
            mountainsType += 1
        end
	elseif currentMountainsTile == 3 or currentMountainsTile == 4 then
		mountainsType = math.random(3, 4)
        if mountainsType == 3 then
            mountainsType -= 1
        end
	end

	return ((mountainsType * 3) - 2) + math.random(0, 2)
end

-- tables storing information regarding background and ground tile orders.
groundTileTable = {}
mountainsTileTable = {}
mountainsTileTable[0] = math.random(1, 12) -- PERFORMANCE!!!!!!!! this high of a number for the mountains tile table rendering might lead to a crash upon launch?
for i = 1, 4 do
	mountainsTileTable[i] = mountainsLeftTilePicker(i)
end
for i = -1, -4, -1 do
	mountainsTileTable[i] = mountainsRightTilePicker(i)
end



local function startGame()
	Player(200, ground)
	Boss(200, ground)
	for i = 0, 11 do
		local distance = 10
		Ground(0 + (i * 40), 230, 1, ZIndexTable.Ground, 0 + i)
		-- Ground(0 + (i * 40), 230 - distance, .9, ZIndexTable.Player - 1, 0 + i)
		-- Ground(0 + (i * 40), 230 - distance*2, .8, ZIndexTable.Player - 2, i)
		-- Ground(0 + (i * 40), 230 - distance*3, .7, ZIndexTable.Player - 3, i)
	end

	for i = 0, 5 do
		Mountains(0 + (i * 100), 120, 0 + i, mountainsTileTable[i], .25, ZIndexTable.Mountains)
	end
end

startGame()

function playdate.update()
	if currentFrame < 40 then
		currentFrame += 1
	else
		currentFrame = 1
	end

	GSM = gameSpeed * fps/fps
	pd.drawFPS(0,0) -- FPS widget
	gfx.sprite.update()
	pd.timer.updateTimers()
end
-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
local scene = composer.newScene()
--------------------------------------------

-- forward declarations and other locals
local screenW, screenH = display.actualContentWidth, display.actualContentHeight

local background, scoreText, circle, bgColor, scoreBg
local score = 0
local centerX = display.contentCenterX
local centerY = display.contentCenterY
local radius = 0.144 * screenH
local circleRad = 0.0144 * screenH
local speedLimit = 0.4
local speed = 0.04
local speedInc = 0.001
local time = 90
local points = { 0, 0, radius, 0 }
local sections = {}
local uiSound = audio.loadSound( "assets/ui-click.wav" )
local pointSound = audio.loadSound("assets/point-sound.wav")
local gameOverSound = audio.loadSound("assets/game-over.wav")
local homeBtn, pulseC, timeBar, innerBar, gameTimer, timerDec, homeBg
-- end game made local here, so it can be called inside handle touch
local endGame

local colors = {
	{0.267, 0.392, 0.678},
	{0.514, 0.773, 0.745},
	{0.941, 0.549, 0.682},
	{0.957, 0.878, 0.302}
}

-- filter a table
function table.filter(t, filterFunc)
    local filteredTable = {}
    for _, v in ipairs(t) do
        if filterFunc(v) then
            table.insert(filteredTable, v)
        end
    end
    return filteredTable
end

-- animate the white circle
local function animate()
    time = time + speed
    local angle = time
    local x = centerX + radius * math.cos(angle)
    local y = centerY + radius * math.sin(angle)
    circle.x, circle.y = x, y
end

-- show a pulse animation under the colorwheel
local function pulse()
	transition.to(pulseC, { time=150, xScale=1.1, yScale=1.1, onComplete=function()
        transition.to(pulseC, { time=150, xScale=1, yScale=1 })
    end })
end

-- update bg color, increment score etc when player chooses the right color
local function matchingColor()
	if (speed + speedInc) < speedLimit then
		speed = speed + speedInc
	end
	audio.play(pointSound)
	local randomInt = math.random(1, 3)
	local filteredCols = table.filter(colors, function(c) return c ~= bgColor end)
	bgColor = filteredCols[randomInt]
	background:setFillColor(bgColor[1], bgColor[2], bgColor[3], 0.875)
	innerBar:setFillColor(bgColor[1], bgColor[2], bgColor[3])
	innerBar.width = timeBar.width -10
	score = score +1
	scoreText.text = score
	scoreBg.width = scoreText.width * 1.25
	pulse()
end

-- check if table elements match
local function checkTable(sec, bg)
	if sec[1] ~= bg[1] then
		return false
	end
	if sec[2] ~= bg[2] then
		return false
	end
	if sec[3] ~= bg[3] then
		return false
	end
	return true
end

-- check if sector rgb and background rgb match
local function checkColor()
	local x, y = circle.x, circle.y
	local bg = background.fill
	if x >= centerX and y >= centerY then
		local sec = sections[1].fill
		return checkTable({sec.r, sec.g, sec.b},{bg.r, bg.g, bg.b})
	end
	if x < centerX and y >= centerY then
		local sec = sections[2].fill
		return checkTable({sec.r, sec.g, sec.b},{bg.r, bg.g, bg.b})
	end
	if x < centerX and y < centerY then
		local sec = sections[3].fill
		return checkTable({sec.r, sec.g, sec.b},{bg.r, bg.g, bg.b})
	end
	if x >= centerX and y < centerY then
		local sec = sections[4].fill
		return checkTable({sec.r, sec.g, sec.b},{bg.r, bg.g, bg.b})
	end
end

-- handling player's touch
local function handleTouch(event)
	if event.phase == "began" then
		local padding = homeBg.width/2
		-- check if player is exiting game
		if event.x < (homeBg.x + padding) and event.x > (homeBg.x - padding) and
		event.y < (homeBg.y + padding) and event.y > (homeBg.y - padding)  then
			return
		end
		if checkColor() then
			matchingColor()
		else
			endGame(circle)
		end
	end
end

-- leave game without animations
local function exitGame(event)
	if event.phase == "ended" or event.phase == "cancelled" then
		Runtime:removeEventListener("touch", handleTouch)
		homeBtn:removeEventListener("touch", exitGame)

		local highscore = system.getPreference("app", "highscore", "number")
		if highscore == nil or highscore < score then
			local appPreferences =
			{
				highscore = score
			}
			system.setPreferences( "app", appPreferences )
		end
		Runtime:removeEventListener("enterFrame", animate)
		timer.cancel(gameTimer)
		transition.cancelAll()
		audio.play( uiSound )
		composer.gotoScene( "menu", { time=300, effect="slideDown" } )
	end
end

-- update highscore if necessary and return to menu, object is either timer or circle
function endGame(object)
	Runtime:removeEventListener("touch", handleTouch)
	homeBtn:removeEventListener("touch", exitGame)
	local highscore = system.getPreference("app", "highscore", "number")
	if highscore == nil or highscore < score then
		local appPreferences =
		{
			highscore = score
		}
		system.setPreferences( "app", appPreferences )
	end
	audio.play(gameOverSound)
	Runtime:removeEventListener("enterFrame", animate)
	timer.cancel(gameTimer)
	transition.blink( object, { time=500 } )
	timer.performWithDelay( 1000, function ()
		transition.cancelAll()
		composer.gotoScene( "menu", { time=300, effect="slideDown" } )
	end )
end

-- create color sections
local function makeSection(rotation, r, g, b)
	local p = display.newPolygon(0, 0, points)
	p.anchorX, p.x = 0, display.contentCenterX
	p.anchorY, p.y = 0, display.contentCenterY
	p.rotation = rotation
	p:setFillColor(r, g, b)
	return p
end

-- decrease the game timer's time
local function decreaseTime()
	if (innerBar.width - timerDec < 0) == false then
		innerBar.width = innerBar.width - timerDec
	else
		innerBar.width = 0
		endGame(timeBar)
	end
end

-- animate the tutorial text
local function animateText(text)
	transition.to(text, { time=500, xScale=1.05, yScale=1.05, onComplete=function()
		transition.to(text, { time=500, xScale=1, yScale=1, onComplete=animateText })
	end })
end

local function startGame()
	Runtime:addEventListener("enterFrame", animate)
	Runtime:addEventListener( "touch", handleTouch )
	homeBtn:addEventListener("touch", exitGame)
	gameTimer = timer.performWithDelay( 10, decreaseTime, -1, "time" )
end

-- show tutorial the first time the game is played
local function showTutorial(sceneGroup)
	local overlayGroup = display.newGroup()
	local overlay = display.newRect(centerX, centerY, display.actualContentWidth, display.actualContentHeight)

	local tutOpt =
	{
		text = "Tap the screen when the white circle is on the same color as the background",
		x = centerX,
		y = circle.y + radius,
		width = screenW*0.7,
		height = 100,
		font = native.systemFont,
		fontSize = 16,
		align = "center"
	}
	local tutText = display.newText(tutOpt)
	animateText(tutText)

	local contOpt =
	{
		text = "[ Tap to continue ]",
		x = centerX,
		y = tutText.y + 100,
		width = screenW*0.8,
		height = 100,
		font = native.systemFont,
		fontSize = 14,
		align = "center"
	}
	local continueText = display.newText(contOpt)

	overlayGroup:insert(overlay)
	overlayGroup:insert(tutText)
	overlayGroup:insert(continueText)
	sceneGroup:insert(overlayGroup)

	overlay:setFillColor(0, 0, 0, 0.8)
	overlay:addEventListener("touch", function (e)
		if e.phase == "ended" then
			overlayGroup:removeSelf()
			startGame()
		end
	end)
end

function scene:create( event )

	-- Called when the scene's view does not exist.
	-- 
	-- INSERT code here to initialize the scene
	-- e.g. add display objects to 'sceneGroup', add touch listeners, etc.

	local sceneGroup = self.view
	background = display.newRect(centerX, centerY, screenW, screenH)
	bgColor = colors[1]
	background:setFillColor(bgColor[1], bgColor[2], bgColor[3], 0.875)
	sceneGroup:insert(background)

	scoreText = display.newText(0, centerX, 0.144*screenH, native.systemFontBold, 0.045*screenH )
	scoreBg = display.newRoundedRect(scoreText.x, scoreText.y, scoreText.width * 1.25, scoreText.height, 5)
	scoreBg:setFillColor(0, 0, 0, 0.4)
	sceneGroup:insert(scoreBg)
	sceneGroup:insert(scoreText)

	pulseC = display.newCircle(centerX, centerY, radius)
	pulseC:setFillColor(1,1,1, 0.3)
	sceneGroup:insert(pulseC)

	for i = 1, 20 do
		local angle = (math.pi / 2) * i / 20
		points[#points + 1] = radius * math.cos(angle)
		points[#points + 1] = radius * math.sin(angle)
	end

	local deg = 0
	for i, color in ipairs(colors) do
		local sec = makeSection(deg, color[1], color[2], color[3])
		sceneGroup:insert(sec)
		table.insert(sections, sec)
		deg = deg + 90
	end

	circle = display.newCircle(centerX, centerY - radius, circleRad)
	circle.x = centerX + radius * math.cos(time)
    circle.y = centerY + radius * math.sin(time)
	sceneGroup:insert(circle)

	local btnSize = 0.036*screenH

	homeBg = display.newRoundedRect(30, 0.1 * screenH, btnSize*1.25, btnSize*1.25, 5)
	homeBg:setFillColor(0,0,0,0.4)
	sceneGroup:insert(homeBg)

	homeBtn = display.newImageRect("assets/exit.png", btnSize, btnSize)
	homeBtn.x, homeBtn.y = 30, 0.1 * screenH
	homeBtn:setFillColor(1, 1, 1)
	sceneGroup:insert(homeBtn)

	local timerH = 0.03*screenH
	timeBar = display.newRoundedRect(centerX, scoreText.y + (0.07 * screenH), timerH/0.13, timerH, 10)
	innerBar = display.newRoundedRect(centerX, timeBar.y, timeBar.width - timerH/2, timerH/2, 10)
	innerBar:setFillColor(bgColor[1], bgColor[2], bgColor[3])
	innerBar.anchorX, innerBar.x = 0, centerX - innerBar.width/2
	timerDec = innerBar.width / 180
	sceneGroup:insert(timeBar)
	sceneGroup:insert(innerBar)
end


function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		-- Called when the scene is now on screen
		local firstTime = system.getPreference("app", "firstTime", "string")
		if (firstTime ~= "false") then
			local appPreferences = { firstTime = "false" }
			system.setPreferences( "app", appPreferences )
			showTutorial(sceneGroup)
		else
			startGame()
		end
	end
end

function scene:hide( event )
	local phase = event.phase
	
	if event.phase == "will" then
		-- Called when the scene is on screen and is about to move off screen
		Runtime:removeEventListener("touch", handleTouch)
		homeBtn:removeEventListener("touch", exitGame)
	elseif phase == "did" then
		-- Called when the scene is now off screen
		composer.removeScene("game")
	end

end

function scene:destroy( event )

	-- Called prior to the removal of scene's "view" (sceneGroup)
	local sceneGroup = self.view
	--  delete sections
	for i = 1, #sections do
		sections[i]:removeSelf()
		sections[i] = nil
	end
	sceneGroup:removeSelf()
	transition:cancelAll()
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene
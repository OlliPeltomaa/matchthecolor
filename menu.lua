-----------------------------------------------------------------------------------------
--
-- menu.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
local scene = composer.newScene()

--------------------------------------------

-- forward declarations and other locals
local playBtn, playText, hsText, textShadow, backgroundGroup, shadowBtn
local highscore = 0
local soundEffect = audio.loadSound( "assets/ui-click.wav" )

-- 'onRelease' event listener for playBtn
local function onPlayBtnRelease(event)

	-- go to game scene
	if (event.phase == "ended") then
		audio.play( soundEffect )
		composer.gotoScene( "game", "slideUp", 300 )
	end

	return true	-- indicates successful touch
end

local function rotateBackground(event)
	backgroundGroup.rotation = backgroundGroup.rotation + 0.2
end

local function animateText()
	transition.to(textShadow, { time=500, xScale=1.1, yScale=1.1, onComplete=function()
        transition.to(textShadow, { time=500, xScale=1, yScale=1 })
    end })
    transition.to(hsText, { time=500, xScale=1.1, yScale=1.1, onComplete=function()
        transition.to(hsText, { time=500, xScale=1, yScale=1, onComplete=animateText })
    end })
end

function scene:create( event )
	local sceneGroup = self.view

	-- Called when the scene's view does not exist.
	-- display a background image

	local rectWidth = display.actualContentHeight
	local rectHeight = display.actualContentHeight
	backgroundGroup = display.newGroup()
	backgroundGroup.x = display.contentCenterX
	backgroundGroup.y = display.contentCenterY
	backgroundGroup.anchorX = 0.5
	backgroundGroup.anchorY = 0.5

	local bg1 = display.newRect( backgroundGroup, -rectWidth/2, -rectHeight/2, rectWidth, rectHeight)
	bg1:setFillColor(0.267, 0.392, 0.678, 0.9)
	local bg2 = display.newRect( backgroundGroup, rectWidth/2, -rectHeight/2, rectWidth, rectHeight )
	bg2:setFillColor(0.514, 0.773, 0.745, 0.9)
	local bg3 = display.newRect( backgroundGroup, rectWidth/2, rectHeight/2, rectWidth, rectHeight )
	bg3:setFillColor(0.941, 0.549, 0.682, 0.9)
	local bg4 = display.newRect( backgroundGroup, -rectWidth/2, rectHeight/2, rectWidth, rectHeight )
	bg4:setFillColor(0.957, 0.878, 0.302, 0.9)

	backgroundGroup:insert(bg1)
	backgroundGroup:insert(bg2)
	backgroundGroup:insert(bg3)
	backgroundGroup:insert(bg4)
	-- create/position logo/title image on upper-half of the screen
	local titleH = 0.25 * display.actualContentHeight
	local titleLogo = display.newImageRect( "assets/match-the-color.png", titleH * 1.4, titleH )
	titleLogo.x = display.contentCenterX
	titleLogo.y = titleH * 1.25

	-- create a widget button (which will loads level1.lua on release)
	local btnH = 0.07 * display.actualContentHeight
	playBtn = display.newRoundedRect( display.contentCenterX, display.contentHeight/2 + btnH*2, btnH*3, btnH, 10 )
	playBtn:setFillColor(0.267, 0.392, 0.678)
	playText = display.newText("Play", playBtn.x, playBtn.y, native.systemFontBold, btnH*0.32)

	local padding = 0.007 * display.actualContentHeight
	shadowBtn = display.newRoundedRect(playBtn.x + padding, playBtn.y + padding, playBtn.width, playBtn.height, 10)
	shadowBtn:setFillColor(0, 0, 0, 0.5)

	local fontSize = 0.03 * display.actualContentHeight
	hsText = display.newText("Highscore " .. highscore, display.contentCenterX, display.contentCenterY, native.systemFontBold, fontSize)
	hsText:setFillColor(1,1,1)
	textShadow = display.newRoundedRect(hsText.x, hsText.y, hsText.width * 1.25, hsText.height * 1.25, 5)
	textShadow:setFillColor(0, 0, 0, 0.5)

	-- all display objects must be inserted into group
	sceneGroup:insert( backgroundGroup )
	sceneGroup:insert( titleLogo )
	sceneGroup:insert( shadowBtn )
	sceneGroup:insert( playBtn )
	sceneGroup:insert( playText )
	sceneGroup:insert( textShadow )
	sceneGroup:insert( hsText )

	playBtn:addEventListener("touch", onPlayBtnRelease)
end

function scene:show( event )
	local phase = event.phase

	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
		highscore = system.getPreference("app", "highscore", "number")
		if (highscore ~= nil) then
			hsText.text = "Highscore " .. highscore
			textShadow.text = "Highscore " .. highscore
		end
	elseif phase == "did" then
		-- Called when the scene is now on screen
		Runtime:addEventListener("enterFrame", rotateBackground)
		animateText()
	end
end

function scene:hide( event )
	local phase = event.phase

	if phase == "did" then
		-- Called when the scene is now off screen
		Runtime:removeEventListener("enterFrame", rotateBackground)
		transition.cancel()
	end
end

function scene:destroy( event )
	local sceneGroup = self.view

	-- Called prior to the removal of scene's "view" (sceneGroup)
	if playBtn then
		playBtn:removeSelf()	-- widgets must be manually removed
		playBtn = nil
	end
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene

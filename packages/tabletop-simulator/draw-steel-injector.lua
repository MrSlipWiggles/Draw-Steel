--[[LUAStart
className = "MeasurementToken"
versionNumber = "1.0.0"
scaleMultiplierX = 1.0
scaleMultiplierY = 1.0
scaleMultiplierZ = 1.0
finishedLoading = false
calibratedOnce = false
debuggingEnabled = false
onUpdateTriggerCount = 0
onSaveFrameCount = 0
onUpdateScale = 1.0
onUpdateGridSize = 1.0
loadTime = 1.0
saveVersion = 1
a = {}
triggerNames = {}
showing = false
savedAttachScales = {}

stamina = {value = 10, max = 10}
tempStamina = {value = 0}
recoveries = {value = 3, max = 3}
heroicResource = {value = 0}
surges = {value = 0}

player = false
measureMove = false
alternateDiag = false
stabilizeOnDrop = false
miniHighlight = "highlightNone"
highlightToggle = true
hideFromPlayers = false
firstEdit = true

options = {
    staminaToDescription = false,
    allowBelowZero = true,
    allowAboveMax = false,
    heightModifier = 110,
    showBaseButtons = true,
    showBarButtons = true,
    hideStaminaBar = false,
    hideTempStaminaBar = false,
    hideRecoveriesBar = false,
    hideHeroicResourceBar = false,
    hideSurgesBar = false,
    incrementBy = 1,
    rotation = 90
}

function updateSave()
    if onSaveFrameCount > 0 then
        onSaveFrameCount = 120
        return
    end
    onSaveFrameCount = 120
    startLuaCoroutine(self, "updateSaveActual")
end

function updateSaveActual()
    while onSaveFrameCount > 0 do
        onSaveFrameCount = onSaveFrameCount - 1
        coroutine.yield(0)
    end
    saveVersion = saveVersion + 1
    if debuggingEnabled then
        print(self.getName() .. " saving, version " .. saveVersion .. ".")
    end
    local encodedAttachScales = {}
    if #savedAttachScales > 0 then
        for _, scaleVector in ipairs(savedAttachScales) do
            table.insert(encodedAttachScales, {x=scaleVector.x, y=scaleVector.y, z=scaleVector.z})
        end
    end
    self.script_state = JSON.encode({
        scale_multiplier_x = scaleMultiplierX,
        scale_multiplier_y = scaleMultiplierY,
        scale_multiplier_z = scaleMultiplierZ,
        calibrated_once = calibratedOnce,
        stamina = stamina,
        tempStamina = tempStamina,
        recoveries = recoveries,
        heroicResource = heroicResource,
        surges = surges,
        options = options,
        encodedAttachScales = encodedAttachScales,
        statNames = statNames,
        player = player,
        measureMove = measureMove,
        alternateDiag = alternateDiag,
        stabilizeOnDrop = stabilizeOnDrop,
        miniHighlight = miniHighlight,
        highlightToggle = highlightToggle,
        hideFromPlayers = hideFromPlayers,
        saveVersion = saveVersion
    })
    return 1
end


function onLoad(save_state)

    function onLoad_helper()
        coroutine.yield(0)
        if stabilizeOnDrop == true and self.held_by_color == nil then
            coroutine.yield(0)
            stabilize()
        end
        local saved_data = nil
        local my_saved_data = nil
        local bestVersion = 0
        if save_state ~= "" then
            saved_data = JSON.decode(save_state)
            my_saved_data = saved_data
            if saved_data.saveVersion ~= nil then
                bestVersion = saved_data.saveVersion
            end
        end
        -- ALRIGHTY, let's see which state data we need to use
        states = self.getStates()
        if states ~= nil then
            for _, s in pairs(states) do
                test_data = JSON.decode(s.lua_script_state)
                if test_data ~= nil and test_data.saveVersion ~= nil and test_data.saveVersion > bestVersion then
                    saved_data = test_data
                    bestVersion = test_data.saveVersion
                    coroutine.yield(0)
                end
            end
        end
        if debuggingEnabled then
            print(self.getName() .. " best version: " .. bestVersion)
        end
        if saved_data ~= nil then
            if saved_data.stamina then
                for key,_ in pairs(stamina) do
                    stamina[key] = saved_data.stamina[key]
                end
            end
            if saved_data.tempStamina then
                for key,_ in pairs(tempStamina) do
                    tempStamina[key] = saved_data.tempStamina[key]
                end
            end
            if saved_data.recoveries then
                for key,_ in pairs(recoveries) do
                    recoveries[key] = saved_data.recoveries[key]
                end
            end
            if saved_data.heroicResource then
                for key,_ in pairs(heroicResource) do
                    heroicResource[key] = saved_data.heroicResource[key]
                end
            end
            if saved_data.surges then
                for key,_ in pairs(surges) do
                    surges[key] = saved_data.surges[key]
                end
            end
            if saved_data.options then
                for opt,_ in pairs(options) do
                    if saved_data.options[opt] ~= nil then
                        options[opt] = saved_data.options[opt]
                    end
                end
            end
            if saved_data.encodedAttachScales then
                for _,encodedScale in pairs(saved_data.encodedAttachScales) do
                    if debuggingEnabled then
                        print("loaded vector: " .. encodedScale.x .. ", " .. encodedScale.y .. ", " .. encodedScale.z)
                    end
                    table.insert(savedAttachScales, vector(encodedScale.x, encodedScale.y, encodedScale.z))
                    coroutine.yield(0)
                end
            end
            if saved_data.statNames then
                for stat,_ in pairs(statNames) do
                    statNames[stat] = saved_data.statNames[stat]
                end
            end
            -- Check if we need to override the scale calibration
            -- This state's calibration takes precedence over other states
            if my_saved_data ~= nil and my_saved_data.calibrated_once == true then
                saved_data.calibrated_once = my_saved_data.calibrated_once
                saved_data.scale_multiplier_x = my_saved_data.scale_multiplier_x
                saved_data.scale_multiplier_y = my_saved_data.scale_multiplier_y
                saved_data.scale_multiplier_z = my_saved_data.scale_multiplier_z
                if my_saved_data.options ~= nil then
                    options["heightModifier"] = my_saved_data.options["heightModifier"]
                end
            end
            if saved_data.scale_multiplier_x ~= nil then
                scaleMultiplierX = saved_data.scale_multiplier_x
            end
            if saved_data.scale_multiplier_y ~= nil then
                scaleMultiplierY = saved_data.scale_multiplier_y
            end
            if saved_data.scale_multiplier_z ~= nil then
                scaleMultiplierZ = saved_data.scale_multiplier_z
            end
            if saved_data.calibrated_once ~= nil then
                calibratedOnce = saved_data.calibrated_once
            end
            if saved_data.player ~= nil then
                player = saved_data.player
            end
            if saved_data.measureMove ~= nil then
                measureMove = saved_data.measureMove
            end
            if saved_data.alternateDiag ~= nil then
                alternateDiag = saved_data.alternateDiag
            end
            if saved_data.stabilizeOnDrop ~= nil then
                stabilizeOnDrop = saved_data.stabilizeOnDrop
            end
            if saved_data.miniHighlight ~= nil then
                miniHighlight = saved_data.miniHighlight
            end
            if saved_data.highlightToggle ~= nil then
                highlightToggle = saved_data.highlightToggle
            end
            if saved_data.hideFromPlayers ~= nil then
                hideFromPlayers = saved_data.hideFromPlayers
                if player == true then
                    hideFromPlayers = false
                end
            end
            if saved_data.saveVersion ~= nil then
                saveVersion = saved_data.saveVersion
                if debuggingEnabled then
                    print(self.getName() .. " loading, version " .. saveVersion .. ".")
                end
            end
        end
        self.setVar("className", "MeasurementToken")
        self.setVar("player", player)
        self.setVar("measureMove", measureMove)
        self.setVar("alternateDiag", alternateDiag)
        self.setVar("stabilizeOnDrop", stabilizeOnDrop)
        self.setVar("miniHighlight", miniHighlight)
        self.setVar("highlightToggle", highlightToggle)
        self.setVar("hideFromPlayers", hideFromPlayers)

        coroutine.yield(0)
        loadStageOne()
        coroutine.yield(0)
        loadStageTwo()
        coroutine.yield(0)

        finishedLoading = true
        self.setVar("finishedLoading", true)
        return 1
    end
    startLuaCoroutine(self, "onLoad_helper")
end

function loadStageOne()
    local script = self.getLuaScript()
    local xml = script:sub(script:find("StartXML")+8, script:find("StopXML")-1)
    self.UI.setXml(xml)
    coroutine.yield(0)
end

function loadStageTwo()
    self.UI.setAttribute("panel", "position", "0 0 -" .. self.getBounds().size.y / self.getScale().y * options.heightModifier)
    self.UI.setAttribute("staminaProgress", "percentage", stamina.value / stamina.max * 100)
    self.UI.setAttribute("staminaText", "text", stamina.value .. "/" .. stamina.max)
    self.UI.setAttribute("tempStaminaProgress", "percentage", tempStamina.value)
    self.UI.setAttribute("tempStaminaText", "text", tempStamina.value)
    self.UI.setAttribute("recoveriesProgress", "percentage", recoveries.value / recoveries.max * 100)
    self.UI.setAttribute("recoveriesText", "text", recoveries.value .. "/" .. recoveries.max)
    self.UI.setAttribute("heroicResourceText", "text", heroicResource.value)
    self.UI.setAttribute("surgesText", "text", surges.value)
    self.UI.setAttribute("increment", "text", options.incrementBy)
    coroutine.yield(0)

    for i,j in pairs(statNames) do
        if j == true then
            self.UI.setAttribute(i, "active", true)
            coroutine.yield(0)
        end
    end
    coroutine.yield(0)
    self.UI.setAttribute("statePanel", "width", getStatsCount()*300)

    if options.showBarButtons == true then
        self.UI.setAttribute("addStaminaSub", "active", true)
        self.UI.setAttribute("addTempStaminaSub", "active", true)
        self.UI.setAttribute("addRecoveriesSub", "active", true)
        coroutine.yield(0)
    end

    self.UI.setAttribute("hiddenButtonBar", "active", (options.hideStaminaBar == true and options.hideTempStaminaBar == true and options.hideRecoveriesBar == true and options.hideHeroicResourceBar == true and options.hideSurgesBar == true) and "True" or "False")

    self.UI.setAttribute("staminaBar", "active", options.hideStaminaBar == true and "False" or "True")
    self.UI.setAttribute("tempStaminaBar", "active", options.hideTempStaminaBar == true and "False" or "True")
    self.UI.setAttribute("recoveriesBar", "active", options.hideRecoveriesBar == true and "False" or "True")
    self.UI.setAttribute("heroicResourceBar", "active", options.hideHeroicResourceBar == true and "False" or "True")
    self.UI.setAttribute("surgesBar", "active", options.hideSurgesBar == true and "False" or "True")

    self.UI.setAttribute("addStaminaSub", "active", options.showBarButtons == true and "True" or "False")
    self.UI.setAttribute("addTempStaminaSub", "active", options.showBarButtons == true and "True" or "False")
    self.UI.setAttribute("addRecoveriesSub", "active", options.showBarButtons == true and "True" or "False")
    self.UI.setAttribute("panel", "rotation", options.rotation .. " 270 90")
    coroutine.yield(0)

    self.UI.setAttribute("PlayerCharToggle", "textColor", player == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("StabilizeToggle", "textColor", stabilizeOnDrop == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("HStamina", "textColor", options.hideStaminaBar == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("HTempStamina", "textColor", options.hideTempStaminaBar == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("HRecoveries", "textColor", options.hideRecoveriesBar == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("HHeroicResource", "textColor", options.hideHeroicResourceBar == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("HSurges", "textColor", options.hideSurgesBar == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("HB", "textColor", options.showBarButtons == true and "#AA2222" or "#FFFFFF")
    coroutine.yield(0)

    -- Look for the mini injector, if available
    local allObjects = getAllObjects()
    for _, obj in ipairs(allObjects) do
        if obj ~= self and obj ~= nil then
            local typeCheck = obj.getVar("className")
            if typeCheck == "MiniInjector" then
                autoCalibrate = obj.getVar("autoCalibrateEnabled")
                if autoCalibrate == true then
                    calibrateScale()
                end
                -- grab ui settings
                local injOptions = obj.getTable("options")
                alternateDiag = injOptions.alternateDiag
                self.UI.setAttribute("AlternateDiagToggle", "textColor", alternateDiag == true and "#AA2222" or "#FFFFFF")
                coroutine.yield(0)
                if player == true then
                    self.UI.setAttribute("staminaProgress", "visibility", "")
                    self.UI.setAttribute("recoveriesProgress", "visibility", "")
                    self.UI.setAttribute("staminaText", "visibility", "")
                    self.UI.setAttribute("tempStaminaText", "visibility", "")
                    self.UI.setAttribute("recoveriesText", "visibility", "")
                    self.UI.setAttribute("heroicResourceText", "visibility", "")
                    self.UI.setAttribute("surgesText", "visibility", "")
                    self.UI.setAttribute("addStaminaSub", "visibility", "")
                    self.UI.setAttribute("addTempStaminaSub", "visibility", "")
                    self.UI.setAttribute("addRecoveriesSub", "visibility", "")
                    self.UI.setAttribute("editPanel", "visibility", "")
                    self.UI.setAttribute("leftSide1", "visibility", "")
                    self.UI.setAttribute("editButton0", "visibility", "")
                    self.UI.setAttribute("editButton1", "visibility", "")
                    self.UI.setAttribute("editButtonS1", "visibility", "")
                    self.UI.setAttribute("leftSide2", "visibility", "")
                    self.UI.setAttribute("editButton2", "visibility", "")
                    self.UI.setAttribute("editButtonS2", "visibility", "")
                    self.UI.setAttribute("leftSide3", "visibility", "")
                    self.UI.setAttribute("editButton3", "visibility", "")
                    self.UI.setAttribute("editButtonS3", "visibility", "")
                    self.UI.setAttribute("leftSide4", "visibility", "")
                    self.UI.setAttribute("editButton4", "visibility", "")
                    self.UI.setAttribute("editButtonS4", "visibility", "")
                    self.UI.setAttribute("leftSide5", "visibility", "")
                    self.UI.setAttribute("editButton5", "visibility", "")
                    self.UI.setAttribute("editButtonS5", "visibility", "")
                    coroutine.yield(0)
                else
                    if injOptions.hideBar == true then
                        self.UI.setAttribute("staminaProgress", "visibility", "Black")
                        self.UI.setAttribute("recoveriesProgress", "visibility", "Black")
                    else
                        self.UI.setAttribute("staminaProgress", "visibility", "")
                        self.UI.setAttribute("recoveriesProgress", "visibility", "")
                    end
                    if injOptions.hideText == true then
                        self.UI.setAttribute("staminaText", "visibility", "Black")
                        self.UI.setAttribute("tempStaminaText", "visibility", "Black")
                        self.UI.setAttribute("recoveriesText", "visibility", "Black")
                        self.UI.setAttribute("heroicResourceText", "visibility", "Black")
                        self.UI.setAttribute("surgesText", "visibility", "Black")
                    else
                        self.UI.setAttribute("staminaText", "visibility", "")
                        self.UI.setAttribute("tempStaminaText", "visibility", "")
                        self.UI.setAttribute("recoveriesText", "visibility", "")
                        self.UI.setAttribute("heroicResourceText", "visibility", "")
                        self.UI.setAttribute("surgesText", "visibility", "")
                    end
                    if injOptions.editText == true then
                        self.UI.setAttribute("addStaminaSub", "visibility", "Black")
                        self.UI.setAttribute("addTempStaminaSub", "visibility", "Black")
                        self.UI.setAttribute("addRecoveriesSub", "visibility", "Black")
                        self.UI.setAttribute("editPanel", "visibility", "Black")
                    else
                        self.UI.setAttribute("addStaminaSub", "visibility", "")
                        self.UI.setAttribute("addTempStaminaSub", "visibility", "")
                        self.UI.setAttribute("addRecoveriesSub", "visibility", "")
                        self.UI.setAttribute("editPanel", "visibility", "")
                    end
                    coroutine.yield(0)
                    self.UI.setAttribute("editButton0", "visibility", "Black")
                    self.UI.setAttribute("leftSide1", "visibility", "Black")
                    self.UI.setAttribute("editButton1", "visibility", "Black")
                    self.UI.setAttribute("editButtonS1", "visibility", "Black")
                    self.UI.setAttribute("leftSide2", "visibility", "Black")
                    self.UI.setAttribute("editButton2", "visibility", "Black")
                    self.UI.setAttribute("editButtonS2", "visibility", "Black")
                    self.UI.setAttribute("leftSide3", "visibility", "Black")
                    self.UI.setAttribute("editButton3", "visibility", "Black")
                    self.UI.setAttribute("editButtonS3", "visibility", "Black")
                    coroutine.yield(0)
                end
            end
        end
    end

    rebuildContextMenu()
    coroutine.yield(0)

    updateHighlight()
    coroutine.yield(0)

    self.auto_raise = true
    self.interactable = true

    onUpdateScale = 1.0
    onUpdateGridSize = 1.0
    loadTime = os.clock()

    instantiateTriggers()
    coroutine.yield(0)

    if hideFromPlayers then
        aColors = Player.getAvailableColors()
        for k, v in ipairs(aColors) do
            if v == "Black" or v == "Grey" or v == "White" then
                table.remove(aColors, k)
            end
        end
        table.insert(aColors, "Grey")
        table.insert(aColors, "White")
        if debuggingEnabled then
            print(self.getName() .. " gone.")
        end
        self.setInvisibleTo(aColors)
        -- In this case attachments are already shrunk, don't worry about them
        coroutine.yield(0)
    end

    updateSave()

    return 1
end


function instantiateTriggers()
    for i = 0, 99 do
        triggerNames[i] = nil
        if self.AssetBundle ~= nil and self.AssetBundle.getTriggerEffects() ~= nil and self.AssetBundle.getTriggerEffects()[i] ~= nil then
            a[i] = false
            triggerNames[i] = self.AssetBundle.getTriggerEffects()[i].name
            -- create a new global function
            _G["TriggerFunction" .. i] = function()
                -- that simply calls our real target function
                self.AssetBundle.playTriggerEffect(i - 1)
            end
            coroutine.yield(0)
        end
    end
end

function onPlayerConnect(player)
    -- Wait 30 seconds for them to load fully.
    Wait.time(updateHighlight, 30)
end

function changeHighlight(player, value, id)
    miniHighlight = id
    highlightToggle = true
    updateHighlight(miniHighlight)
end

function toggleHighlight(player, value, id)
    highlightToggle = not highlightToggle
    updateHighlight()
end

function updateHighlight()
    if highlightToggle == false then
        self.highlightOff()
    elseif miniHighlight == "highlightNone" then
        self.highlightOff()
    elseif miniHighlight == "highlightWhite" then
        self.highlightOn(Color.White)
    elseif miniHighlight == "highlightBrown" then
        self.highlightOn(Color.Brown)
    elseif miniHighlight == "highlightRed" then
        self.highlightOn(Color.Red)
    elseif miniHighlight == "highlightOrange" then
        self.highlightOn(Color.Orange)
    elseif miniHighlight == "highlightYellow" then
        self.highlightOn(Color.Yellow)
    elseif miniHighlight == "highlightGreen" then
        self.highlightOn(Color.Green)
    elseif miniHighlight == "highlightTeal" then
        self.highlightOn(Color.Teal)
    elseif miniHighlight == "highlightBlue" then
        self.highlightOn(Color.Blue)
    elseif miniHighlight == "highlightPurple" then
        self.highlightOn(Color.Purple)
    elseif miniHighlight == "highlightPink" then
        self.highlightOn(Color.Pink)
    elseif miniHighlight == "highlightBlack" then
        self.highlightOn(Color.Black)
    end
    updateSave()
end

function onUpdate()
    onUpdateTriggerCount = onUpdateTriggerCount + 1
    if onUpdateTriggerCount > 60 then
        onUpdateTriggerCount = 0
        if finishedLoading == true and onUpdateScale ~= self.getScale().y then
            local newScale = dec3(0.3 * (1.0 / self.getScale().y))
            self.UI.setAttribute("panel", "scale", newScale .. " " .. newScale)
            self.UI.setAttribute("panel", "position", "0 0 -" .. (options.heightModifier + 1))
            self.UI.setAttribute("panel", "position", "0 0 -" .. options.heightModifier)
            onUpdateScale = self.getScale().y
            updateSave()
        end
        if finishedLoading == true and onUpdateGridSize ~= Grid.sizeX then
            resetScale()
        end
    end
end

function dec3(input)
    return math.floor(input * 1000.0) / 1000.0
end

function rebuildContextMenu()
    self.clearContextMenu()
    self.addContextMenuItem("UI Height UP", uiHeightUp, true)
    self.addContextMenuItem("UI Height DOWN", uiHeightDown, true)
    self.addContextMenuItem("UI Rotate 90", uiRotate90, true)
    if hideFromPlayers == true then
        self.addContextMenuItem("[X] Hide from players", toggleHideFromPlayers)
    else
        self.addContextMenuItem("[ ] Hide from players", toggleHideFromPlayers)
    end
    if calibratedOnce == true then
        self.addContextMenuItem("[X] Calibrate Scale", calibrateScale)
    else
        self.addContextMenuItem("[ ] Calibrate Scale", calibrateScale)
    end
    self.addContextMenuItem("Reset Scale", resetScale)
    self.addContextMenuItem("Reload Mini", reloadMini)
end

function uiHeightUp()
    options.heightModifier = options.heightModifier + 50
    self.UI.setAttribute("panel", "position", "0 0 -" .. options.heightModifier)
    updateSave()
end

function uiHeightDown()
    options.heightModifier = options.heightModifier - 50
    self.UI.setAttribute("panel", "position", "0 0 -" .. options.heightModifier)
    updateSave()
end

function uiRotate90()
    options.rotation = options.rotation + 90
    self.UI.setAttribute("panel", "rotation", options.rotation .. " 270 90")
    updateSave()
end

function toggleHideFromPlayers()
    if player == true and hideFromPlayers == false then
        print(self.getName() .. " is a player character, cannot hide.")
        return
    end
    hideFromPlayers = not hideFromPlayers
    if hideFromPlayers then
        aColors = Player.getAvailableColors()
        for k, v in ipairs(aColors) do
            if v == "Black" or v == "Grey" or v == "White" then
                table.remove(aColors, k)
            end
        end
        table.insert(aColors, "Grey")
        table.insert(aColors, "White")
        if debuggingEnabled then
            print(self.getName() .. " gone.")
        end
        self.setInvisibleTo(aColors)
        -- If the object has attachments, make them invisible too
        myAttach = self.removeAttachments()
        if #myAttach > 0 then
            savedAttachScales = {}
            if debuggingEnabled then
                print(self.getName() .. " has attach.")
            end
            for _, attachObj in ipairs(myAttach) do
                if debuggingEnabled then
                    print(attachObj.getName() .. " gone.")
                end
                --attachObj.setInvisibleTo(aColors)
                table.insert(savedAttachScales, attachObj.getScale())
                attachObj.setScale(vector(0, 0, 0))
                self.addAttachment(attachObj)
            end
        end
    else
        if debuggingEnabled then
            print(self.getName() .. " back.")
        end
        self.setInvisibleTo({})
        -- If the object has attachments, make them visible too
        myAttach = self.removeAttachments()
        if #myAttach > 0 then
            if debuggingEnabled then
                print(self.getName() .. " has attach.")
            end
            for attachIndex, attachObj in ipairs(myAttach) do
                if debuggingEnabled then
                    print(attachObj.getName() .. " back.")
                end
                attachObj.setScale(savedAttachScales[attachIndex])
                self.addAttachment(attachObj)
            end
        end
        savedAttachScales = {}
    end
    rebuildContextMenu()
    updateSave()
end

function togglePlayer()
    player = not player
    self.UI.setAttribute("PlayerCharToggle", "textColor", player == true and "#AA2222" or "#FFFFFF")
    if player == true and hideFromPlayers == true then
        toggleHideFromPlayers()
    end
    startLuaCoroutine(self, "loadStageTwo")
    updateSave()
end

function toggleMeasure()
    measureMove = not measureMove
    self.UI.setAttribute("MeasureMoveToggle", "textColor", measureMove == true and "#AA2222" or "#FFFFFF")
    updateSave()
end

function toggleStabilizeOnDrop()
    stabilizeOnDrop = not stabilizeOnDrop
    self.UI.setAttribute("StabilizeToggle", "textColor", stabilizeOnDrop == true and "#AA2222" or "#FFFFFF")
    updateSave()
end

function calibrateScale()
    currentScale = self.getScale()
    scaleMultiplierX = currentScale.x / Grid.sizeX
    scaleMultiplierY = currentScale.y / Grid.sizeX
    scaleMultiplierZ = currentScale.z / Grid.sizeX
    calibratedOnce = true
    if debuggingEnabled then
        print(self.getName() .. ": Calibrated scale with reference to grid.")
    end
    rebuildContextMenu()
    updateSave()
end

function reloadMini()
    self.reload()
end

function resetScale()
    if calibratedOnce == false then
        if debuggingEnabled == true then
            print(self.getName() .. ": Mini not calibrated to grid yet.")
        end
        return
    end
    newScaleX = Grid.sizeX * scaleMultiplierX
    newScaleY = Grid.sizeX * scaleMultiplierY
    newScaleZ = Grid.sizeX * scaleMultiplierZ
    if debuggingEnabled == true then
        print(self.getName() .. ": Reset scale with reference to grid.")
    end
    scaleVector = vector(newScaleX, newScaleY, newScaleZ)
    self.setScale(scaleVector)
    onUpdateGridSize = Grid.sizeX
    updateSave()
end

function onRotate(spin, flip, player_color, old_spin, old_flip)
    if flip ~= old_flip then
        destabilize()
        if stabilizeOnDrop == true then
            local object = self
            local timeWaiting = os.clock() + 0.26
            local rotateWatch = function()
                if object == nil or object.resting then
                    return true
                end
                local currentRotation = object.getRotation()
                local rotationTarget = object.getRotationSmooth()
                return os.clock() > timeWaiting and (rotationTarget == nil or currentRotation:angle(rotationTarget) < 0.5)
            end
            local rotateFunc = function()
                if object == nil then
                    return
                end
                if stabilizeOnDrop == true then
                    if debuggingEnabled == true then
                        print(self.getName() .. ": Stabilizing after rotation.")
                    end
                    stabilize()
                end
            end
            Wait.condition(rotateFunc, rotateWatch)
        end
    end
end

function onPickUp(pcolor)
    destabilize()
    if measureMove == true and hideFromPlayers == false and finishedLoading == true then
        createMoveToken(pcolor, self)
    end
end

function onDrop(dcolor)
    if stabilizeOnDrop == true then
        stabilize()
    end
    if measureMove == true then
        destroyMoveToken()
    end
end

function stabilize()
    if debuggingEnabled == true then
        print(self.getName() .. ": stabilizing.")
    end
    local rb = self.getComponent("Rigidbody")
    rb.set("freezeRotation", true)
end

function destabilize()
    if debuggingEnabled == true then
        print(self.getName() .. ": de-stabilizing.")
    end
    local rb = self.getComponent("Rigidbody")
    rb.set("freezeRotation", false)
end

function destroyMoveToken()
    if string.match(tostring(myMoveToken),"Custom") then
        destroyObject(myMoveToken)
    end
end

function createMoveToken(mcolor, mtoken)
    destroyMoveToken()
    if finishedLoading == false then
        return
    end
    tokenRot = Player[mcolor].getPointerRotation()
    movetokenparams = {
        image = "https://steamusercontent-a.akamaihd.net/ugc/1021697601906583980/C63D67188FAD8B02F1B58E17C7B1DB304B7ECBE3/",
        thickness = 0.1,
        type = 2
    }
    startloc = mtoken.getPosition()
    local hitList = Physics.cast({
        origin       = mtoken.getBounds().center,
        direction    = {0,-1,0},
        type         = 1,
        max_distance = 10,
        debug        = false,
    })
    for _, hitTable in ipairs(hitList) do
        -- Find the first object directly below the mini
        if hitTable ~= nil and hitTable.point ~= nil and hitTable.hit_object ~= mtoken then
            startloc = hitTable.point
            break
        else
            if debuggingEnabled == true then
                print("Did not find object below mini.")
            end
        end
    end
    tokenScale = {
        x= Grid.sizeX / 2.2,
        y= 0.1,
        z= Grid.sizeX / 2.2
    }
    spawnparams = {
        type = "Custom_Tile",
        position = startloc,
        rotation = {x = 0, y = tokenRot, z = 0},
        scale = tokenScale,
        sound = false
    }
    local moveToken = spawnObject(spawnparams)
    moveToken.setLock(true)
    moveToken.setCustomObject(movetokenparams)
    mtoken.setVar("myMoveToken", moveToken)
    moveToken.setVar("measuredObject", mtoken)
    moveToken.setVar("myPlayer", mcolor)
    moveToken.setVar("alternateDiag", alternateDiag)
    moveToken.setVar("className", "MeasurementToken_Move")
    moveToken.interactable = false
    moveButtonParams = {
        click_function = "onLoad",
        function_owner = self,
        label = "00",
        position = {x=0, y=0.1, z=0},
        width = 0,
        height = 0,
        font_size = 600
    }

    moveButton = moveToken.createButton(moveButtonParams)
    moveToken.setLuaScript("    function onUpdate() " ..
                           "        local finalDistance = 0 " ..
                           "        local mypos = self.getPosition() " ..
                           "        if measuredObject == nil or measuredObject.held_by_color == nil then " ..
                           "            destroyObject(self) " ..
                           "            return " ..
                           "        end " ..
                           "        local opos = measuredObject.getPosition() " ..
                           "        local oheld = measuredObject.held_by_color " ..
                           "        opos.y = opos.y-(Player[myPlayer].lift_height*5) " ..
                           "        mdiff = mypos - opos " ..
                           "        if oheld then " ..
                           "            if alternateDiag then " ..
                           "                mDistance = math.abs(mdiff.x) " ..
                           "                xDisGrid = math.floor(mDistance / Grid.sizeX + 0.5) " ..
                           "                zDistance = math.abs(mdiff.z) " ..
                           "                yDisGrid = math.floor(zDistance / Grid.sizeY + 0.5) " ..
                           "                if xDisGrid > yDisGrid then " ..
                           "                    finalDistance = math.floor(xDisGrid + yDisGrid/2.0) * 5.0 " ..
                           "                else" ..
                           "                    finalDistance = math.floor(yDisGrid + xDisGrid/2.0) * 5.0 " ..
                           "                end " ..
                           "            else " ..
                           "                mDistance = math.abs(mdiff.x) " ..
                           "                zDistance = math.abs(mdiff.z) " ..
                           "                if zDistance > mDistance then " ..
                           "                    mDistance = zDistance " ..
                           "                end " ..
                           "                mDistance = mDistance * (5.0 / Grid.sizeX) " ..
                           "                finalDistance = (math.floor((mDistance + 2.5) / 5.0)) " ..
                           "            end " ..
                           "            self.editButton({index = 0, label = tostring(finalDistance)}) " ..
                           "        end " ..
                           "    end ")

end

function reduceStamina()
    adjustStamina(-1)
end

function increaseStamina()
    adjustStamina(1)
end

function adjustStamina(difference)
    local intDiff = tonumber(difference)
    stamina.value = stamina.value + intDiff
    if stamina.value > stamina.max and not options.allowAboveMax then stamina.value = stamina.max end
    if stamina.value < 0 and not options.allowBelowZero then stamina.value = 0 end
    self.UI.setAttribute("staminaText", "text", stamina.value .. "/" .. stamina.max)
    self.UI.setAttribute("staminaProgress", "percentage", stamina.value / stamina.max * 100)
    updateRollers()
    updateSave()
end

function setStamina(newStamina)
    local intNewStamina = tonumber(newStamina)
    stamina.value = intNewStamina
    if stamina.value > stamina.max and not options.allowAboveMax then stamina.value = stamina.max end
    if stamina.value < 0 and not options.allowBelowZero then stamina.value = 0 end
    self.UI.setAttribute("staminaText", "text", stamina.value .. "/" .. stamina.max)
    self.UI.setAttribute("staminaProgress", "percentage", stamina.value / stamina.max * 100)
    updateRollers()
    updateSave()
end

function setStaminaMax(newStaminaMax)
    local intNewStaminaMax = tonumber(newStaminaMax)
    if (intNewStaminaMax < 0) then
      intNewStaminaMax = 0
    end
    if (stamina.value > stamina.max) then
      stamina.value = stamina.max
    end
    stamina.max = intNewStaminaMax
    if stamina.value > stamina.max and not options.allowAboveMax then stamina.value = stamina.max end
    if stamina.value < 0 and not options.allowBelowZero then stamina.value = 0 end
    self.UI.setAttribute("staminaText", "text", stamina.value .. "/" .. stamina.max)
    self.UI.setAttribute("staminaProgress", "percentage", stamina.value / stamina.max * 100)
    updateRollers()
    updateSave()
end

function adjustTempStamina(difference)
    local intDiff = tonumber(difference)
    tempStamina.value = tempStamina.value + intDiff
    if tempStamina.value < 0 then tempStamina.value = 0 end
    self.UI.setAttribute("tempStaminaText", "text", tempStamina.value)
    updateSave()
end

function adjustRecoveries(difference)
    local intDiff = tonumber(difference)
    recoveries.value = recoveries.value + intDiff
    if recoveries.value > recoveries.max and not options.allowAboveMax then recoveries.value = recoveries.max end
    if recoveries.value < 0 and not options.allowBelowZero then recoveries.value = 0 end
    self.UI.setAttribute("recoveriesText", "text", recoveries.value .. "/" .. recoveries.max)
    self.UI.setAttribute("recoveriesProgress", "percentage", recoveries.value / recoveries.max * 100)
    updateRollers()
    updateSave()
end

function adjustHeroicResource(difference)
    local intDiff = tonumber(difference)
    heroicResource.value = heroicResource.value + intDiff
    if heroicResource.value < 0 then heroicResource.value = 0 end
    self.UI.setAttribute("heroicResourceText", "text", heroicResource.value)
    updateSave()
end

function adjustSurges(difference)
    local intDiff = tonumber(difference)
    surges.value = surges.value + intDiff
    if surges.value < 0 then surges.value = 0 end
    self.UI.setAttribute("surgesText", "text", surges.value)
    updateSave()
end

function updateRollers()
    local allObjects = getAllObjects()
    for _, obj in ipairs(allObjects) do
        local className = obj.getVar("className")
        if className == "MiniInjector" then
            obj.call("updateFromGuid", self.guid)
        end
    end
end

function onEndEdit(player, value, id)
    if id == "increment" then
        options.incrementBy = tonumber(value)
        self.UI.setAttribute("increment", "text", options.incrementBy)
    end
    updateSave()
end

function onClickEx(params)
    onClick(params.player, params.value, params.id)
end

function add() onClick(-1, - 1, "addStamina") end
function sub() onClick(-1, - 1, "subStamina") end

function onClick(player_in, value, id)
    if id == "leftSide1" or id == "leftSide2" or id == "leftSide3" then
        if showing ~= true then
            showAllButtons()
        else
            self.clearButtons()
            showing = false
        end
    elseif id == "editButton0" or id == "editButton1" or id == "editButton2" or id == "editButton3" then
        if firstEdit == true or self.UI.getAttribute("editPanel", "active") == "False" or self.UI.getAttribute("editPanel", "active") == nil then
            self.UI.setAttribute("editPanel", "active", true)
            self.UI.setAttribute("statePanel", "active", false)
            firstEdit = false
        else
            self.UI.setAttribute("editPanel", "active", false)
            self.UI.setAttribute("statePanel", "active", true)
        end
    elseif id == "subHeight" or id == "addHeight" then
        if id == "addHeight" then
            options.heightModifier = options.heightModifier + getIncrement(value)
        else
            options.heightModifier = options.heightModifier - getIncrement(value)
        end
        self.UI.setAttribute("panel", "position", "0 0 -" .. options.heightModifier)
    elseif id == "subRotation" or id == "addRotation" then
        if id == "addRotation" then
            options.rotation = options.rotation + getIncrement(value)
        else
            options.rotation = options.rotation - getIncrement(value)
        end
        self.UI.setAttribute("panel", "rotation", options.rotation .. " 270 90")
    elseif id == "HStamina" then
        options.hideStaminaBar = not options.hideStaminaBar
        Wait.frames(function()
            self.UI.setAttribute("HStamina", "textColor", options.hideStaminaBar == true and "#AA2222" or "#FFFFFF")
            self.UI.setAttribute("staminaBar", "active", options.hideStaminaBar == true and "False" or "True")
            updateHiddenButtonBar()
        end, 1)
    elseif id == "HTempStamina" then
        options.hideTempStaminaBar = not options.hideTempStaminaBar
        Wait.frames(function()
            self.UI.setAttribute("HTempStamina", "textColor", options.hideTempStaminaBar == true and "#AA2222" or "#FFFFFF")
            self.UI.setAttribute("tempStaminaBar", "active", options.hideTempStaminaBar == true and "False" or "True")
            updateHiddenButtonBar()
        end, 1)
    elseif id == "HRecoveries" then
        options.hideRecoveriesBar = not options.hideRecoveriesBar
        Wait.frames(function()
            self.UI.setAttribute("HRecoveries", "textColor", options.hideRecoveriesBar == true and "#AA2222" or "#FFFFFF")
            self.UI.setAttribute("recoveriesBar", "active", options.hideRecoveriesBar == true and "False" or "True")
            updateHiddenButtonBar()
        end, 1)
    elseif id == "HHeroicResource" then
        options.hideHeroicResourceBar = not options.hideHeroicResourceBar
        Wait.frames(function()
            self.UI.setAttribute("HHeroicResource", "textColor", options.hideHeroicResourceBar == true and "#AA2222" or "#FFFFFF")
            self.UI.setAttribute("heroicResourceBar", "active", options.hideHeroicResourceBar == true and "False" or "True")
            updateHiddenButtonBar()
        end, 1)
    elseif id == "HSurges" then
        options.hideSurgesBar = not options.hideSurgesBar
        Wait.frames(function()
            self.UI.setAttribute("HSurges", "textColor", options.hideSurgesBar == true and "#AA2222" or "#FFFFFF")
            self.UI.setAttribute("surgesBar", "active", options.hideSurgesBar == true and "False" or "True")
            updateHiddenButtonBar()
        end, 1)
    elseif id == "HB" then
        if options.showBarButtons then
            self.UI.setAttribute("addStaminaSub", "active", false)
            self.UI.setAttribute("addTempStaminaSub", "active", false)
            self.UI.setAttribute("addRecoveriesSub", "active", false)
            options.showBarButtons = false
        else
            self.UI.setAttribute("addStaminaSub", "active", true)
            self.UI.setAttribute("addTempStaminaSub", "active", true)
            self.UI.setAttribute("addRecoveriesSub", "active", true)
            options.showBarButtons = true
        end
        self.UI.setAttribute("HB", "textColor", options.showBarButtons == true and "#AA2222" or "#FFFFFF")
    elseif id == "BZ" then
        options.allowBelowZero = not options.allowBelowZero
        self.UI.setAttribute("BZ", "textColor", options.allowBelowZero == true and "#AA2222" or "#FFFFFF")
        if stamina.value > stamina.max and not options.allowAboveMax then stamina.value = stamina.max end
        if stamina.value < 0 and not options.allowBelowZero then stamina.value = 0 end
        if recoveries.value > recoveries.max and not options.allowAboveMax then recoveries.value = recoveries.max end
        if recoveries.value < 0 and not options.allowBelowZero then recoveries.value = 0 end
        if tempStamina.value < 0 then tempStamina.value = 0 end
        if heroicResource.value < 0 then heroicResource.value = 0 end
        if surges.value < 0 then surges.value = 0 end
        self.UI.setAttribute("staminaProgress", "percentage", stamina.value / stamina.max * 100)
        self.UI.setAttribute("recoveriesProgress", "percentage", recoveries.value / recoveries.max * 100)
        self.UI.setAttribute("staminaText", "text", stamina.value .. "/" .. stamina.max)
        self.UI.setAttribute("tempStaminaText", "text", tempStamina.value)
        self.UI.setAttribute("recoveriesText", "text", recoveries.value .. "/" .. recoveries.max)
        self.UI.setAttribute("heroicResourceText", "text", heroicResource.value)
        self.UI.setAttribute("surgesText", "text", surges.value)
        if options.staminaToDescription then
            self.setDescription(stamina.value .. "/" .. stamina.max)
        end
        updateRollers()
    elseif id == "AM" then
        options.allowAboveMax = not options.allowAboveMax
        self.UI.setAttribute("AM", "textColor", options.allowAboveMax == true and "#AA2222" or "#FFFFFF")
        if stamina.value > stamina.max and not options.allowAboveMax then stamina.value = stamina.max end
        if stamina.value < 0 and not options.allowBelowZero then stamina.value = 0 end
        if recoveries.value > recoveries.max and not options.allowAboveMax then recoveries.value = recoveries.max end
        if recoveries.value < 0 and not options.allowBelowZero then recoveries.value = 0 end
        if tempStamina.value < 0 then tempStamina.value = 0 end
        if heroicResource.value < 0 then heroicResource.value = 0 end
        if surges.value < 0 then surges.value = 0 end
        self.UI.setAttribute("staminaProgress", "percentage", stamina.value / stamina.max * 100)
        self.UI.setAttribute("recoveriesProgress", "percentage", recoveries.value / recoveries.max * 100)
        self.UI.setAttribute("staminaText", "text", stamina.value .. "/" .. stamina.max)
        self.UI.setAttribute("tempStaminaText", "text", tempStamina.value)
        self.UI.setAttribute("recoveriesText", "text", recoveries.value .. "/" .. recoveries.max)
        self.UI.setAttribute("heroicResourceText", "text", heroicResource.value)
        self.UI.setAttribute("surgesText", "text", surges.value)
        if options.staminaToDescription then
            self.setDescription(stamina.value .. "/" .. stamina.max)
        end
        updateRollers()
    elseif statNames[id] ~= nil then
        self.UI.setAttribute(id, "active", false)
        self.UI.setAttribute("statePanel", "width", tonumber(self.UI.getAttribute("statePanel", "width")-300))
        statNames[id] = false
    else
        if id == "addStamina" then
            adjustStamina(getIncrement(value))
        elseif id == "subStamina" then
            adjustStamina(-getIncrement(value))
        elseif id == "addStaminaMax" then
            stamina.value = stamina.value + getIncrement(value)
            stamina.max = stamina.max + getIncrement(value)
        elseif id == "subStaminaMax" then
            stamina.value = stamina.value - getIncrement(value)
            stamina.max = stamina.max - getIncrement(value)
        elseif id == "addTempStamina" then
            adjustTempStamina(getIncrement(value))
        elseif id == "subTempStamina" then
            adjustTempStamina(-getIncrement(value))
        elseif id == "addRecoveries" then
            adjustRecoveries(getIncrement(value))
        elseif id == "subRecoveries" then
            adjustRecoveries(-getIncrement(value))
        elseif id == "addRecoveriesMax" then
            recoveries.value = recoveries.value + getIncrement(value)
            recoveries.max = recoveries.max + getIncrement(value)
        elseif id == "subRecoveriesMax" then
            recoveries.value = recoveries.value - getIncrement(value)
            recoveries.max = recoveries.max - getIncrement(value)
        elseif id == "addHeroicResource" then
            adjustHeroicResource(getIncrement(value))
        elseif id == "subHeroicResource" then
            adjustHeroicResource(-getIncrement(value))
        elseif id == "addSurges" then
            adjustSurges(getIncrement(value))
        elseif id == "subSurges" then
            adjustSurges(-getIncrement(value))
        end
        if stamina.value > stamina.max and not options.allowAboveMax then stamina.value = stamina.max end
        if stamina.value < 0 and not options.allowBelowZero then stamina.value = 0 end
        if recoveries.value > recoveries.max and not options.allowAboveMax then recoveries.value = recoveries.max end
        if recoveries.value < 0 and not options.allowBelowZero then recoveries.value = 0 end
        if tempStamina.value < 0 then tempStamina.value = 0 end
        if heroicResource.value < 0 then heroicResource.value = 0 end
        if surges.value < 0 then surges.value = 0 end
        self.UI.setAttribute("staminaProgress", "percentage", stamina.value / stamina.max * 100)
        self.UI.setAttribute("recoveriesProgress", "percentage", recoveries.value / recoveries.max * 100)
        self.UI.setAttribute("staminaText", "text", stamina.value .. "/" .. stamina.max)
        self.UI.setAttribute("tempStaminaText", "text", tempStamina.value)
        self.UI.setAttribute("recoveriesText", "text", recoveries.value .. "/" .. recoveries.max)
        self.UI.setAttribute("heroicResourceText", "text", heroicResource.value)
        self.UI.setAttribute("surgesText", "text", surges.value)
        if options.staminaToDescription then
            self.setDescription(stamina.value .. "/" .. stamina.max)
        end
        updateRollers()
    end
    updateSave()
end

function updateHiddenButtonBar()
    self.UI.setAttribute("hiddenButtonBar", "active", (options.hideStaminaBar == true and options.hideTempStaminaBar == true and options.hideRecoveriesBar == true and options.hideHeroicResourceBar == true and options.hideSurgesBar == true) and "True" or "False")
end

function getIncrement(value)
    if value == "-1" then
        return options.incrementBy
    else
        return 10
    end
end

function showAllButtons()
    local foundTriggers = false
    posi = 16
    posiY = 2
    counter = 0
    for k = 0, 99 do
        if triggerNames[k] ~= nil and triggerNames[k] ~= "Reset" then
            foundTriggers = true
            -- typical button params
            local button_parameters1 = {}
            button_parameters1.click_function = "trigger"

            button_parameters1.function_owner = self
            button_parameters1.label = triggerNames[k]
            button_parameters1.position = {posi, 4, posiY}
            button_parameters1.rotation = {0, 90, 0}
            button_parameters1.width = 2000
            button_parameters1.height = 400
            button_parameters1.font_size = 150

            if a[k] == true then
                button_parameters1.color = {74 / 255, 186 / 255, 74 / 255}
                button_parameters1.hover_color = {74 / 255, 186 / 255, 74 / 255}
            end

            counter = counter + 1
            if counter < 16 then
                posi = posi - 1

                if counter == 11 then
                    if posiY == 21.5 then
                        posiY = posiY + 6
                        posi = 16
                        counter = 0
                    end
                end
            else
                posi = 16
                if posiY == 2 then
                    posiY = posiY + 6
                else
                    posiY = posiY + 4.5
                end
                counter = 0
            end

            -- create a new global function
            _G["ClickFunction" .. k] = function(obj, col)
                -- that simply calls our real target function
                RealClickFunction(obj, k)
            end

            button_parameters1.click_function = "ClickFunction" .. k

            self.createButton(button_parameters1)
        end
    end
    if triggerNames == false then
        print("No triggers found.")
        return
    end
    showing = true
end

function RealClickFunction(obj, index)
    if a[index] ~= true then
        a[index] = true
        self.editButton({index = index - 2, color = {74 / 255, 186 / 255, 74 / 255}})
        self.editButton({index = index - 2, hover_color = {120 / 255, 255 / 255, 120 / 255}})
    else
        a[index] = false
        self.editButton({index = index - 2, color = {255 / 255, 255 / 255, 255 / 255}})
        self.editButton({index = index - 2, hover_color = {180 / 255, 180 / 255, 180 / 255}})
    end
    self.AssetBundle.playTriggerEffect(0)
    Wait.frames(updateTriggerAgain, 10)
end

function updateTriggerAgain()
    timer = 1
    for i = 0, 99 do
        if a[i] ~= nil then
            if a[i] == true then
                Wait.frames(_G["TriggerFunction" .. i], timer)
                timer = timer + 10
            end
        end
    end
end

function onCollisionEnter(a) -- if colliding with a status token, destroy it and apply to UI
    local newState = a.collision_object.getName()
    if statNames[newState] ~= nil then
        statNames[newState] = true
        a.collision_object.destruct()
        self.UI.setAttribute(newState, "active", true)
        Wait.frames(function() self.UI.setAttribute("statePanel", "width", getStatsCount()*300) end, 1)
    end
end

function getStatsCount()
    local count = 0
    for i,j in pairs(statNames) do
        if self.UI.getAttribute(i, "active") == "True" or self.UI.getAttribute(i, "active") == "true" then
            count = count + 1
        end
    end
    return count
end
LUAStop--lua]]


--[[XMLStart
<Defaults>
    <Button onClick="onClick" fontSize="50" textColor="#FFFFFF" color="#000000FF"/>
    <Text fontSize="50" color="#FFFFFF"/>
    <InputField fontSize="50" color="#000000FF" textColor="#FFFFFF" characterValidation="Integer"/>
</Defaults>

<Panel id="panel" position="0 0 -220" rotation="90 270 90" scale="0.2 0.2">
    <VerticalLayout id="bars" height="500">
        <Panel id="hiddenButtonBar" active="false">
            <HorizontalLayout height="25" width="400">
                 <Button id="editButton0" color="#00000000"><Image image="UpArrow" preserveAspect="true"></Image></Button>
            </HorizontalLayout>
        </Panel>
        <!-- Stamina Bar -->
        <Panel id="staminaBar" active="true">
            <ProgressBar id="staminaProgress" visibility="" height="100" width="600" showPercentageText="false" color="#000000FF" percentage="100" fillImageColor="#3f5e40ff"></ProgressBar>
            <Text id="staminaText" visibility="" height="100" width="600" text="10/10"></Text>
            <HorizontalLayout id="editButtonBar" height="100" width="600">
                 <Button id="leftSide1" text="" color="#00000000"></Button>
                 <Button id="editButton1" color="#00000000"></Button>
                 <Button id="editButtonS1" text="" color="#00000000"></Button>
            </HorizontalLayout>
            <Panel id="addStaminaSub" visibility="" height="100" width="825" active="false">
                <HorizontalLayout spacing="625">
                     <Button id="subStamina" text="-" color="#FFFFFF" textColor="#000000"></Button>
                     <Button id="addStamina" text="+" color="#FFFFFF" textColor="#000000"></Button>
                </HorizontalLayout>
            </Panel>
        </Panel>
        <!-- Temp Stamina Bar -->
        <Panel id="tempStaminaBar" active="true">
            <Text id="tempStaminaText" visibility="" height="100" width="600" text="0" fontSize="50"></Text>
            <HorizontalLayout id="editButtonBar" height="100" width="600">
                 <Button id="leftSide2" text="" color="#00000000"></Button>
                 <Button id="editButton2" color="#00000000"></Button>
                 <Button id="editButtonS2" text="" color="#00000000"></Button>
            </HorizontalLayout>
            <Panel id="addTempStaminaSub" visibility="" height="100" width="825" active="false">
                <HorizontalLayout spacing="625">
                     <Button id="subTempStamina" text="-" color="#FFFFFF" textColor="#000000"></Button>
                     <Button id="addTempStamina" text="+" color="#FFFFFF" textColor="#000000"></Button>
                </HorizontalLayout>
            </Panel>
        </Panel>
        <!-- Recoveries Bar -->
        <Panel id="recoveriesBar" active="true">
            <ProgressBar id="recoveriesProgress" visibility="" height="100" width="600" showPercentageText="false" color="#000000FF" percentage="100" fillImageColor="#525370ff"></ProgressBar>
            <Text id="recoveriesText" visibility="" height="100" width="600" text="3/3"></Text>
            <HorizontalLayout id="editButtonBar" height="100" width="600">
                 <Button id="leftSide3" text="" color="#00000000"></Button>
                 <Button id="editButton3" color="#00000000"></Button>
                 <Button id="editButtonS3" text="" color="#00000000"></Button>
            </HorizontalLayout>
            <Panel id="addRecoveriesSub" visibility="" height="100" width="825" active="false">
                <HorizontalLayout spacing="625">
                     <Button id="subRecoveries" text="-" color="#FFFFFF" textColor="#000000"></Button>
                     <Button id="addRecoveries" text="+" color="#FFFFFF" textColor="#000000"></Button>
                </HorizontalLayout>
            </Panel>
        </Panel>
        <!-- Heroic Resource Bar -->
        <Panel id="heroicResourceBar" active="true">
            <Text id="heroicResourceText" visibility="" height="100" width="600" text="0" fontSize="50"></Text>
            <HorizontalLayout id="editButtonBar" height="100" width="600">
                 <Button id="leftSide4" text="" color="#00000000"></Button>
                 <Button id="editButton4" color="#00000000"></Button>
                 <Button id="editButtonS4" text="" color="#00000000"></Button>
            </HorizontalLayout>
            <Panel id="addHeroicResourceSub" visibility="" height="100" width="825" active="false">
                <HorizontalLayout spacing="625">
                     <Button id="subHeroicResource" text="-" color="#FFFFFF" textColor="#000000"></Button>
                     <Button id="addHeroicResource" text="+" color="#FFFFFF" textColor="#000000"></Button>
                </HorizontalLayout>
            </Panel>
        </Panel>
        <!-- Surges Bar -->
        <Panel id="surgesBar" active="true">
            <Text id="surgesText" visibility="" height="100" width="600" text="0" fontSize="50"></Text>
            <HorizontalLayout id="editButtonBar" height="100" width="600">
                 <Button id="leftSide5" text="" color="#00000000"></Button>
                 <Button id="editButton5" color="#00000000"></Button>
                 <Button id="editButtonS5" text="" color="#00000000"></Button>
            </HorizontalLayout>
            <Panel id="addSurgesSub" visibility="" height="100" width="825" active="false">
                <HorizontalLayout spacing="625">
                     <Button id="subSurges" text="-" color="#FFFFFF" textColor="#000000"></Button>
                     <Button id="addSurges" text="+" color="#FFFFFF" textColor="#000000"></Button>
                </HorizontalLayout>
            </Panel>
        </Panel>
    </VerticalLayout>
    <Panel id="editPanel" height="600" width="1200" color="#000000C0" position="0 750 0" active="False">
        <HorizontalLayout>
            <VerticalLayout>
                <HorizontalLayout spacing="15" minheight="100">
                    <Button id="subHeight" text="◄" minwidth="60"></Button>
                    <Text>Height</Text>
                    <Button id="addHeight" text="►" minwidth="60"></Button>
                </HorizontalLayout>
                <HorizontalLayout spacing="15" minheight="100">
                    <Button id="subRotation" text="◄" minwidth="60"></Button>
                    <Text>Rotation</Text>
                    <Button id="addRotation" text="►" minwidth="60"></Button>
                </HorizontalLayout>
                <HorizontalLayout minheight="100">
                    <Button id="PlayerCharToggle" onClick="togglePlayer" text="Player Character" color="#000000FF"></Button>
                </HorizontalLayout>
                <HorizontalLayout spacing="15" minheight="100">
                    <Button id="subStaminaMax" text="◄" minwidth="60"></Button>
                    <Text>Stamina Max</Text>
                    <Button id="addStaminaMax" text="►" minwidth="60"></Button>
                </HorizontalLayout>
                <HorizontalLayout spacing="15" minheight="100">
                    <Button id="subRecoveriesMax" text="◄" minwidth="60"></Button>
                    <Text>Recoveries Max</Text>
                    <Button id="addRecoveriesMax" text="►" minwidth="60"></Button>
                </HorizontalLayout>
                <HorizontalLayout spacing="10" minheight="100">
                    <Text fontSize="50" minwidth="300">Increment by:</Text>
                    <InputField id="increment" onEndEdit="onEndEdit" minwidth="200" text="1"></InputField>
                </HorizontalLayout>
                <HorizontalLayout spacing="15" minheight="100">
                    <Button id="BZ" text="Allow Below Zero" color="#000000FF"></Button>
                </HorizontalLayout>
                <HorizontalLayout spacing="15" minheight="100">
                    <Button id="AM" text="Allow Above Max" color="#000000FF"></Button>
                </HorizontalLayout>
                <HorizontalLayout spacing="15" minheight="100">
                    <Button id="HB" text="Show Bar Buttons" color="#000000FF"></Button>
                </HorizontalLayout>
                <HorizontalLayout spacing="15" minheight="100">
                    <Button id="HStamina" text="Hide Stamina" color="#000000FF"></Button>
                </HorizontalLayout>
                <HorizontalLayout spacing="15" minheight="100">
                    <Button id="HTempStamina" text="Hide Temp Stamina" color="#000000FF"></Button>
                </HorizontalLayout>
                <HorizontalLayout spacing="15" minheight="100">
                    <Button id="HRecoveries" text="Hide Recoveries" color="#000000FF"></Button>
                </HorizontalLayout>
                <HorizontalLayout spacing="15" minheight="100">
                    <Button id="HHeroicResource" text="Hide Heroic Resource" color="#000000FF"></Button>
                </HorizontalLayout>
                <HorizontalLayout spacing="15" minheight="100">
                    <Button id="HSurges" text="Hide Surges" color="#000000FF"></Button>
                </HorizontalLayout>
            </VerticalLayout>
            <VerticalLayout>
                <Button id="highlightNone" onClick="changeHighlight" minwidth="100" minheight="60" fontSize="70" text="None" color="Grey"></Button>
                <Button id="highlightWhite" onClick="changeHighlight" minwidth="100" minheight="60" fontSize="70" text="" color="White"></Button>
                <Button id="highlightBrown" onClick="changeHighlight" minwidth="100" minheight="60" fontSize="70" text="" color="Brown"></Button>
                <Button id="highlightRed" onClick="changeHighlight" minwidth="100" minheight="60" fontSize="70" text="" color="Red"></Button>
                <Button id="highlightOrange" onClick="changeHighlight" minwidth="100" minheight="60" fontSize="70" text="" color="Orange"></Button>
                <Button id="highlightYellow" onClick="changeHighlight" minwidth="100" minheight="60" fontSize="70" text="" color="Yellow"></Button>
                <Button id="highlightGreen" onClick="changeHighlight" minwidth="100" minheight="60" fontSize="70" text="" color="Green"></Button>
                <Button id="highlightTeal" onClick="changeHighlight" minwidth="100" minheight="60" fontSize="70" text="" color="Teal"></Button>
                <Button id="highlightBlue" onClick="changeHighlight" minwidth="100" minheight="60" fontSize="70" text="" color="Blue"></Button>
                <Button id="highlightPurple" onClick="changeHighlight" minwidth="100" minheight="60" fontSize="70" text="" color="Purple"></Button>
                <Button id="highlightPink" onClick="changeHighlight" minwidth="100" minheight="60" fontSize="70" text="" color="Pink"></Button>
                <Button id="highlightBlack" onClick="changeHighlight" minwidth="100" minheight="60" fontSize="70" text="" color="Black"></Button>
                <Button id="highlightToggle" onClick="toggleHighlight" minwidth="100" minheight="60" fontSize="50" text="Toggle" color="Grey"></Button>
            </VerticalLayout>
        </HorizontalLayout>
    </Panel>
    <Panel id="statePanel" height="300" width="-5" position="0 370 0">
        <VerticalLayout>
            <HorizontalLayout spacing="5">
                STATSIMAGE
            </HorizontalLayout>
        </VerticalLayout>
    </Panel>
</Panel>
]]--XMLStop

className = "MiniInjector"
versionNumber = "1.0.0"
finishedLoading = false
debuggingEnabled = false
pingInitMinis = true
autostartOneWorld = true
initTableOnly = true
hideUpsideDownMinis = true
autoCalibrateEnabled = false
injectEverythingAllowed = false
injectEverythingActive = false
injectEverythingFrameCount = 0
updateEverythingActive = false
updateEverythingFrameCount = 0
updateEverythingIndex = 1
injectedFrameLimiter = 0
collisionProcessing = {}

options = {
    hideText = false,
    editText = false,
    hideBar = false,
    hideAll = false,
    showAll = true,
    measureMove = false,
    alternateDiag = false,
    playerChar = false,
    staminaToDescription = false,
    stamina = 10,
    tempStamina = 0,
    recoveries = 3,
    heroicResource = 0,
    surges = 0,
    initCurrentGUID = ""
}

initFigures = {}

function onSave()
    local save_state = JSON.encode({
        debugging_enabled = debuggingEnabled,
        ping_init_minis = pingInitMinis,
        autostart_oneworld = autostartOneWorld,
        init_table_only = initTableOnly,
        auto_calibrate_enabled = autoCalibrateEnabled,
        options = options,
    })
    return save_state
end

function onLoad(save_state)

    if save_state ~= "" then
        saved_data = JSON.decode(save_state)
        if saved_data ~= nil then
            if saved_data.options ~= nil then
                for opt,_ in pairs(saved_data.options) do
                    if saved_data.options[opt] ~= nil then
                        options[opt] = saved_data.options[opt]
                    end
                end
            end
            if saved_data.autostart_oneworld ~= nil then
                autostartOneWorld = saved_data.autostart_oneworld
            end
            if saved_data.init_table_only ~= nil then
                initTableOnly = saved_data.init_table_only
            end
            if saved_data.auto_calibrate_enabled ~= nil then
                autoCalibrateEnabled = saved_data.auto_calibrate_enabled
            end
        end
    end

    self.setVar("className", "MiniInjector")
    rebuildContextMenu()
    finishedLoading = true
    self.setVar("finishedLoading", true)
    self.setName("Draw Steel Injector " .. versionNumber)

    Wait.frames(updateSettingUI, 10)

    Wait.frames(initOneWorld, 60)

    Wait.frames(updateEverything, 120)
end

function updateSettingUI()
    -- Update options if needed for UI display
    for opt,_ in pairs(options) do
        if opt == "measureMove" or opt == "alternateDiag" or opt == "playerChar" or opt == "hideBar" or opt == "hideText" or opt == "editText" then
            if options[opt] then
                self.UI.setAttribute(opt, "value", "true")
                self.UI.setAttribute(opt, "text", "✘")
            else
                self.UI.setAttribute(opt, "value", "false")
                self.UI.setAttribute(opt, "text", "")
            end
            self.UI.setAttribute(opt, "textColor", "#FFFFFF")
        end
    end
end

function initOneWorld()
    if autostartOneWorld then
        local owHub = getOneWorldHub()
        if owHub ~= nil and owHub.getVar("iu") ~= nil then
            owHub.call("chkIUnit")
        end
    end
end

function rebuildContextMenu()
    self.clearContextMenu()
    if (initTableOnly) then
        self.addContextMenuItem("[X] Init Table Only", toggleInitTableOnly)
    else
        self.addContextMenuItem("[ ] Init Table Only", toggleInitTableOnly)
    end
    if (autoCalibrateEnabled) then
        self.addContextMenuItem("[X] Auto-Calibrate", toggleAutoCalibrate)
    else
        self.addContextMenuItem("[ ] Auto-Calibrate", toggleAutoCalibrate)
    end
    if (autostartOneWorld) then
        self.addContextMenuItem("[X] Auto-OneWorld", toggleAutostartOneWorld)
    else
        self.addContextMenuItem("[ ] Auto-OneWorld", toggleAutostartOneWorld)
    end
    self.addContextMenuItem("Inject EVERYTHING", injectEverything)
end

function toggleAutostartOneWorld()
    autostartOneWorld = not autostartOneWorld
    rebuildContextMenu()
end

function toggleInitTableOnly()
    initTableOnly = not initTableOnly
    rebuildContextMenu()
end

function updateEverything()
    updateEverythingActive = true
end

function toggleAutoCalibrate()
    autoCalibrateEnabled = not autoCalibrateEnabled
    if autoCalibrateEnabled then
        print("Automatic calibration ENABLED. Injected minis will automatically be calibrated to the current grid.")
    else
        print("Automatic calibration DISABLED.")
    end
    rebuildContextMenu()
end

function injectEverything()
    if injectEverythingAllowed == false then
        print("INJECT EVERYTHING. This will inject movement tokens into literally every object in this save. Only use this in an empty save with only miniatures and measurement tools. Click it again to confirm.")
        injectEverythingAllowed = true
        return
    end
    injectEverythingActive = true
end

function onUpdate()
    if injectedFrameLimiter > 0 then
        injectedFrameLimiter = injectedFrameLimiter - 1
    end
    if injectedFrameLimiter == 0 and #collisionProcessing > 0 then
        local collision_info = table.remove(collisionProcessing)
        local object = collision_info.collision_object
        if object ~= nil then
            local hitList = Physics.cast({
                origin       = object.getBounds().center,
                direction    = {0,-1,0},
                type         = 1,
                max_distance = 10,
                debug        = false,
            })
            local attemptCount = 1
            for _, hitTable in ipairs(hitList) do
                -- This hit makes sure the injector is the first object directly below the mini
                if hitTable ~= nil and hitTable.hit_object == self then
                    if self.getRotationValue() == "[00ff00]INJECT[-]" then
                        objClassName = object.getVar("className")
                        if objClassName ~= "MiniInjector" and
                           objClassName ~= "MeasurementToken" and
                           objClassName ~= "MeasurementToken_Move" and
                           objClassName ~= "MeasurementTool" then
                            if debuggingEnabled == true then
                                print("[00ff00]Injecting[-] mini " .. object.getName() .. ".")
                            end
                            injectToken(object)
                            injectedFrameLimiter = 60
                            break
                        end
                    elseif self.getRotationValue() == "[ff0000]REMOVE[-]" then
                        if object.getVar("className") == "MeasurementToken" then
                            if debuggingEnabled == true then
                                print("[ff0000]Removing[-] injection from " .. object.getName() .. ".")
                            end
                            object.call("destroyMoveToken")
                            object.script_state = ""
                            object.script_code = ""
                            object.setLuaScript("")
                            object.reload()
                            break
                        end
                    else
                        error("Invalid rotation.")
                        break
                    end
                else
                    attemptCount = attemptCount + 1
                    if (debuggingEnabled) then
                        print("Did not find injector, index "..tostring(attemptCount)..".")
                    end
                end
            end
        end
    end
    if injectEverythingActive == true then
        injectEverythingFrameCount = injectEverythingFrameCount + 1
        if injectEverythingFrameCount >= 5 then
            injectEverythingFrameCount = 0
            local allObjects = getAllObjects()
            for _, obj in ipairs(allObjects) do
                if obj ~= self and obj ~= nil then
                    objClassName = obj.getVar("className")
                    if objClassName ~= "MeasurementToken" and
                       objClassName ~= "MeasurementToken_Move" and
                       objClassName ~= "MeasurementTool" then
                        print("[00ff00]Injecting[-] mini " .. obj.getName() .. ".")
                        injectToken(obj)
                        return
                    end
                end
            end
            injectEverythingActive = false
            print("[00ff00]Inject EVERYTHING complete.[-]")
        end
    end

    if updateEverythingActive == true then
        updateEverythingFrameCount = updateEverythingFrameCount + 1
        if updateEverythingFrameCount >= 5 then
            updateEverythingFrameCount = 0
            local allObjects = getAllObjects()
            for _, obj in ipairs(allObjects) do
                if obj ~= self and obj ~= nil then
                    objClassName = obj.getVar("className")
                    if objClassName == "MeasurementToken" then
                        tokenVersion = obj.getVar("versionNumber")
                        if versionNumber ~= tokenVersion then
                            -- Wait for the mini to fully load before killing it
                            if obj.getVar("finishedLoading") ~= true then
                                return
                            end
                            print("[00ff00]Updating[-] mini " .. updateEverythingIndex .. ".")
                            updateEverythingIndex = updateEverythingIndex + 1
                            injectToken(obj)
                            return
                        end
                    end
                end
            end
        end
    end
end

function onObjectSpawn(object)
    if finishedLoading == false then
        return
    end
    local dropWatch = function()
        if object == nil then
            return true
        end
        if object.resting then
            if object.getVar("className") ~= "MeasurementToken" then
                return true
            end
            -- Wait for the mini to fully load before killing it
            if object.getVar("finishedLoading") == true then
                return true
            end
        end
        return false
    end
    local dropFunc = function()
        if object == nil then
            return
        end
        if object.getVar("className") == "MeasurementToken" then
            tokenVersion = object.getVar("versionNumber")
            if versionNumber ~= tokenVersion then
                print("[00ff00]Updating[-] spawned mini.")
                injectToken(object)
                return
            else
                object.call('resetScale')
            end
        end
    end
    Wait.condition(dropFunc, dropWatch)
end

function allOff()
    for i,j in pairs(getAllObjects()) do
        if j ~= self then
            if j.getLuaScript():find("StartXML") then
                j.UI.setAttribute("panel", "active", "false")
            end
        end
    end
end

function toggleCheckBox(player, value, id)
    if self.UI.getAttribute(id, "value") == "false" then
        self.UI.setAttribute(id, "value", "true")
        self.UI.setAttribute(id, "text", "✘")
        options[id] = true
    else
        self.UI.setAttribute(id, "value", "false")
        self.UI.setAttribute(id, "text", "")
        options[id] = false
    end
    self.UI.setAttribute(id, "textColor", "#FFFFFF")
    for i,j in pairs(getAllObjects()) do
        if j ~= self then
            if j.getLuaScript():find("StartXML") then
                if id == "alternateDiag" then
                    j.call('toggleAlternateDiag')
                end
                if j.getVar("player") then
                    if id == "hideBar" then
                        j.UI.setAttribute("staminaProgress", "visibility", "")
                        j.UI.setAttribute("recoveriesProgress", "visibility", "")
                    elseif id == "hideText" then
                        j.UI.setAttribute("staminaText", "visibility", "")
                        j.UI.setAttribute("tempStaminaText", "visibility", "")
                        j.UI.setAttribute("recoveriesText", "visibility", "")
                        j.UI.setAttribute("heroicResourceText", "visibility", "")
                        j.UI.setAttribute("surgesText", "visibility", "")
                    elseif id == "editText" then
                        j.UI.setAttribute("addStaminaSub", "visibility", "")
                        j.UI.setAttribute("addTempStaminaSub", "visibility", "")
                        j.UI.setAttribute("addRecoveriesSub", "visibility", "")
                        j.UI.setAttribute("editPanel", "visibility", "")
                    end
                else
                    if id == "hideBar" then
                        j.UI.setAttribute("staminaProgress", "visibility", options[id] == true and "Black" or "")
                        j.UI.setAttribute("recoveriesProgress", "visibility", options[id] == true and "Black" or "")
                    elseif id == "hideText" then
                        j.UI.setAttribute("staminaText", "visibility", options[id] == true and "Black" or "")
                        j.UI.setAttribute("tempStaminaText", "visibility", options[id] == true and "Black" or "")
                        j.UI.setAttribute("recoveriesText", "visibility", options[id] == true and "Black" or "")
                        j.UI.setAttribute("heroicResourceText", "visibility", options[id] == true and "Black" or "")
                        j.UI.setAttribute("surgesText", "visibility", options[id] == true and "Black" or "")
                    elseif id == "editText" then
                        j.UI.setAttribute("addStaminaSub", "visibility", options[id] == true and "Black" or "")
                        j.UI.setAttribute("addTempStaminaSub", "visibility", options[id] == true and "Black" or "")
                        j.UI.setAttribute("addRecoveriesSub", "visibility", options[id] == true and "Black" or "")
                        j.UI.setAttribute("editPanel", "visibility", options[id] == true and "Black" or "")
                    end
                end
            end
        end
    end
end

function toggleHideBars(player, value, id)
    for i,j in pairs(getAllObjects()) do
        if j ~= self then
            if j.getLuaScript():find("StartXML") then
                if not options.hideAll then
                    j.UI.setAttribute("resourceBar", "active", "false")
                    j.UI.setAttribute("resourceBarS", "active", "false")
                    j.UI.setAttribute("extraBar", "active", "false")
                else
                    j.UI.setAttribute("resourceBar", "active", "true")
                    local objTable = j.getTable("options")
                    if not objTable.hideMana then
                        j.UI.setAttribute("resourceBarS", "active", "true")
                    end
                    if not objTable.hideExtra then
                        j.UI.setAttribute("extraBar", "active", "true")
                    end
                end
            end
        end
    end
    options.hideAll = not options.hideAll
end


function toggleOnOff(player, value, id)
    if self.UI.getAttribute(id, "value") == "false" then
        self.UI.setAttribute(id, "value", "true")
        options[id] = true
    else
        self.UI.setAttribute(id, "value", "false")
        options[id] = false
    end
    for i,j in pairs(getAllObjects()) do
        if j ~= self then
            if j.getLuaScript():find("StartXML") then
                j.UI.setAttribute("panel", "active", options[id] == true and "true" or "false")
            end
        end
    end
end

function onEndEdit(player, value, id)
    if value ~= "" then
        options[id] = tonumber(value)
        self.UI.setAttribute(id, "text", value)
    end
end

function onCollisionEnter(collision_info)
    table.insert(collisionProcessing, collision_info)
end

function injectToken(object)
    local assets = self.UI.getCustomAssets()
    object.UI.setCustomAssets(assets)
    local script = self.getLuaScript()
    local xml = script:sub(script:find("XMLStart")+8, script:find("XMLStop")-1)
    local newScript = script:sub(script:find("LUAStart")+8, script:find("LUAStop")-1)
    local stats = "statNames = {"
    local xmlStats = ""
    for j,i in pairs(assets) do
        stats = stats .. i.name .. " = false, "
        xmlStats = xmlStats .. '<Button id="' .. i.name .. '" color="#FFFFFF00" active="false"><Image image="' .. i.name .. '" preserveAspect="true"></Image></Button>\n'
    end
    newScript = "--[[StartXML\n" .. xml:gsub("STATSIMAGE", xmlStats) .. "StopXML--xml]]" .. stats:sub(1, -3) .. "}\n" .. newScript
    xml = xml:gsub("STATSIMAGE", xmlStats)
    
    if not options.hideText and options.staminaToDescription then
        object.setDescription(options.stamina .. "/" .. options.stamina)
    end
    
    newScript = newScript:gsub("stamina = {value = 10, max = 10}", "stamina = {value = " .. options.stamina ..", max = " .. options.stamina .. "}")
    newScript = newScript:gsub("tempStamina = {value = 0}", "tempStamina = {value = " .. options.tempStamina .. "}")
    newScript = newScript:gsub("recoveries = {value = 3, max = 3}", "recoveries = {value = " .. options.recoveries ..", max = " .. options.recoveries .. "}")
    newScript = newScript:gsub("heroicResource = {value = 0}", "heroicResource = {value = " .. options.heroicResource .. "}")
    newScript = newScript:gsub("surges = {value = 0}", "surges = {value = " .. options.surges .. "}")

    if options.measureMove == true then
        newScript = newScript:gsub("measureMove = false", "measureMove = true")
    end
    if options.playerChar == true then
        newScript = newScript:gsub("player = false", "player = true")
        if options.staminaToDescription == true then
            newScript = newScript:gsub("staminaToDescription = false,", "staminaToDescription = true,")
        end
    else
        if options.hideText == true then
            newScript = newScript:gsub('id="staminaText" visibility=""', 'id="staminaText" visibility="Black"')
            newScript = newScript:gsub('id="tempStaminaText" visibility=""', 'id="tempStaminaText" visibility="Black"')
            newScript = newScript:gsub('id="recoveriesText" visibility=""', 'id="recoveriesText" visibility="Black"')
            newScript = newScript:gsub('id="heroicResourceText" visibility=""', 'id="heroicResourceText" visibility="Black"')
            newScript = newScript:gsub('id="surgesText" visibility=""', 'id="surgesText" visibility="Black"')
        end
        if options.hideBar == true then
            newScript = newScript:gsub('id="staminaProgress" visibility=""', 'id="staminaProgress" visibility="Black"')
            newScript = newScript:gsub('id="recoveriesProgress" visibility=""', 'id="recoveriesProgress" visibility="Black"')
        end
        if options.editText == true then
            newScript = newScript:gsub('id="addStaminaSub" visibility=""', 'id="addStaminaSub" visibility="Black"')
            newScript = newScript:gsub('id="addTempStaminaSub" visibility=""', 'id="addTempStaminaSub" visibility="Black"')
            newScript = newScript:gsub('id="addRecoveriesSub" visibility=""', 'id="addRecoveriesSub" visibility="Black"')
            newScript = newScript:gsub('id="editPanel" visibility=""', 'id="editPanel" visibility="Black"')
        end
    end
    newScript = newScript:gsub('<Panel id="panel" position="0 0 -220"', '<Panel id="panel" position="0 0 ' .. object.getBounds().size.y / object.getScale().y * 110 .. '"')
    object.setLuaScript(newScript)
    object.reload()
end

function getOneWorldHub()
    for _, obj in ipairs(getAllObjects()) do
        if obj ~= self and obj ~= nil and obj.getName() == "OW_Hub" then
            return obj
        end
    end
    return nil
end

function getOneWorldMap()
    for _, obj in ipairs(getAllObjects()) do
        if obj ~= self and obj ~= nil and obj.getName() == "_OW_vBase" then
            return obj
        end
    end
    return nil
end

function getMapBounds(debug)
    local defaultBounds = {x = 88.07, y = 1, z = 52.02}
    local oneWorldMap = getOneWorldMap()
    if oneWorldMap ~= nil then
        local oneWorldBounds = oneWorldMap.getBounds();
        if oneWorldBounds.size.x > 10 then
            if debuggingEnabled then
                print("Using OneWorld map bounds.")
            end
            return oneWorldBounds.size
        end
        if debug or debuggingEnabled then
            print("A OneWorld map is not deployed! Using default bounds.")
        end
        return defaultBounds
    end
    if debug or debuggingEnabled then
        print("OneWorld is not available! Using default bounds.")
    end
    return defaultBounds
end

function rebuildUI()

    local xmlUI = self.UI.getXmlTable()
    -- clear out existing figures
    xmlUI[2].children = {}

    local allObjects = getAllObjects()
    local minilist = {
        tag='VerticalLayout',
        attributes={id='scroll', minHeight='100', width='600', inertia=false, scrollSensitivity=4, color='#00000000', visibility='Black', rectAlignment='UpperCenter'},
        children = {
            {tag='VerticalLayout', attributes={childForceExpandHeight=false, contentSizeFitter='vertical', spacing='5', padding='5 5 5 5', visibility='Black', rectAlignment='UpperCenter'}, children={}}
        }
    }

    local creatureCount = 0
    for i, figure in ipairs(initFigures) do
        creatureCount = creatureCount + 1
        local c = figure.colorTint
        local color = '#'..string.format('%02x', math.ceil(c.r * 255))..string.format('%02x', math.ceil(c.g * 255))..string.format('%02x', math.ceil(c.b * 255))

        local colorVar = '#202020'
        if options.initCurrentGUID == figure.guidValue then
            colorVar = '#505050'
        elseif figure.player == true then
            colorVar = '#401010'
        end

        local extraText = ''
        local currentStamina = figure.stamina.value
        local maxStamina = figure.stamina.max
        local perc = (maxStamina == 0) and 0 or (currentStamina * 1.0) / (maxStamina * 1.0)
        if (perc <= 0) then
            extraText = ' (Exhausted)'
        elseif (perc <= 0.25) then
            extraText = ' (Critical)'
        elseif (perc <= 0.5) then
            extraText = ' (Low)'
        elseif (perc < 1.0) then
            extraText = ' (Healthy)'
        else
            extraText = ' (Untouched)'
        end
        extraText = striptags(figure.name)..extraText
        local percMax = tonumber(perc * 100.0)
        local miniui = {
            tag='verticallayout',
            attributes={
                color=colorVar,
                childForceExpandHeight=false,
                padding=5,
                spacing=5,
                flexibleHeight=0
            },
            children={
                {
                    tag='horizontallayout',
                    attributes={
                        preferredHeight = 60,
                        childForceExpandHeight=false,
                        childForceExpandWidth=false,
                        spacing=5
                    },
                    children={
                        {
                            tag='text',
                            attributes={
                                id=figure.guidValue ..'_header_init',
                                alignment='MiddleLeft',
                                preferredHeight=60,
                                fontSize='32',
                                resizeTextForBestFit=true,
                                minWidth='113',
                                text=figure.initText
                            }
                        },
                        {
                            tag='panel',
                            attributes={
                                color=color,
                                preferredWidth = 10,
                                flexibleWidth = 0,
                                preferredHeight=60,
                                minWidth='10'
                            }
                        },
                        {
                            tag='text',
                            attributes={
                                id=figure.guidValue ..'_header_title',
                                alignment='MiddleLeft',
                                preferredHeight=60,
                                fontSize='32',
                                resizeTextForBestFit=true,
                                preferredWidth=10000,
                                text=extraText
                            }
                        },
                    }
                },
                {
                    tag='horizontallayout',
                    attributes={
                        preferredHeight=60,
                        childForceExpandHeight=false,
                        childForceExpandWidth=false,
                        spacing=5
                    },
                    children={
                        {
                            tag='InputField',
                            attributes={
                                id=figure.guidValue ..'_input_change',
                                preferredHeight='60',
                                preferredWidth='130',
                                flexibleWidth=0,
                                fontSize='38',
                                alignment='MiddleCenter',
                                offsetXY='150 0',
                                color='rgb(0.3,0.3,0.3)',
                                textColor='rgb(1,1,1)',
                                characterValidation='Integer',
                                onEndEdit='barChangeDiff',
                                fontStyle='Bold'
                            }
                        },
                        {
                            tag='InputField',
                            attributes={
                                id=figure.guidValue ..'_input_current',
                                preferredHeight='60',
                                preferredWidth='130',
                                flexibleWidth=0,
                                fontSize='38',
                                alignment='MiddleCenter',
                                offsetXY='150 0',
                                text=currentHealth,
                                characterValidation='Integer',
                                onEndEdit='barChangeCurrent',
                                fontStyle='Bold'
                            }
                        },
                        {
                            tag='Button',
                            attributes={
                                id=figure.guidValue ..'_barReduce',
                                preferredWidth='30',
                                preferredHeight='60',
                                flexibleWidth=0,
                                image='ui_arrow_l2',
                                onClick='barReduce'
                            }
                        },
                        {
                            tag='panel',
                            attributes={
                                preferredHeight='60',
                                preferredWidth='300'
                            },
                            children={
                                {
                                    tag='progressbar',
                                    attributes={
                                        id=figure.guidValue ..'_bar',
                                        width='100%',
                                        percentage=percMax,
                                        fillImageColor='#FF0000',
                                        color='#00000080',
                                        textColor='transparent'
                                    }
                                }
                            }
                        },
                        {
                            tag='Button',
                            attributes={
                                id=figure.guidValue ..'_barIncrease',
                                preferredWidth='30',
                                preferredHeight='60',
                                image='ui_arrow_r2',
                                flexibleWidth=0,
                                onClick='barIncrease'
                            }
                        },
                        {
                            tag='InputField',
                            attributes={
                                id=figure.guidValue ..'_input_maximum',
                                preferredHeight='60',
                                preferredWidth='130',
                                fontSize='38',
                                text=maxHealth,
                                characterValidation='Integer',
                                onEndEdit='barChangeMaximum',
                                fontStyle='Bold'
                            }
                        }
                    }
                }
            }
        }

        table.insert(minilist.children[1].children, miniui)
    end

    local calcHeight = 93 * creatureCount
    minilist.attributes.height = calcHeight..''
    minilist.attributes.minHeight = calcHeight..''
    table.insert(xmlUI[2].children, {
        tag='Defaults', children={
            {tag='Text', attributes={color='#cccccc', fontSize='15', alignment='MiddleLeft', visibility='Black'}},
            {tag='InputField', attributes={fontSize='15', preferredHeight='60', visibility='Black'}},
            {tag='ToggleButton', attributes={fontSize='15', preferredHeight='60', colors='#ffcc33|#ffffff|#808080|#606060', selectedBackgroundColor='#dddddd', deselectedBackgroundColor='#999999', visibility='Black'}},
            {tag='Button', attributes={fontSize='15', preferredHeight='60', colors='#dddddd|#ffffff|#808080|#606060', visibility='Black'}},
            {tag='Toggle', attributes={textColor='#cccccc', visibility='Black'}},
        }
    })
    table.insert(xmlUI[2].children, {tag='Panel', attributes={ height=calcHeight..'', width='790', rectAlignment='UpperCenter'},
        children={
            {tag='VerticalLayout', attributes={childForceExpandHeight=false, minHeight='0', spacing=10, rectAlignment='UpperCenter'}, children={
                {tag='HorizontalLayout', attributes={preferredHeight=80, childForceExpandWidth=false, flexibleHeight=0, spacing=20, padding='10 10 10 10'}, children={}},
                minilist
            }}
        }
    })
    self.UI.setXmlTable(xmlUI)
end

function updateFromGuid(guid)
    local token = getObjectFromGUID(guid)
    if (token ~= nil) then
        local extraText = ''
        local staminaTable = token.getTable("stamina")
        local currentStamina = staminaTable.value
        local maxStamina = staminaTable.max
        local perc = (maxStamina == 0) and 0 or (currentStamina * 1.0) / (maxStamina * 1.0)
        if (perc <= 0) then
            extraText = ' (Exhausted)'
        elseif (perc <= 0.25) then
            extraText = ' (Critical)'
        elseif (perc <= 0.5) then
            extraText = ' (Low)'
        elseif (perc < 1.0) then
            extraText = ' (Healthy)'
        else
            extraText = ' (Full)'
        end
        local percMax = tonumber(perc * 100.0)
        self.UI.setAttribute(guid..'_header_title', 'text', striptags(token.getName())..extraText)
        self.UI.setAttribute(guid..'_input_current', 'text', currentStamina)
        self.UI.setAttribute(guid..'_bar', 'percentage', percMax)
        self.UI.setAttribute(guid..'_input_maximum', 'text', maxStamina)
    end
end

function barChangeDiff(player, value, id)
    if value == "" then
        return
    end
    local args = {}
    for a in string.gmatch(id, '([^%_]+)') do
        table.insert(args,a)
    end
    local guid = args[1]
    local token = getObjectFromGUID(guid)
    if (token ~= nil) then
        token.call('adjustStamina', value)
    end
    self.UI.setAttribute(id, 'text', '')
end

function barChangeCurrent(player, value, id)
    if value == "" then
        return
    end
    local args = {}
    for a in string.gmatch(id, '([^%_]+)') do
        table.insert(args,a)
    end
    local guid = args[1]
    local token = getObjectFromGUID(guid)
    if (token ~= nil) then
        token.call('setStamina', value)
    end
end

function barChangeMaximum(player, value, id)
    if value == "" then
        return
    end
    local args = {}
    for a in string.gmatch(id, '([^%_]+)') do
        table.insert(args,a)
    end
    local guid = args[1]
    local token = getObjectFromGUID(guid)
    if (token ~= nil) then
        token.call('setStaminaMax', value)
    end
end

function barReduce(player, value, id)
    local guid = id:sub(1, -11)
    local token = getObjectFromGUID(guid)
    if token ~= nil then
        if value == "-1" then
            token.call('reduceStamina')
        else
            token.call('adjustStamina', -10)
        end
    end
end

function barIncrease(player, value, id)
    local guid = id:sub(1, -13)
    local token = getObjectFromGUID(guid)
    if token ~= nil then
        if value == "-1" then
            token.call('increaseStamina')
        else
            token.call('adjustStamina', 10)
        end
    end
end

function sanitize(str)
    return str:gsub('[<>]', '')
end

function striptags(str)
    str = sanitize(str)
    str = str:gsub('%[/?[iI]%]', '')
    str = str:gsub('%[/?[bB]%]', '')
    str = str:gsub('%[/?[uU]%]', '')
    str = str:gsub('%[/?[sS]%]', '')
    str = str:gsub('%[/?[sS][uU][bB]%]', '')
    str = str:gsub('%[/?[sS][uU][pP]%]', '')
    str = str:gsub('%[/?[sS][uU][pP]%]', '')
    str = str:gsub('%[/?%-%]', '')
    str = str:gsub('%[/?[a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9]%]', '')
    return str
end

--Converts a color tint to a hex code
function tintToHex(objColor)
    hexColor = ''
    for i=1,3 do
        hex = ''
        dec = objColor[i] * 255
        hex = string.format( "%2.2X",math.floor(dec+0.5))
        hexColor = hexColor..hex
    end
    return hexColor
end

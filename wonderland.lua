Config = {
    Map = "aduermael.hills",
    Items = {"michak.grid", "michak.cube_white", "michak.cube_red", "michak.glow", "michak.go", "michak.waiting",
             "aduermael.booni", "aduermael.selector", "aduermael.selector_disabled", "theosaurus.booni"}
}

-- ******************************* SETTINGS ***********************************

settings = {
    debug = {
        logEnabled = true,
        controls = true,
        showColliders = false
    },
    camera = {
        altitude = 5,
        minSpeed = 60.0,
        lock = false
    },
    player = {
        hidden = true,
        physics = false
    },
    multi = {
        maxPlayers = 16
    },
    map = {
        timeCycle = false
    },
    score = {
        glow = 10,
        scaleFactor = 0.01
    }
}

-- ******************************* STATE **************************************

state = {
    coll = {
        hitBlockCoords = nil,
        hitBlockFace = nil
    },
    player = {
        yaw = 0,
        pitch = 0
    }
}

-- ******************************* ENUMS **************************************

CameraMode {
    FitToScreen = 1,
    Top
}

-- ******************************* HOOKS **************************************

Client.OnStart = function()
    initialize(CameraMode.FitToScreen)
    boonies = {}
    cpuBoonies = {}
    glows = newGlows(200, 2.0)
    ui = newUI()
    newCPUBoonies(15)
end

Client.Tick = function(dt)
    checkForPlayers(dt)
    updateUI(dt)
    for name, booni in pairs(boonies) do
        updateBooni(booni, name, dt)
    end
    for index, booni in ipairs(cpuBoonies) do
        updateBooniAI(booni, index, dt)
        updateBooni(booni, index, dt)
    end
    updateCamera(dt)
end

-- ****************************** CAMERA **************************************

function updateCameraFitToScreen(dt)
    if playerBooni == nil then
        logError("No camera target for FitToScreen camera mode")
        return
    end
    Camera:SetModeFree()
    Camera.Rotation = {state.player.pitch, state.player.yaw, 0}
    Camera:FitToScreen(playerBooni.shape, 1.0, true)
end

function updateCameraThirdPerson(dt)
    Camera.SetModeThirdPerson()
    Camera.Rotation = {state.player.pitch, state.player.yaw, 0}
end

-- ******************************* INIT ***************************************

function initialize(cameraMode)
    switch(cameraMode, {
        [1] = function()
            log("CameraMode: FitToScreen")
            updateCamera = updateCameraFitToScreen
        end,
        [2] = function()
            log("CameraMode: Top")
            updateCamera = updateCameraThirdPerson
        end,
        [3] = function()
            log("CameraMode: 3rd Person")
            updateCamera = updateCameraThirdPerson
        end
    })

    TimeCycle.On = settings.map.timeCycle
    Dev.DisplayColliders = settings.debug.showColliders
    Player.Physics = settings.player.physics
    Player.IsHidden = settings.player.hidden
    World:AddChild(Shape(Items.michak.grid))
    World:AddChild(Player)
end

-- ******************************* COLLISIONS *********************************

function booniCollidedWithGlow(booni, glow)
    if booni ~= nil then
        -- dump(booni)
        booni.score = booni.score + settings.score.glow
    else
        logError("No booni")
    end
    glow.Position = randomPosition()

end

-- ******************************* BOONI **************************************

function newBooni(player)
    local booni = {}
    booni.ai = {
        idleTime = 5
    }
    booni.score = 0
    booni.shape = Shape(Items.theosaurus.booni)
    booni.shape.Pivot.Y = 0
    booni.pos = Number3(362.5, 292.5 + settings.camera.altitude * Map.Scale.Y, 157.5)
    booni.target = booni.pos

    booni.anim = {}
    booni.anim.move = Number3(0, 0, 0)
    booni.anim.scale = Number3(0, 0, 0)

    booni.shape.Scale = 0.4
    World:AddChild(booni.shape)
    booni.shape.Position = booni.pos
    booni.Physics = true

    booni.CollisionGroups = CollisionGroups(2)
    booni.CollidesWithGroups = Map.CollisionGroups + CollisionGroups(3)

    booni.shape.booni = booni
    booni.shape.OnCollision = function(o1, o2)
        booniCollidedWithGlow(o1.booni, o2)
    end

    booni.OnCollision = function(o1, o2)
        log("shape col: ", o1, o2)
        dump(o1)
        dump(o2)
        o2.Position = randomPosition()
    end

    if player == "cpu" then
        booni.type = "cpu"
        booni.key = #cpuBoonies + 1
        cpuBoonies[booni.key] = booni
        booni.username = "cpu #" .. #cpuBoonies
        log(booni.username .. " has entered the tag")
    else
        booni.type = "player"
        booni.key = player.ID
        boonies[player.ID] = booni
        booni.username = player.Username
    end

    booni.chatBubbleRemainingTime = 0.0
    booni.shape:TextBubble(booni.username, 86400, Color(255, 255, 255, 150), Color(255, 255, 255, 0), false)

    if player == Player then
        Player.Position = booni.pos
        Player.IsHidden = settings.player.hidden
    end
    return booni
end

function newCPUBoonies(count)
    for i = 1, count do
        local booni = newBooni("cpu")
        -- booni.pos = randomPosition()
        booni.pos = Number3(362.5, i * 10.0 + 292.5 + settings.camera.altitude * Map.Scale.Y, 157.5)
        booni.target = randomPosition()
        cpuBoonies[i] = booni
    end
end

function destroyBooni(playerID)

    local booni = boonies[playerID]

    booni.shape:ClearTextBubble()
    booni.shape:RemoveFromParent()
    booni.shape = nil

    boonies[playerID] = nil
end

updateBooni = function(booni, name, dt)
    if booni ~= nil then
        booni.anim.move.Y = booni.anim.move.Y + dt
        booni.anim.scale.X = booni.anim.scale.X + dt * 5.0
        booni.anim.scale.Y = booni.anim.scale.Y + dt * 5.5

        booni.pos = booni.pos + (booni.target - booni.pos) * 2.0 * dt

        booni.shape.Position = booni.pos + {0, math.sin(booni.anim.move.Y), 0}
        booni.shape.Scale.X = 0.4 + booni.score * settings.score.scaleFactor + math.sin(booni.anim.scale.X) * 0.03
        booni.shape.Scale.Y = 0.4 + booni.score * settings.score.scaleFactor + math.sin(booni.anim.scale.Y) * 0.03
        booni.shape.Scale.Z = 0.4 + booni.score * settings.score.scaleFactor

        if booni.chatBubbleRemainingTime > 0.0 then
            booni.chatBubbleRemainingTime = booni.chatBubbleRemainingTime - dt
            if booni.chatBubbleRemainingTime <= 0.0 then

                booni.shape:ClearTextBubble()
                booni.shape:TextBubble(booni.username, 86400, Color(255, 255, 255, 150), Color(255, 255, 255, 0), false)
            end
        end

        -- if settings.camera.lock == false then
        if name == Player.ID then
            Player.Position = booni.pos
            -- local distance = booni.target - {0, 2, 0} - Player.Position
            -- if distance.Length > 0.1 then

            --     local speed = ((booni.target - booni.pos) * 2.0).Length
            --     if speed < settings.camera.minSpeed then
            --         speed = settings.camera.minSpeed
            --     end

            --     if speed * dt > distance.Length then
            --         speed = distance.Length / dt
            --     end

            --     distance:Normalize()
            --     Player.Position = Player.Position + distance * speed * dt
            -- end
            -- end
        end
    end
end

function updateBooniAI(booni, index, dt)
    if booni.ai.idleTime < 0 then
        local targetGlowIndex = math.random(1, #glows)
        booni.target = glows[targetGlowIndex].Position
        booni.ai.idleTime = 5
    end
    booni.ai.idleTime = booni.ai.idleTime - dt
end

-- ******************************* GLOW **************************************

function newGlows(count, size)
    glows = {}
    for i = 1, count, 1 do
        -- local cube = Shape(Items.michak.cube_white)
        local glow = Shape(Items.michak.glow)
        glow.Physics = true
        glow.OnCollision = function(o1, o2)
            -- log("glow col")
        end
        glow.key = i
        glow.Scale = size
        glow.CollisionGroups = CollisionGroups(3)
        glow.CollidesWithGroups = Map.CollisionGroups + CollisionGroups(2)
        glow.Position = randomPosition()
        World:AddChild(glow)
        -- cube.Scale = size
        -- cube.CollisionGroups = CollisionGroups(3)
        -- cube.CollidesWithGroups = Map.CollisionGroups + CollisionGroups(2)
        -- cube.Mass = 1
        -- Map:AddChild(cube)
        glows[i] = glow
    end
    return glows
end

checkForPlayers = function(dt)
    if #boonies < 2 and dt % 50000 == 0 then
        -- log("players count " .. #boonies)
        -- log("waiting for players")

    else
    end
end

-- ******************************** INPUT *************************************

Pointer.Down = function(e)

    settings.camera.lock = true

    local impact = e:CastRay(Map.CollisionGroups)
    if impact.Block ~= nil then
        updateSelectorShape(impact)
    end
end

Pointer.Drag = function(e)

    state.player.yaw = state.player.yaw + e.DX * 0.01
    state.player.pitch = state.player.pitch - e.DY * 0.01
    Player.Rotation = {state.player.pitch, state.player.yaw, 0}
    playerBooni.shape.Rotation = {state.player.pitch, state.player.yaw, 0}

    local impact = e:CastRay(Map.CollisionGroups)
    if impact.Block ~= nil then
        updateSelectorShape(impact)
        if state.coll.hitBlockCoords == impact.Block.Coords and state.coll.hitBlockFace == impact.FaceTouched then
            selectorShape.IsHidden = false
            selectorShapeDisabled.IsHidden = true
        else
            selectorShape.IsHidden = true
            selectorShapeDisabled.IsHidden = false
        end
    end
end

Pointer.Up = function(e)

    settings.camera.lock = false
    selectorShape.IsHidden = true
    selectorShapeDisabled.IsHidden = true

    if boonies[Player.ID] == nil then
        return
    end

    local impact = e:CastRay(Map.CollisionGroups)
    if impact.Block ~= nil then
        if impact.Block.Coords == state.coll.hitBlockCoords and impact.FaceTouched == state.coll.hitBlockFace then

            local coords = state.coll.hitBlockCoords
            if state.coll.hitBlockFace == BlockFace.Top then
                coords = coords + {0.5, 1.5, 0.5}
            elseif state.coll.hitBlockFace == BlockFace.Bottom then
                coords = coords + {0.5, -0.5, 0.5}
            elseif state.coll.hitBlockFace == BlockFace.Left then
                coords = coords + {-0.5, 0.5, 0.5}
            elseif state.coll.hitBlockFace == BlockFace.Right then
                coords = coords + {1.5, 0.5, 0.5}
            elseif state.coll.hitBlockFace == BlockFace.Front then
                coords = coords + {0.5, 0.5, -0.5}
            elseif state.coll.hitBlockFace == BlockFace.Back then
                coords = coords + {0.5, 0.5, 1.5}
            end

            target = Map:BlockToWorld(coords)
            -- log("new target:", target)

            local e = Event()
            e.action = "move"
            e.targetX = target.X
            e.targetY = target.Y
            e.targetZ = target.Z
            -- e:SendTo(OtherPlayers)
            e:SendTo(Players)
        end
    end
end

-- ******************************* NETWORK ************************************

Client.OnChat = function(msg)
    local e = Event()
    e.action = "chat"
    e.msg = msg
    e:SendTo(Players)
end

Client.OnPlayerJoin = function(player)
    log(player.Username .. "! Run for your life!")
    local booni = newBooni(player)
    if playerBooni == nil then
        playerBooni = booni
        playerBooni.score = 0
    end
end

Client.OnPlayerLeave = function(player)
    -- BUG: player is already gone when this function
    -- is called. So we can't access its ID. 
    -- But there's a workaround, we can loop over Players for each booni
    -- to see the one who's gone.
    local toDestroy = {}

    for playerID, booni in pairs(boonies) do
        if Players[playerID] == nil or Players[playerID].ID == nil or Players[playerID].Username == nil then
            toDestroy[playerID] = booni
        end
    end

    for playerID, booni in pairs(toDestroy) do
        log("Player left:", booni.username)
        destroyBooni(playerID)
    end
end

Client.DidReceiveEvent = function(e)

    if e.action == "move" then

        local booni = boonies[e.Sender.ID]
        if booni == nil then
            return
        end
        -- log("look forward")
        -- booni.shape.Rotation = {0, math.pi, 0}
        -- booni.shape.Forward = Camera.Backward
        booni.target = Number3(e.targetX, e.targetY, e.targetZ)
    elseif e.action == "chat" then

        local booni = boonies[e.Sender.ID]
        if booni == nil then
            return
        end

        booni.chatBubbleRemainingTime = 5.0

        booni.shape:ClearTextBubble()
        booni.shape:TextBubble(e.msg, 86400, Color(0, 0, 0, 255), Color(255, 255, 255, 255), true)

        log(e.Sender.Username .. ": " .. e.msg)
    end
end

-- ******************************* UI *****************************************

function newUI()
    local cameraDistance = 10
    local ui = {}
    ui.waiting = Shape(Items.michak.waiting)
    ui.go = Shape(Items.michak.go)
    Camera:AddChild(ui.waiting)
    -- Camera:AddChild(ui.go)
    ui.waiting.LocalPosition = -Camera.Forward * cameraDistance
    -- ui.go.LocalPosition = -Camera.Forward * cameraDistance
    log(ui.waiting)
    log(ui.waiting:GetParent())
    selector = Object()
    selectorShape = Shape(Items.aduermael.selector)
    selectorShape.Scale = 0.5
    selectorShape.Pivot.Y = 0
    selector:AddChild(selectorShape)
    selectorShape.IsHidden = true
    selectorShapeDisabled = Shape(Items.aduermael.selector_disabled)
    selectorShapeDisabled.Scale = 0.5
    selectorShapeDisabled.Pivot.Y = 0
    selector:AddChild(selectorShapeDisabled)
    selectorShapeDisabled.IsHidden = true
    World:AddChild(selector)
    Pointer:Show()
    UI.Crosshair = false

    newPlayersList()
    if settings.debug.controls then
        newControlButtons()
    end
    return ui
end

function newControlButtons()
    cameraButton = Button("Camera", Anchor.Left, Anchor.Top)
    cameraButton.OnPress = function()
        log("camera pressed")
    end
    growButton = Button("Grow", Anchor.Left, Anchor.Top)
    growButton.OnPress = function()
        booniCollidedWithGlow(booni)
    end
end

function newPlayersList()
    playersListLabels = {}
    for i = 1, 16 do
        playersListLabels[i] = Label("?????????", Anchor.Right, Anchor.Top)
    end
end

function updatePlayersList()
    allBoonies = {}
    booniesCount = 0
    for name, booni in pairs(boonies) do
        allBoonies[booniesCount + 1] = {}
        allBoonies[booniesCount + 1].name = booni.username
        allBoonies[booniesCount + 1].score = booni.score
        if name == Player.ID then
            allBoonies[booniesCount + 1].color = Color(255, 0, 0)
        else
            allBoonies[booniesCount + 1].color = Color(255, 255, 255)
        end
        booniesCount = booniesCount + 1

    end
    for index, booni in ipairs(cpuBoonies) do
        allBoonies[booniesCount + 1] = {}
        allBoonies[booniesCount + 1].name = booni.username
        allBoonies[booniesCount + 1].score = booni.score
        allBoonies[booniesCount + 1].color = Color(192, 192, 192)
        booniesCount = booniesCount + 1
    end

    function compare(a, b)
        return a.score > b.score
    end
    table.sort(allBoonies, compare)
    for i = 1, #allBoonies do
        playersListLabels[i].Text = string.format("%-10s%-s%7d", allBoonies[i].name, "|", allBoonies[i].score)
        playersListLabels[i].TextColor = allBoonies[i].color
    end
end

function updateUI(dt)
    updatePlayersList(dt)
end

function updateSelectorShape(impact)
    selectorShape.IsHidden = false

    state.coll.hitBlockCoords = impact.Block.Coords
    state.coll.hitBlockFace = impact.FaceTouched

    local coords = state.coll.hitBlockCoords
    if state.coll.hitBlockFace == BlockFace.Top then
        coords = coords + {0.5, 1.0, 0.5}
        selectorShape.Rotation = {0, 0, 0}
    elseif state.coll.hitBlockFace == BlockFace.Bottom then
        coords = coords + {0.5, 0.0, 0.5}
        selectorShape.Rotation = {math.pi, 0, 0}
    elseif state.coll.hitBlockFace == BlockFace.Left then
        coords = coords + {0, 0.5, 0.5}
        selectorShape.Rotation = {0, 0, math.pi * 0.5}
    elseif state.coll.hitBlockFace == BlockFace.Right then
        coords = coords + {1.0, 0.5, 0.5}
        selectorShape.Rotation = {0, 0, math.pi * -0.5}
    elseif state.coll.hitBlockFace == BlockFace.Front then
        coords = coords + {0.5, 0.5, 0.0}
        selectorShape.Rotation = {math.pi * -0.5, 0, 0}
    elseif state.coll.hitBlockFace == BlockFace.Back then
        coords = coords + {0.5, 0.5, 1.0}
        selectorShape.Rotation = {math.pi * 0.5, 0, 0}
    end

    selector.Position = Map:BlockToWorld(coords)
end

-- ***************************************** UTILS ****************************

function dump(obj)
    log("[" .. tostring(obj) .. "]")
    for key, value in pairs(obj) do
        log("  " .. key .. ": ", value)
    end
end

function log(...)
    if settings.debug.logEnabled then
        print(...)
    end
end

function logError(...)
    log("Error: ", ...)
end

function arrayConcat(...)
    local t = {}
    for n = 1, select("#", ...) do
        local arg = select(n, ...)
        if type(arg) == "table" then
            for _, v in ipairs(arg) do
                t[#t + 1] = v
            end
        else
            t[#t + 1] = arg
        end
    end
    return t
end

switch = function(param, case_table)
    local case = case_table[param]
    if case then
        return case()
    end
    local def = case_table['default']
    return def and def() or nil
end

-- ******************************** 3D TOOLS **********************************

function randomPosition()
    return Number3(math.random(0, Map.Width), Map.Height + settings.camera.altitude, math.random(0, Map.Depth)) *
               Map.Scale
end

function mapCenter()
    return Number3(Map.Width * 0.5, Map.Height + 10, Map.Depth * 0.5) * Map.Scale
end


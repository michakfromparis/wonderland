Config = {
    Map = "aduermael.hills",
    Items = {"michak.cube_white", "michak.cube_red", "michak.glow", "michak.go", "michak.waiting", "aduermael.booni",
             "aduermael.selector", "aduermael.selector_disabled", "theosaurus.booni"}
}

-- ******************************* SETTINGS ***********************************

settings = {
    debug = {
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

-- ******************************* HOOKS **************************************

Client.OnStart = function()

    TimeCycle.On = settings.map.timeCycle
    Dev.DisplayColliders = settings.debug.showColliders
    glowCollisionGroup = CollisionGroups(3)
    Player.Physics = settings.player.physics
    Player.IsHidden = settings.player.hidden
    World:AddChild(Player)
    boonies = {}
    cpuBoonies = {}
    glows = newGlows(200, 0.42)
    ui = newUI()
    newCPUBoonies(10)
end

Client.Tick = function(dt)
    checkForPlayers(dt)
    updatePlayersList()
    for name, booni in pairs(boonies) do
        updateBooni(booni, name, dt)
    end
    for name, booni in pairs(cpuBoonies) do
        updateBooni(booni, name, dt)
    end
    -- Camera.SetModeThirdPerson()
    if playerBooni ~= mil then
        Camera:FitToScreen(playerBooni.shape, 0.1, true)
        Camera.DistanceFromTarget = 10
    end
end

-- ******************************* PLAYER **************************************

function newPlayer()
    print("new Player")
    glowCollisionGroup = CollisionGroups(3)
    Player.Physics = settings.player.physics
    Player.IsHidden = settings.player.hidden
    -- Player.CollidesWithMask = 0
    -- Player.CollisionGroupsMask = 0
    Player.CollidesWithGroups = Map.CollisionGroups + Player.CollisionGroups + glowCollisionGroup
    World:AddChild(Player)
end

-- ******************************* BOONI **************************************

function newBooni(player)
    print("new Booni")
    local booni = {}
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
        if o1.booni ~= nil then
            print("booni", o1.booni)
            dump(o1.booni)
            o1.booni.score = o1.booni.score + settings.score.glow
            print("booni score: ", o1.booni.score)
        else
            print("Error: No booni")
        end
        o2.Position = randomPosition()
    end

    booni.OnCollision = function(o1, o2)
        print("shape col: ", o1, o2)
        dump(o1)
        dump(o2)
        o2.Position = randomPosition()
    end

    if player == "cpu" then
        booni.type = "cpu"
        booni.key = #cpuBoonies + 1
        cpuBoonies[booni.key] = booni
        booni.username = "cpu #" .. #cpuBoonies
        print(booni.username .. " has entered the tag")
    else
        booni.type = "player"
        booni.key = player.ID
        boonies[player.ID] = booni
        booni.username = player.Username
    end

    booni.chatBubbleRemainingTime = 0.0
    booni.shape:TextBubble(booni.username, 86400, Color(255, 255, 255, 150), Color(255, 255, 255, 0), false)

    if player == Player then
        Player.Position = booni.pos - {0, 2, 0}
        Player.IsHidden = settings.player.hidden
    end
    return booni
end

function newCPUBoonies(count)
    for i = 1, count do
        local booni = newBooni("cpu")
        rx = math.random(0, Map.Width)
        ry = Map.Height
        rz = math.random(0, Map.Depth)
        booni.pos = Number3(rx, ry, rz)
        rx = math.random(0, Map.Width)
        ry = Map.Height
        rz = math.random(0, Map.Depth)
        booni.target = Number3(rx, ry, rz)
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

        if settings.camera.lock == false then
            if name == Player.ID then
                local distance = booni.target - {0, 2, 0} - Player.Position
                if distance.Length > 0.1 then

                    local speed = ((booni.target - booni.pos) * 2.0).Length
                    if speed < settings.camera.minSpeed then
                        speed = settings.camera.minSpeed
                    end

                    if speed * dt > distance.Length then
                        speed = distance.Length / dt
                    end

                    distance:Normalize()
                    Player.Position = Player.Position + distance * speed * dt
                end
            end
        end
    end
end

-- ******************************* Glow **************************************

function newGlows(count, size)
    glows = {}
    for i = 1, count, 1 do
        -- local cube = Shape(Items.michak.cube_white)
        local glow = Shape(Items.michak.glow)
        glow.Physics = true
        glow.OnCollision = function(o1, o2)
            -- print("glow col")
        end
        glow.key = i
        glow.Scale = size * 1.7
        glow.CollisionGroups = CollisionGroups(3)
        glow.CollidesWithGroups = Map.CollisionGroups + CollisionGroups(2)
        glow.Position = randomPosition()
        Map:AddChild(glow)
        -- cube.Scale = size
        -- cube.CollisionGroups = CollisionGroups(3)
        -- cube.CollidesWithGroups = Map.CollisionGroups + CollisionGroups(2)
        -- cube.Mass = 1
        -- Map:AddChild(cube)
        glows[i] = glow
    end
    return glows
end

function newPlayersList()
    playersListLabels = {}
    for i = 1, 10 do
        playersListLabels[i] = Label("❤❤❤", Anchor.Right, Anchor.Top)
    end
end

function updatePlayersList()
    for i = 1, 10 do
        playersListLabels[i].Text = "Player " .. i
    end
end

checkForPlayers = function(dt)
    if #boonies < 2 and dt % 50000 == 0 then
        -- print("players count " .. #boonies)
        -- print("waiting for players")

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
            -- print("new target:", target)

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
    print(player.Username .. "! Run for your life!")
    local booni = newBooni(player)
    if playerBooni == nil then
        playerBooni = booni
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
        print("Player left:", booni.username)
        destroyBooni(playerID)
    end
end

Client.DidReceiveEvent = function(e)

    if e.action == "move" then

        local booni = boonies[e.Sender.ID]
        if booni == nil then
            return
        end
        -- print("look forward")
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

        print(e.Sender.Username .. ": " .. e.msg)
    end
end

-- ***************************************** UTILS ****************************

dump = function(obj)
    print("[" .. tostring(obj) .. "]")
    for key, value in pairs(obj) do
        print("  " .. key .. ": ", value)
    end
end

function randomPosition()
    return Number3(math.random(0, Map.Width), math.random(0, Map.Height), math.random(0, Map.Depth))
end

-- ******************************* UI *****************************************

function newUI()
    local cameraDistance = 100
    local ui = {}
    ui.waiting = Shape(Items.michak.waiting)
    ui.go = Shape(Items.michak.go)
    ui.waiting.Position = Camera.Position - Camera.Forward * cameraDistance
    ui.go.Position = Camera.Position - Camera.Forward * cameraDistance
    Camera:AddChild(ui.waiting)
    Camera:AddChild(ui.go)

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
    return ui
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

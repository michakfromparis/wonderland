Config = {
    Map = "aduermael.hills",
    Items = {"michak.cube_white", "michak.cube_red", "michak.glow", "michak.go", "michak.waiting", "aduermael.booni",
             "aduermael.selector", "aduermael.selector_disabled", "theosaurus.booni"}
}

settings = {
    debug = {
        showColliders = true
    },
    camera = {
        altitude = 5,
        minSpeed = 60.0
    },
    map = {
        timeCycle = false
    }
}

Client.OnStart = function()

    TimeCycle.On = settings.map.timeCycle
    Dev.DisplayColliders = true

    glowCollisionGroup = CollisionGroups(3)
    Player.CollidesWithGroups = Map.CollisionGroups + Player.CollisionGroups + glowCollisionGroup
    Player.OnCollision = function(o1, o2)
        print("player col: ", o1, o2)
        dump(o1)
        dump(o2)
    end

    boonies = {}
    cpuBoonies = {}
    glows = newGlows(200, 0.42)
    ui = newUI()

    function newBooni(player)

        local booni = {}

        booni.total1 = 0.0
        booni.total2 = 0.0
        booni.total3 = 0.0

        booni.pos = Number3(362.5, 292.5 + settings.camera.altitude * Map.Scale.Y, 157.5)
        booni.target = booni.pos
        booni.upDownDelta = 0.0

        booni.shape = Shape(Items.theosaurus.booni)
        booni.shape.Pivot.Y = 0
        booni.shape.Scale = 0.4
        World:AddChild(booni.shape)
        booni.shape.Position = booni.pos
        booni.Physics = true

        booni.CollisionGroups = Player.CollisionGroups

        booni.shape.OnCollision = function(o1, o2)
            print("shape col: ", o1, o2)
            dump(o1)
            dump(o2)
        end

        if player == "cpu" then
            cpuBoonies[#cpuBoonies + 1] = booni
            booni.username = "cpu #" .. #cpuBoonies
            print(booni.username .. " has entered the tag")
        else
            boonies[player.ID] = booni
            booni.username = player.Username
        end

        booni.chatBubbleRemainingTime = 0.0
        booni.shape:TextBubble(booni.username, 86400, Color(255, 255, 255, 150), Color(255, 255, 255, 0), false)

        if player == Player then
            Player.Position = booni.pos - {0, 2, 0}
            Player.IsHidden = true
        end
        return booni
    end

    function destroyBooni(playerID)

        local booni = boonies[playerID]

        booni.shape:ClearTextBubble()
        booni.shape:RemoveFromParent()
        booni.shape = nil

        boonies[playerID] = nil
    end

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

    -- Using the Player object as a little trick 
    -- to use the third person camera. 
    -- It's still not possible to assign it to other objects...
    -- An hidden player with a position that follows the one of the 
    -- object allows to use the third person camera anyway. :p
    Player.Physics = false
    Player.IsHidden = true
    -- Player.CollidesWithMask = 0
    -- Player.CollisionGroupsMask = 0
    World:AddChild(Player)

    yaw = 0
    pitch = 0

    hitBlockCoords = nil
    hitBlockFace = nil

    lockCamera = false

    newCPUBoonies(10)
end

newCPUBoonies = function(count)
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

newGlows = function(count, size)
    glows = {}
    for i = 1, count, 1 do
        local cube = Shape(Items.michak.cube_red)
        local glow = Shape(Items.michak.glow)
        cube.OnCollision = function(o1, o2)
            -- print("cube collision detected between", o1, "and", o2)
        end
        glow.OnCollision = function(o1, o2)
            -- o2:TextBubble("+1", 86400, Color(255, 255, 255, 150), Color(255, 255, 255, 0), false)
            -- print("glow collision detected between", o1, "and", o2)
            -- print("glow " .. o1)
            -- print("other " .. o2)

        end

        glow.scale = size / 4
        glow.Physics = true
        glow.CollisionGroups = CollisionGroups(3)
        glow.CollidesWithGroups = Player.CollisionGroups + Map.CollisionGroups
        rx = math.random(0, Map.Width)
        ry = math.random(0, Map.Height)
        rz = math.random(0, Map.Depth)
        glow.Position = {rx, ry, rz}
        cube.Position = {rx, ry, rz}
        cube:AddChild(glow)
        cube.Scale = size
        cube.Physics = true
        cube.CollisionGroups = CollisionGroups(3)
        cube.CollidesWithGroups = Player.CollisionGroups + Map.CollisionGroups
        cube.Mass = 1
        Map:AddChild(cube)
        glows[i] = glow
    end
    return glows
end

newUI = function()
    local cameraDistance = 100
    local ui = {}
    ui.waiting = Shape(Items.michak.waiting)
    ui.go = Shape(Items.michak.go)
    ui.waiting.Position = Camera.Position - Camera.Forward * cameraDistance
    ui.go.Position = Camera.Position - Camera.Forward * cameraDistance * 100
    Camera:AddChild(ui.waiting)
    Camera:AddChild(ui.go)
    return ui
end

function updateSelectorShape(impact)
    selectorShape.IsHidden = false

    hitBlockCoords = impact.Block.Coords
    hitBlockFace = impact.FaceTouched

    local coords = hitBlockCoords
    if hitBlockFace == BlockFace.Top then
        coords = coords + {0.5, 1.0, 0.5}
        selectorShape.Rotation = {0, 0, 0}
    elseif hitBlockFace == BlockFace.Bottom then
        coords = coords + {0.5, 0.0, 0.5}
        selectorShape.Rotation = {math.pi, 0, 0}
    elseif hitBlockFace == BlockFace.Left then
        coords = coords + {0, 0.5, 0.5}
        selectorShape.Rotation = {0, 0, math.pi * 0.5}
    elseif hitBlockFace == BlockFace.Right then
        coords = coords + {1.0, 0.5, 0.5}
        selectorShape.Rotation = {0, 0, math.pi * -0.5}
    elseif hitBlockFace == BlockFace.Front then
        coords = coords + {0.5, 0.5, 0.0}
        selectorShape.Rotation = {math.pi * -0.5, 0, 0}
    elseif hitBlockFace == BlockFace.Back then
        coords = coords + {0.5, 0.5, 1.0}
        selectorShape.Rotation = {math.pi * 0.5, 0, 0}
    end

    selector.Position = Map:BlockToWorld(coords)
end

randomizeCat = function()
    for k, booni in pairs(boonies) do
        booni.isCat = false
    end
    booniIndex = math.random(1, number(#boonies))
    -- print("setting player " .. booniIndex .. " of " .. #boonies .. " player")
    if boonies[booniIndex] ~= nil then
        boonies[booniIndex].isCat = true
    end
    -- print(booni.player.username " is Cat!")
    return booniIndex
end

checkForPlayers = function(dt)
    if #boonies < 2 and dt % 50000 == 0 then
        -- print("players count " .. #boonies)
        -- print("waiting for players")

    else
        randomizeCat(boonies)
    end
end

updateBoony = function(booni, name, dt)
    if booni ~= nil then

        booni.total1 = booni.total1 + dt
        booni.total2 = booni.total2 + dt * 5.0
        booni.total3 = booni.total3 + dt * 5.5

        booni.pos = booni.pos + (booni.target - booni.pos) * 2.0 * dt
        booni.upDownDelta = math.sin(booni.total1)

        booni.shape.Position = booni.pos + {0, booni.upDownDelta, 0}

        booni.shape.Scale.X = 0.4 + math.sin(booni.total2) * 0.03
        booni.shape.Scale.Y = 0.4 + math.sin(booni.total3) * 0.03

        if booni.chatBubbleRemainingTime > 0.0 then
            booni.chatBubbleRemainingTime = booni.chatBubbleRemainingTime - dt
            if booni.chatBubbleRemainingTime <= 0.0 then

                booni.shape:ClearTextBubble()
                booni.shape:TextBubble(booni.username, 86400, Color(255, 255, 255, 150), Color(255, 255, 255, 0), false)
            end
        end

        if lockCamera == false then
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

Pointer.Down = function(e)

    lockCamera = true

    local impact = e:CastRay(Map.CollisionGroups)
    if impact.Block ~= nil then
        updateSelectorShape(impact)
    end
end

Pointer.Drag = function(e)

    yaw = yaw + e.DX * 0.01
    pitch = pitch - e.DY * 0.01
    Player.Rotation = {pitch, yaw, 0}

    local impact = e:CastRay(Map.CollisionGroups)
    if impact.Block ~= nil then
        updateSelectorShape(impact)
        if hitBlockCoords == impact.Block.Coords and hitBlockFace == impact.FaceTouched then
            selectorShape.IsHidden = false
            selectorShapeDisabled.IsHidden = true
        else
            selectorShape.IsHidden = true
            selectorShapeDisabled.IsHidden = false
        end
    end
end

Pointer.Up = function(e)

    lockCamera = false
    selectorShape.IsHidden = true
    selectorShapeDisabled.IsHidden = true

    if boonies[Player.ID] == nil then
        return
    end

    local impact = e:CastRay(Map.CollisionGroups)
    if impact.Block ~= nil then
        if impact.Block.Coords == hitBlockCoords and impact.FaceTouched == hitBlockFace then

            local coords = hitBlockCoords
            if hitBlockFace == BlockFace.Top then
                coords = coords + {0.5, 1.5, 0.5}
            elseif hitBlockFace == BlockFace.Bottom then
                coords = coords + {0.5, -0.5, 0.5}
            elseif hitBlockFace == BlockFace.Left then
                coords = coords + {-0.5, 0.5, 0.5}
            elseif hitBlockFace == BlockFace.Right then
                coords = coords + {1.5, 0.5, 0.5}
            elseif hitBlockFace == BlockFace.Front then
                coords = coords + {0.5, 0.5, -0.5}
            elseif hitBlockFace == BlockFace.Back then
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

Client.Tick = function(dt)

    checkForPlayers(dt)
    for name, booni in pairs(boonies) do
        updateBoony(booni, name, dt)
    end
    for name, booni in pairs(cpuBoonies) do
        updateBoony(booni, name, dt)
    end
end

Client.OnChat = function(msg)
    local e = Event()
    e.action = "chat"
    e.msg = msg
    e:SendTo(Players)
end

Client.OnPlayerJoin = function(player)
    print(player.Username .. "! Run for your life!")
    newBooni(player)
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
        booni.shape.Rotation = {0, math.pi, 0}
        booni.shape.Forward = Camera.Backward
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

-- ***************************************** UTILS ***************************************** 

dump = function(obj)
    print("[" .. tostring(obj) .. "]")
    for key, value in pairs(obj) do
        print("  " .. key .. ": ", value)
    end
end

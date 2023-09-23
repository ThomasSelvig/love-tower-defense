-- press F8 to launch game (if rebinded "Launch Löve")


function love.load()
    Sprites = require("sprites")
    GUI = require("gui")
    TileSize = 128
    -- tile sprites are 48*48
    TileScaleFactor = TileSize / 48

    Map = require("map")

    Enemies = require("enemies")
    Defenders = require("defenders")

    CurrentEnemies = {}
    CurrentDefenders = {}

    Joystick = nil
    JoystickPressedMap = {}

end



local function spotAvailable(x, y)
    -- occupied by defender?
    for _, defender in pairs(CurrentDefenders) do
        if defender.pos[1] == x and defender.pos[2] == y then
            return false
        end
    end
    -- occupied by tile?
    for _, tile in pairs(Map.walkable) do
        if tile[1] == x and tile[2] == y then
            return false
        end
    end
    -- occupied by obstacle?
    for _, tile in pairs(Map.obstacles) do
        if tile[1] == x and tile[2] == y then
            return false
        end
    end

    return true
end

local function tryPlaceDefender(x, y, defender)
    if spotAvailable(x, y) then
        -- place defender
        table.insert(CurrentDefenders, {
            type = defender,
            pos = {x, y},
            lastAttack = 0--love.timer.getTime()
        })
        return true
    end
    return false
end

local function addEnemy(x, y, enemy)
    table.insert(CurrentEnemies, {
        type = enemy,
        hp = enemy.hp,
        pos = {x, y},
        currentPathIndex = 1,
        currentPath = Map.pathfinding[1],
    })
end



function love.joystickadded(joystick)
    print("Joystick connected: " .. joystick:getName()) -- "Buzz"
    Joystick = joystick
end

---Triggered on buzz controller pressed
---@param controller number 0-3 player
---@param button any 0-4 (4=red, 0-3=yellow-blue)
local function buzzPressed(controller, button)
    -- print("Controller " .. controller .. ": " .. button)
    -- print(GUI.controller.cursor.x, GUI.controller.cursor.y)

    if button == 0 then
        tryPlaceDefender(
            GUI.controller.cursor.x,
            GUI.controller.cursor.y,
            Defenders[GUI.buyMenu.selectedDefender]
        )
    -- vim keybinds
    elseif button == 4 then
        GUI.controller.cursor.x = GUI.controller.cursor.x - 1
    elseif button == 3 then
        GUI.controller.cursor.y = GUI.controller.cursor.y + 1
    elseif button == 2 then
        GUI.controller.cursor.y = GUI.controller.cursor.y - 1
    elseif button == 1 then
        GUI.controller.cursor.x = GUI.controller.cursor.x + 1
    end
end



function love.keypressed(k)
    -- buy menu
    if Defenders[tonumber(k)] ~= nil then
        -- valid defender index pressed
        GUI.buyMenu.selectedDefender = tonumber(k)
    end

    -- quit
    if k == "escape" or k == "q" then
        love.event.quit()
    end

    -- debug features
    if k == "space" then
        addEnemy(-1, 0, Enemies[1])
    end
    -- (requires t.console=true in conf.lua)
    if k == "return" then
        debug.debug()
    end
end



function love.update(dt)
    local x, y = love.mouse.getPosition()
    x = math.floor(x / TileSize)
    y = math.floor(y / TileSize)
    -- input
    if love.mouse.isDown(1) then
        tryPlaceDefender(x, y, Defenders[GUI.buyMenu.selectedDefender])
        -- // TODO editor mode: place blocks

    end
    if love.mouse.isDown(2) then
        -- // TODO editor mode: remove blocks

    end
    -- trigger buzz input events
    if Joystick and Joystick:isConnected() and Joystick:getName() == "Buzz" then
        for i = 1,20 do
            local oldBtnVal = JoystickPressedMap[i]
            JoystickPressedMap[i] = Joystick:isDown(i)
            -- if wasnt pressed, but is pressed now
            if not oldBtnVal and JoystickPressedMap[i] then
                buzzPressed(math.floor((i-1) / 5), (i-1) % 5)
            end
        end
    end
    
    -- move enemies
    for _, enemy in pairs(CurrentEnemies) do
        -- remaining movement (if only some moved on x, carry to y)
        local movementLeft = enemy.type.speed * dt

        -- move towards currentPath
        local oldPos = enemy.pos
        local delta = {
            x = enemy.currentPath[1] - enemy.pos[1],
            y = enemy.currentPath[2] - enemy.pos[2]
        }
        -- should move x?
        if math.abs(delta.x) > movementLeft then
            local direction = delta.x >= 0 and 1 or -1
            enemy.pos[1] = enemy.pos[1] + movementLeft * direction
        elseif math.abs(delta.x) > 0 then
            enemy.pos[1] = enemy.currentPath[1]
        end
        -- decrement movement available by how much moved on x axis
        movementLeft = movementLeft - math.abs(oldPos[1] - enemy.pos[1])
        -- should move y?
        if math.abs(delta.y) > movementLeft then
            local direction = delta.y >= 0 and 1 or -1
            enemy.pos[2] = enemy.pos[2] + movementLeft * direction
        elseif math.abs(delta.y) > 0 then
            enemy.pos[2] = enemy.currentPath[2]
        end

        -- path completed?
        if enemy.pos[1] == enemy.currentPath[1] and enemy.pos[2] == enemy.currentPath[2] then
            -- is there more path left?
            if enemy.currentPathIndex < #Map.pathfinding then
                -- assign new path
                enemy.currentPathIndex = enemy.currentPathIndex + 1
                enemy.currentPath = Map.pathfinding[enemy.currentPathIndex]
            else
                -- all paths completed
                -- // TODO attack player
            end
        end

    end

    -- attack enemies
    -- // TODO optimize: make balloons register when they're in range of a defender mby?
    for _, defender in pairs(CurrentDefenders) do
        if love.timer.getTime() - defender.lastAttack > defender.type.rate then
            -- can attack, try to
            for _, enemy in pairs(CurrentEnemies) do
                local dx, dy = math.abs(enemy.pos[1] - defender.pos[1]), math.abs(enemy.pos[2] - defender.pos[2])
                if math.sqrt(math.pow(dx, 2) + math.pow(dy, 2)) < defender.type.range then
                    -- in range, attack
                    enemy.hp = enemy.hp - defender.type.damage
                    defender.lastAttack = love.timer.getTime()
                    -- print(math.sqrt(math.pow(dx, 2) + math.pow(dy, 2)))
                    print(enemy.hp)
                    break
                end
            end
        end
    end

    -- remove dead enemies (iterate backwards bc index shifts)
    for enemy = #CurrentEnemies,1,-1 do
        if CurrentEnemies[enemy].hp <= 0 then
            table.remove(CurrentEnemies, enemy)
        end
    end
end



function love.draw()
    -- draw grass background
    love.graphics.setBackgroundColor(0.25, 0.75, 0.25, 1)

    -- draw walkable paths
    for _, pos in pairs(Map.walkable) do
        love.graphics.draw(
            Sprites.tiles.smoothStone,
            pos[1] * TileSize,
            pos[2] * TileSize,
            0,
            TileScaleFactor,
            TileScaleFactor
        )
    end

    -- draw obstacles
    for _, pos in pairs(Map.obstacles) do
        love.graphics.draw(
            Sprites.tiles.sand,
            pos[1] * TileSize,
            pos[2] * TileSize,
            0,
            TileScaleFactor,
            TileScaleFactor
        )
    end

    -- draw enemies
    for _, enemy in pairs(CurrentEnemies) do
        love.graphics.draw(
            enemy.type.sprite,
            enemy.pos[1] * TileSize,
            enemy.pos[2] * TileSize,
            0,
            0.5,
            0.5
        )
    end

    -- draw defenders
    for _, defender in pairs(CurrentDefenders) do
        local xs, ys = GUI.getImageScaleForNewDimensions(defender.type.sprite)
        love.graphics.draw(
            defender.type.sprite,
            defender.pos[1] * TileSize,
            defender.pos[2] * TileSize,
            0,
            xs,
            ys
        )
        if love.timer.getTime() - defender.lastAttack < 0.25 then
            -- just attacked someone
            love.graphics.setColor(0.75, 0.25, 0.25, 0.25)
            love.graphics.ellipse(
                "fill",
                defender.pos[1] * TileSize,-- + TileSize/2, //TODO fix attack from center
                defender.pos[2] * TileSize,-- + TileSize/2,
                defender.type.range * TileSize,
                defender.type.range * TileSize
            )
            love.graphics.setColor(1, 1, 1, 1)
        end
    end

    GUI.draw()

end
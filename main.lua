-- press F8 to launch game


function love.load()
    -- load sprites
    Sprites = {
        defenders = {
            fox = love.graphics.newImage("sprites/defenders/fox.png"),
            monkey = love.graphics.newImage("sprites/defenders/monkey.png")
        },
        enemies = {
            balloon1 = love.graphics.newImage("sprites/enemies/balloon1.png"),
            balloon2 = love.graphics.newImage("sprites/enemies/balloon2.png"),
            balloon3 = love.graphics.newImage("sprites/enemies/balloon3.png"),
        },
        tiles = {
            dirt = love.graphics.newImage("sprites/tiles/dirt.png"),
            sand = love.graphics.newImage("sprites/tiles/sand.png"),
            smoothStone = love.graphics.newImage("sprites/tiles/smooth stone.png"),
        }
    }
    
    TileSize = 128
    -- the sprites are 48*48
    TileScaleFactor = TileSize / 48

    Map = require("map")

    Enemies = {
        {
            sprite = Sprites.enemies.balloon1,
            speed = 2,
            hp = 100
        },
        {
            sprite = Sprites.enemies.balloon2,
            speed = 2.5,
            hp = 150
        },
        {
            sprite = Sprites.enemies.balloon3,
            speed = 3,
            hp = 200
        }
    }

    --// TODO fix rate makes delay longer instead of shorter
    --// TODO some feature to make the defenders serve unique purposes
    Defenders = {
        {
            sprite = Sprites.defenders.fox,
            damage = 25,
            rate = 1,
            range = 2.5
        },
        {
            sprite = Sprites.defenders.monkey,
            damage = 34,
            rate = 2,
            range = 3.5
        }
    }

    GUI = require("gui")

    CurrentEnemies = {}
    CurrentDefenders = {}

    Waves = {}

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



local function getImageScaleForNewDimensions( image, newWidth, newHeight )
    local currentWidth, currentHeight = image:getDimensions()
    return ( (newWidth or TileSize) / currentWidth ), ( (newHeight or TileSize) / currentHeight )
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
        local xs, ys = getImageScaleForNewDimensions(defender.type.sprite)
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

    -- draw GUI
    -- selected defender-to-buy
    local defenderType = Defenders[GUI.buyMenu.selectedDefender]
    local w, h = love.graphics.getDimensions()
    -- love.graphics.circle("fill", w-TileSize/2, h-TileSize/2, TileSize / 2)
    love.graphics.setColor(0.25, 0.25, 0.75, 1)
    love.graphics.rectangle(
        "fill",
        w - TileSize - GUI.graphics.borderSize * 2,
        h - TileSize - GUI.graphics.borderSize * 2,
        TileSize + GUI.graphics.borderSize * 2,
        TileSize + GUI.graphics.borderSize * 2
    )
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        defenderType.sprite,
        w - TileSize - GUI.graphics.borderSize,
        h - TileSize - GUI.graphics.borderSize,
        0,
        getImageScaleForNewDimensions(defenderType.sprite)
    )

end
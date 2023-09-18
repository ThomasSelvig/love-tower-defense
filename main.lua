-- press F8 to launch game


function love.load()
    -- load sprites
    -- fox = love.graphics.newImage("sprites/fox.png")
    -- monkey = love.graphics.newImage("sprites/monkey.png")
    Sprites = {
        enemies = {
            balloon1 = love.graphics.newImage("sprites/enemies/balloon1.png"),
            balloon2 = love.graphics.newImage("sprites/enemies/balloon2.png"),
            balloon3 = love.graphics.newImage("sprites/enemies/balloon3.png"),
        },
        tiles = {
            smoothStone = love.graphics.newImage("sprites/tiles/smooth stone.png")
        }
    }
    
    -- the sprites are 48*48 but should be rendered as 64*64
    TileScaleFactor = 64 / 48

    Map = require("Map")

    Enemies = {
        {
            sprite = Sprites.enemies.balloon1,
            speed = 2,
            hp = 25
        },
        {
            sprite = Sprites.enemies.balloon2,
            speed = 2.5,
            hp = 50
        },
        {
            sprite = Sprites.enemies.balloon3,
            speed = 3,
            hp = 100
        }
    }

    CurrentEnemies = {}

    Waves = {}

end



function love.keypressed(k)
    if k == "space" then
        table.insert(CurrentEnemies, {
            type = Enemies[1],
            pos = {0, 0},
            currentPathIndex = 1,
            currentPath = Map.pathfinding[1],
        })
    end

    -- debug (requires t.console=true in conf.lua)
    if k == "return" then
        debug.debug()
    end
    -- quit
    if k == "escape" or k == "q" then
        love.event.quit()
    end
end



function love.update(dt)
    -- {4, 0},  --// TODO fix bug where enemy can only move x+ and y+
    
    -- move enemies
    for _, enemy in pairs(CurrentEnemies) do
        -- remaining movement (if only some moved on x, carry to y)
        local movementLeft = enemy.type.speed * dt

        -- move towards currentPath
        
        local oldPos = enemy.pos
        local delta = {
            x = math.abs(enemy.pos[1] - enemy.currentPath[1]),
            y = math.abs(enemy.pos[2] - enemy.currentPath[2])
        }

        -- should move x?
        if delta.x > movementLeft then
            enemy.pos[1] = enemy.pos[1] + movementLeft
        elseif delta.x > 0 then
            enemy.pos[1] = enemy.currentPath[1]
        end
        -- decrement movement available by how much moved on x axis
        movementLeft = movementLeft - math.abs(oldPos[1] - enemy.pos[1])

        -- should move y?
        if delta.y > movementLeft then
            enemy.pos[2] = enemy.pos[2] + movementLeft
        elseif delta.y > 0 then
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
end



function love.draw()

    -- draw grass background
    love.graphics.setBackgroundColor(0.25, 0.75, 0.25, 1)

    -- draw walkable paths
    for _, pos in pairs(Map.walkable) do
        love.graphics.draw(
            Sprites.tiles.smoothStone,
            pos[1] * 64,
            pos[2] * 64,
            0,
            TileScaleFactor,
            TileScaleFactor
        )
    end

    -- draw enemies
    for _, enemy in pairs(CurrentEnemies) do
        love.graphics.draw(
            enemy.type.sprite,
            enemy.pos[1] * 64,
            enemy.pos[2] * 64,
            0,
            0.5,
            0.5
        )
    end

end
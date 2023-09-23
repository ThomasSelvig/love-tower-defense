

local gui = {
    buyMenu = {
        selectedDefender = 1
    },
    graphics = {
        borderSize = 20
    },
    controller = {
        cursor = {x = 0, y = 0}
    }
}

function gui.getImageScaleForNewDimensions( image, newWidth, newHeight )
    local currentWidth, currentHeight = image:getDimensions()
    return ( (newWidth or TileSize) / currentWidth ), ( (newHeight or TileSize) / currentHeight )
end

function gui.draw()
    -- cursor
    if Joystick and Joystick:isConnected() then
        love.graphics.rectangle(
            "line",
            gui.controller.cursor.x * TileSize,
            gui.controller.cursor.y * TileSize,
            TileSize,
            TileSize
        )
    end

    -- selected defender-to-buy
    local defenderType = Defenders[gui.buyMenu.selectedDefender]
    local w, h = love.graphics.getDimensions()
    -- love.graphics.circle("fill", w-TileSize/2, h-TileSize/2, TileSize / 2)
    love.graphics.setColor(0.25, 0.25, 0.75, 1)
    love.graphics.rectangle(
        "fill",
        w - TileSize - gui.graphics.borderSize * 2,
        h - TileSize - gui.graphics.borderSize * 2,
        TileSize + gui.graphics.borderSize * 2,
        TileSize + gui.graphics.borderSize * 2
    )
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        defenderType.sprite,
        w - TileSize - gui.graphics.borderSize,
        h - TileSize - gui.graphics.borderSize,
        0,
        gui.getImageScaleForNewDimensions(defenderType.sprite)
    )
end

return gui
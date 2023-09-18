

return {
    -- positions to render walkable tiles
    walkable = {
        {0, 0},
        {1, 0},
        {2, 0},
        {3, 0},
        {4, 0},
        {4, 1},
        {4, 2},
        {4, 3},
        {4, 4},
        {4, 5},
    },
    -- positions to disallow placement of defense
    obstacles = {

    },
    -- paths are like vectors
    -- order is important here, unlike `walkable`
    pathfinding = {
        {4, 0},
        {4, 5},
    }
}
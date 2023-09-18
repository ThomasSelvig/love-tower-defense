

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
        {5, 5},
        {6, 5},
        {7, 5},
        {8, 5},
        {9, 5},
        {10, 5},
        {11, 5},
        {12, 5},
        {13, 5},
        {14, 5},
        {15, 5},
        {15, 6},
        {15, 7},
        {15, 8},
        {15, 9},
        {15, 10},
        {15, 11},
    },
    -- positions to disallow placement of defense
    obstacles = {

    },
    -- paths are like vectors
    -- order is important here, unlike `walkable`
    pathfinding = {
        {4, 0},
        {4, 5},
        {15, 5},
        {15, 11}
        -- {4, 0},
    }
}
-- Part 1: the window, two Lua tables, keyboard input, and delta time.
local player1, player2

function love.load()
    love.graphics.setBackgroundColor(0.03, 0.05, 0.09)
    player1 = {x = 40, y = 300, width = 16, height = 110, speed = 420}
    player2 = {x = 1044, y = 300, width = 16, height = 110, speed = 420}
end

function love.update(dt)
    if love.keyboard.isDown("w") then player1.y = player1.y - player1.speed * dt end
    if love.keyboard.isDown("s") then player1.y = player1.y + player1.speed * dt end
    if love.keyboard.isDown("up") then player2.y = player2.y - player2.speed * dt end
    if love.keyboard.isDown("down") then player2.y = player2.y + player2.speed * dt end

    local height = love.graphics.getHeight()
    player1.y = math.max(0, math.min(height - player1.height, player1.y))
    player2.y = math.max(0, math.min(height - player2.height, player2.y))
end

function love.draw()
    love.graphics.setColor(0.2, 0.85, 1)
    love.graphics.rectangle("fill", player1.x, player1.y, player1.width, player1.height)
    love.graphics.setColor(1, 0.7, 0.3)
    love.graphics.rectangle("fill", player2.x, player2.y, player2.width, player2.height)
end

-- Run from the project folder: lua tests/game_spec.lua
-- These tests exercise the real main.lua with graphics/audio replaced by stubs.
local held = {}
local noop = function() end
love = {
    graphics = {setBackgroundColor = noop, setDefaultFilter = noop,
        newFont = function() return {} end},
    keyboard = {setKeyRepeat = noop, isDown = function(key) return held[key] or false end},
    mouse = {setVisible = noop},
    math = {random = math.random},
    event = {quit = noop}
}
local game = require("main")
local total = 0
local function close(actual, expected, tolerance)
    assert(math.abs(actual - expected) <= (tolerance or 0.00001),
        "Expected " .. expected .. ", got " .. actual)
end
local function test(name, callback)
    held = {}
    math.randomseed(17)
    love.load()
    callback()
    total = total + 1
    print("PASS  " .. name)
end

test("the ball starts centered and waits for a serve", function()
    close(game.ball.x + game.ball.width / 2, 550)
    close(game.ball.y + game.ball.height / 2, 390)
    local x, y = game.ball.x, game.ball.y
    love.update(1)
    close(game.ball.x, x)
    close(game.ball.y, y)
    assert(game.phase == "serve")
end)

test("both paddles use their assigned keys", function()
    local y1, y2 = game.player1.y, game.player2.y
    held.w, held.down = true, true
    love.update(0.1)
    close(game.player1.y, y1 - 44)
    close(game.player2.y, y2 + 44)
    held = {s = true, up = true}
    love.update(0.1)
    close(game.player1.y, y1)
    close(game.player2.y, y2)
end)

test("paddles stay inside both arena boundaries", function()
    held.w, held.up = true, true
    love.update(5)
    close(game.player1.y, 160)
    close(game.player2.y, 160)
    held = {s = true, down = true}
    love.update(5)
    close(game.player1.y + game.player1.height, 620)
    close(game.player2.y + game.player2.height, 620)
end)

test("ball movement uses pixels per second and dt", function()
    love.keypressed("space")
    game.ball.dx, game.ball.dy = 240, 100
    game.ball.x, game.ball.y = 300, 300
    love.update(0.25)
    close(game.ball.x, 360)
    close(game.ball.y, 325)
end)

test("movement agrees at 30, 60, and 144 FPS", function()
    local referenceX, referenceY, referencePaddle
    for _, fps in ipairs({30, 60, 144}) do
        love.keypressed("r")
        love.keypressed("space")
        game.ball.x, game.ball.y = 300, 300
        game.ball.dx, game.ball.dy = 240, 100
        held = {s = true}
        for _ = 1, fps do love.update(1 / fps) end
        if referenceX then
            close(game.ball.x, referenceX)
            close(game.ball.y, referenceY)
            close(game.player1.y, referencePaddle)
        end
        referenceX, referenceY = game.ball.x, game.ball.y
        referencePaddle = game.player1.y
    end
end)

test("AABB distinguishes overlap, touching edges, and separation", function()
    local a = {x = 0, y = 0, width = 16, height = 16}
    assert(game.collides(a, {x = 15, y = 15, width = 8, height = 8}))
    assert(not game.collides(a, {x = 16, y = 0, width = 8, height = 8}))
    assert(not game.collides(a, {x = 50, y = 50, width = 8, height = 8}))
end)

test("top and bottom walls reverse vertical velocity", function()
    love.keypressed("space")
    game.ball.y, game.ball.dy = 160, -210
    love.update(1 / 240)
    assert(game.ball.dy > 0 and game.ball.y >= 160)
    game.ball.y, game.ball.dy = 604, 210
    love.update(1 / 240)
    assert(game.ball.dy < 0 and game.ball.y + game.ball.height <= 620)
end)

test("left paddle reverses the ball and separates it", function()
    love.keypressed("space")
    game.ball.x = game.player1.x + game.player1.width
    game.ball.y = game.player1.y + 30
    game.ball.dx, game.ball.dy = -360, 0
    love.update(1 / 240)
    assert(game.ball.dx > 360)
    assert(game.ball.x >= game.player1.x + game.player1.width)
    assert(not game.collides(game.ball, game.player1))
    assert(game.rally == 1)
    love.update(1 / 240)
    assert(game.rally == 1)
end)

test("right paddle reverses the ball and separates it", function()
    love.keypressed("space")
    game.ball.x = game.player2.x - game.ball.width
    game.ball.y = game.player2.y + 30
    game.ball.dx, game.ball.dy = 360, 0
    love.update(1 / 240)
    assert(game.ball.dx < -360)
    assert(game.ball.x + game.ball.width <= game.player2.x)
    assert(not game.collides(game.ball, game.player2))
end)

test("a fast ball cannot skip through a paddle during a long frame", function()
    love.keypressed("space")
    game.ball.x, game.ball.y = 130, game.player1.y + 30
    game.ball.dx, game.ball.dy = -750, 0
    love.update(0.2)
    assert(game.ball.dx == 750)
    assert(game.rally == 1 and game.player2.score == 0)
end)

test("a missed ball awards one point then waits in the center", function()
    love.keypressed("space")
    game.ball.x, game.ball.y, game.ball.dx = 1062, 180, 360
    love.update(0.1)
    assert(game.player1.score == 1 and game.player2.score == 0)
    assert(game.phase == "serve")
    close(game.ball.x + game.ball.width / 2, 550)
    love.update(2)
    assert(game.player1.score == 1)
    love.keypressed("space")
    game.ball.x, game.ball.y, game.ball.dx = 20, 180, -360
    love.update(0.1)
    assert(game.player2.score == 1)
end)

test("seven points ends the match and Space starts a rematch", function()
    game.player1.score = 6
    love.keypressed("space")
    game.ball.x, game.ball.y, game.ball.dx = 1062, 180, 360
    love.update(0.1)
    assert(game.phase == "gameover" and game.winner == 1)
    love.keypressed("space")
    assert(game.phase == "playing" and game.player1.score == 0 and game.player2.score == 0)
end)

test("pause freezes the ball and paddles; P resumes", function()
    love.keypressed("space")
    love.keypressed("p")
    local x, y = game.ball.x, game.player1.y
    held.w = true
    love.update(1)
    close(game.ball.x, x)
    close(game.player1.y, y)
    love.keypressed("p")
    assert(game.phase == "playing")
end)

test("losing focus pauses and requires manual resume", function()
    love.keypressed("space")
    love.focus(false)
    assert(game.phase == "paused")
    love.focus(true)
    assert(game.phase == "paused")
    love.keypressed("space")
    assert(game.phase == "playing")
end)

test("R resets scores and M toggles sound", function()
    game.player1.score, game.player2.score = 4, 3
    game.bestRally = 8
    love.keypressed("r")
    assert(game.player1.score == 0 and game.player2.score == 0)
    assert(game.bestRally == 0 and game.phase == "serve")
    local before = game.muted
    love.keypressed("m")
    assert(game.muted ~= before)
end)

print("\n" .. total .. " gameplay tests passed.")

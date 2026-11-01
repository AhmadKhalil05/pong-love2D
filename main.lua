-- PONG / LOCAL DUEL
-- Gameplay lives here. ui.lua only draws the interface.
local ui = require("ui")

local game = {
    width = 1100,
    height = 720,
    arena = {x = 40, y = 160, width = 1020, height = 460},
    winningScore = 7,
    phase = "serve",
    time = 0,
    rally = 0,
    bestRally = 0,
    muted = false,
    particles = {},
    trail = {},
    trailTimer = 0,
    sounds = {}
}

-- AABB: all four comparisons must be true for two rectangles to overlap.
function game.collides(a, b)
    return a.x < b.x + b.width
       and a.x + a.width > b.x
       and a.y < b.y + b.height
       and a.y + a.height > b.y
end

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function playSound(name)
    local source = game.sounds[name]
    if source and not game.muted then
        source:stop()
        source:play()
    end
end

-- Short sounds are synthesized locally; no downloads or sound assets needed.
local function makeTone(frequency, duration)
    local rate = 22050
    local count = math.floor(rate * duration)
    local data = love.sound.newSoundData(count, rate, 16, 1)
    for sample = 0, count - 1 do
        local envelope = (1 - sample / count) ^ 2
        local wave = math.sin(2 * math.pi * frequency * sample / rate)
        data:setSample(sample, wave * envelope * 0.16)
    end
    return love.audio.newSource(data, "static")
end

local function resetBall(direction)
    local ball, arena = game.ball, game.arena
    ball.x = arena.x + (arena.width - ball.width) / 2
    ball.y = arena.y + (arena.height - ball.height) / 2
    -- Velocity is measured in pixels PER SECOND, not pixels per frame.
    ball.dx = 360 * direction
    ball.dy = 210 * (love.math.random(0, 1) == 0 and -1 or 1)
    game.rally = 0
    game.trail = {}
    game.trailTimer = 0
end

local function resetMatch()
    local arena = game.arena
    game.player1.score = 0
    game.player2.score = 0
    game.player1.y = arena.y + (arena.height - game.player1.height) / 2
    game.player2.y = arena.y + (arena.height - game.player2.height) / 2
    game.bestRally = 0
    game.winner = nil
    game.lastScorer = nil
    game.particles = {}
    game.phase = "serve"
    game.previousPhase = nil
    resetBall(1)
end

local function burst(x, y, color)
    for _ = 1, 10 do
        local angle = love.math.random() * math.pi * 2
        local speed = love.math.random(60, 180)
        game.particles[#game.particles + 1] = {
            x = x, y = y,
            dx = math.cos(angle) * speed,
            dy = math.sin(angle) * speed,
            life = 0.35, maximumLife = 0.35,
            color = color
        }
    end
end

local function scorePoint(player, number, direction)
    player.score = player.score + 1
    game.lastScorer = number
    resetBall(direction)
    playSound("score")
    if player.score >= game.winningScore then
        game.winner = number
        game.phase = "gameover"
    else
        game.phase = "serve"
    end
end

local function movePaddle(player, upKey, downKey, dt)
    local movement = 0
    if love.keyboard.isDown(upKey) then movement = movement - 1 end
    if love.keyboard.isDown(downKey) then movement = movement + 1 end
    player.y = player.y + movement * player.speed * dt
    player.y = clamp(player.y, game.arena.y,
        game.arena.y + game.arena.height - player.height)
end

local function paddleHit(player, direction)
    local ball = game.ball
    -- Place the ball OUTSIDE the paddle, so it cannot bounce repeatedly inside it.
    if direction == 1 then
        ball.x = player.x + player.width
    else
        ball.x = player.x - ball.width
    end
    -- Own change: each paddle hit adds 4.5% horizontal speed, with a safe cap.
    ball.dx = direction * math.min(math.abs(ball.dx) * 1.045, 750)
    game.rally = game.rally + 1
    game.bestRally = math.max(game.bestRally, game.rally)
    burst(ball.x + ball.width / 2, ball.y + ball.height / 2, player.color)
    playSound("hit")
end

local function moveBall(dt)
    local ball, arena = game.ball, game.arena
    ball.x = ball.x + ball.dx * dt
    ball.y = ball.y + ball.dy * dt

    if ball.y < arena.y and ball.dy < 0 then
        ball.y = arena.y
        ball.dy = -ball.dy
        playSound("wall")
    elseif ball.y + ball.height > arena.y + arena.height and ball.dy > 0 then
        ball.y = arena.y + arena.height - ball.height
        ball.dy = -ball.dy
        playSound("wall")
    end

    -- The direction checks prevent a second hit while moving away from a paddle.
    if ball.dx < 0 and game.collides(ball, game.player1) then
        paddleHit(game.player1, 1)
    elseif ball.dx > 0 and game.collides(ball, game.player2) then
        paddleHit(game.player2, -1)
    end

    if ball.x + ball.width < arena.x then
        scorePoint(game.player2, 2, -1)
    elseif ball.x > arena.x + arena.width then
        scorePoint(game.player1, 1, 1)
    end

    if game.phase == "playing" then
        game.trailTimer = game.trailTimer + dt
        if game.trailTimer >= 0.014 then
            game.trailTimer = game.trailTimer - 0.014
            game.trail[#game.trail + 1] = {x = ball.x, y = ball.y, life = 0.16}
        end
    end
end

local function updateEffects(dt)
    for index = #game.particles, 1, -1 do
        local particle = game.particles[index]
        particle.life = particle.life - dt
        particle.x = particle.x + particle.dx * dt
        particle.y = particle.y + particle.dy * dt
        if particle.life <= 0 then table.remove(game.particles, index) end
    end
    for index = #game.trail, 1, -1 do
        local point = game.trail[index]
        point.life = point.life - dt
        if point.life <= 0 then table.remove(game.trail, index) end
    end
end

-- 1. LOAD: called once to create the initial game state.
function love.load()
    love.graphics.setBackgroundColor(0.025, 0.04, 0.07)
    love.graphics.setDefaultFilter("linear", "linear")
    love.keyboard.setKeyRepeat(false)
    love.mouse.setVisible(false)
    game.player1 = {
        x = 65, y = 0, width = 16, height = 96, speed = 440,
        score = 0, color = {0.24, 0.84, 1.0}
    }
    game.player2 = {
        x = 1019, y = 0, width = 16, height = 96, speed = 440,
        score = 0, color = {1.0, 0.69, 0.33}
    }
    game.ball = {x = 0, y = 0, width = 16, height = 16, dx = 360, dy = 210}
    ui.load()
    -- Keep playing normally if the computer has no audio device.
    local ok, sounds = pcall(function()
        return {hit = makeTone(640, 0.065), wall = makeTone(400, 0.045),
            score = makeTone(220, 0.22)}
    end)
    if ok then game.sounds = sounds end
    resetMatch()
end

-- 2. UPDATE: dt is the elapsed time in seconds since the previous frame.
function love.update(dt)
    game.time = game.time + dt
    if game.phase == "paused" then return end
    updateEffects(dt)
    if game.phase ~= "serve" and game.phase ~= "playing" then return end

    -- Small substeps prevent fast balls from skipping through a paddle.
    -- The full dt is consumed, so 30 FPS and 144 FPS cover the same game time.
    local remaining = dt
    while remaining > 0 do
        local step = math.min(remaining, 1 / 240)
        movePaddle(game.player1, "w", "s", step)
        movePaddle(game.player2, "up", "down", step)
        if game.phase == "playing" then moveBall(step) end
        remaining = remaining - step
        if game.phase == "gameover" then break end
    end
end

-- 3. DRAW: renders the current state without changing the game rules.
function love.draw()
    ui.draw(game)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "m" then
        game.muted = not game.muted
    elseif key == "r" then
        resetMatch()
    elseif key == "p" then
        if game.phase == "paused" then
            game.phase = game.previousPhase
        elseif game.phase == "playing" or game.phase == "serve" then
            game.previousPhase = game.phase
            game.phase = "paused"
        end
    elseif key == "space" or key == "return" then
        if game.phase == "gameover" then
            resetMatch()
            game.phase = "playing"
        elseif game.phase == "serve" then
            game.phase = "playing"
        elseif game.phase == "paused" then
            game.phase = game.previousPhase
        end
    elseif key == "f12" then
        love.graphics.captureScreenshot("pong-screenshot.png")
        print("Screenshot: " .. love.filesystem.getSaveDirectory() .. "/pong-screenshot.png")
    end
end

function love.focus(focused)
    if not focused and (game.phase == "playing" or game.phase == "serve") then
        game.previousPhase = game.phase
        game.phase = "paused"
    end
end

-- Returning the state also makes the actual gameplay easy to inspect and test.
return game

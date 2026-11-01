-- Presentation only: the collision and movement code stays in main.lua.
local ui = {}
local fonts = {}
local cyan = {0.24, 0.84, 1.0}
local amber = {1.0, 0.69, 0.33}
local white = {0.92, 0.95, 1.0}
local muted = {0.43, 0.51, 0.63}

local function color(rgb, alpha)
    love.graphics.setColor(rgb[1], rgb[2], rgb[3], alpha or 1)
end

local function text(value, x, y, font, tint, width, align)
    love.graphics.setFont(fonts[font])
    color(tint or white)
    if width then
        love.graphics.printf(value, x, y, width, align or "left")
    else
        love.graphics.print(value, x, y)
    end
end

local function rectangle(mode, x, y, width, height, radius)
    love.graphics.rectangle(mode, x, y, width, height, radius or 0, radius or 0)
end

local function keycap(value, x, y, width, tint)
    color(tint, 0.08)
    rectangle("fill", x, y, width, 25, 6)
    color(tint, 0.28)
    rectangle("line", x + 0.5, y + 0.5, width - 1, 24, 6)
    text(value, x, y + 5, "small", tint, width, "center")
end

function ui.load()
    fonts.small = love.graphics.newFont(11)
    fonts.body = love.graphics.newFont(14)
    fonts.title = love.graphics.newFont(29)
    fonts.headline = love.graphics.newFont(32)
    fonts.score = love.graphics.newFont(64)
end

local function header(game)
    text("PONG", 40, 27, "title")
    color(cyan)
    love.graphics.circle("fill", 143, 48, 3)
    text("A CLASSIC. A NEW RALLY.", 41, 71, "small", muted)

    text("PLAYER 01", 410, 25, "small", cyan, 110, "center")
    text("PLAYER 02", 580, 25, "small", amber, 110, "center")
    text(string.format("%02d", game.player1.score), 410, 43, "score", white, 110, "center")
    text(string.format("%02d", game.player2.score), 580, 43, "score", white, 110, "center")
    text(":", 535, 56, "title", muted, 30, "center")
    text("FIRST TO " .. game.winningScore, 491, 114, "small", muted, 118, "center")

    color(cyan, 0.07)
    rectangle("fill", 897, 34, 163, 32, 16)
    color(cyan, 0.35)
    love.graphics.circle("fill", 915, 50, 3)
    text("LOCAL MULTIPLAYER", 929, 44, "small", cyan)
    text(game.muted and "SOUND OFF" or "SOUND ON", 897, 79, "small", muted, 163, "right")

    text("THE ARENA", 41, 139, "small", muted)
    local status = ({serve = "AWAITING SERVE", playing = "MATCH IN PROGRESS",
        paused = "MATCH PAUSED", gameover = "MATCH COMPLETE"})[game.phase]
    text(status, 825, 139, "small", muted, 235, "right")
end

local function court(game)
    local a = game.arena
    color({0.045, 0.065, 0.10})
    rectangle("fill", a.x, a.y, a.width, a.height, 18)
    love.graphics.setScissor(a.x + 1, a.y + 1, a.width - 2, a.height - 2)

    color(white, 0.022)
    for x = a.x + 30, a.x + a.width - 1, 40 do
        love.graphics.line(x, a.y, x, a.y + a.height)
    end
    for y = a.y + 30, a.y + a.height - 1, 40 do
        love.graphics.line(a.x, y, a.x + a.width, y)
    end

    color(cyan, 0.025)
    rectangle("fill", a.x, a.y, 85, a.height)
    color(amber, 0.025)
    rectangle("fill", a.x + a.width - 85, a.y, 85, a.height)
    color(white, 0.06)
    love.graphics.circle("line", game.width / 2, a.y + a.height / 2, 64)
    for y = a.y + 22, a.y + a.height - 20, 22 do
        color(white, 0.14)
        rectangle("fill", game.width / 2 - 1, y, 2, 9, 1)
    end
    love.graphics.setScissor()

    color(white, 0.10)
    rectangle("line", a.x + 0.5, a.y + 0.5, a.width - 1, a.height - 1, 18)
    color(cyan, 0.50)
    rectangle("fill", a.x, a.y + 42, 2, a.height - 84, 1)
    color(amber, 0.50)
    rectangle("fill", a.x + a.width - 2, a.y + 42, 2, a.height - 84, 1)

    if game.phase == "playing" then
        color({0.045, 0.065, 0.10})
        rectangle("fill", 498, 174, 104, 25, 12)
        text(string.format("RALLY %02d", game.rally), 498, 182, "small", muted, 104, "center")
    end
end

local function paddle(player)
    for spread = 12, 3, -3 do
        color(player.color, 0.018)
        rectangle("fill", player.x - spread, player.y - spread,
            player.width + spread * 2, player.height + spread * 2, 10)
    end
    color(player.color)
    rectangle("fill", player.x, player.y, player.width, player.height, 5)
    color(white, 0.45)
    rectangle("fill", player.x + 4, player.y + 6, 2, player.height - 12, 1)
end

local function ballAndEffects(game)
    local ball = game.ball
    local tint = ball.dx > 0 and cyan or amber
    for _, point in ipairs(game.trail) do
        color(tint, math.max(0, point.life / 0.16) * 0.19)
        rectangle("fill", point.x + 2, point.y + 2, ball.width - 4, ball.height - 4, 3)
    end
    for _, particle in ipairs(game.particles) do
        color(particle.color, particle.life / particle.maximumLife)
        rectangle("fill", particle.x, particle.y, 3, 3, 1)
    end
    for spread = 10, 2, -2 do
        color(white, 0.025)
        rectangle("fill", ball.x - spread, ball.y - spread,
            ball.width + spread * 2, ball.height + spread * 2, 6)
    end
    color(white)
    rectangle("fill", ball.x, ball.y, ball.width, ball.height, 4)
end

local function overlay(game)
    if game.phase == "playing" then return end
    local a = game.arena
    color({0.015, 0.025, 0.045}, 0.65)
    rectangle("fill", a.x + 1, a.y + 1, a.width - 2, a.height - 2, 18)
    color({0.065, 0.09, 0.135}, 0.98)
    rectangle("fill", 313, 290, 474, 201, 18)
    color(white, 0.12)
    rectangle("line", 313.5, 290.5, 473, 200, 18)

    local eyebrow, title, description, key, tint
    if game.phase == "serve" then
        eyebrow = game.lastScorer and ("PLAYER 0" .. game.lastScorer .. " SCORED") or "TWO PLAYERS. ONE KEYBOARD."
        title = game.lastScorer and "One more rally." or "Ready to rally?"
        description = "Move your paddles. Find your rhythm."
        key, tint = "SPACE  /  SERVE", cyan
    elseif game.phase == "paused" then
        eyebrow, title = "TAKE A BREATHER", "Time out."
        description = "Your match is right where you left it."
        key, tint = "P  /  RESUME", cyan
    else
        eyebrow, title = "MATCH POINT. MATCH WON.", "PLAYER 0" .. game.winner .. " WINS"
        description = "Final score  " .. game.player1.score .. " : " .. game.player2.score
            .. "     |     Best rally  " .. game.bestRally
        key = "SPACE  /  PLAY AGAIN"
        tint = game.winner == 1 and cyan or amber
    end
    text(eyebrow, 333, 311, "small", tint, 434, "center")
    text(title, 328, 337, "headline", white, 444, "center")
    text(description, 328, 384, "body", muted, 444, "center")
    color(tint, 0.10 + 0.035 * math.sin(game.time * 3))
    rectangle("fill", 439, 430, 222, 37, 9)
    color(tint, 0.3)
    rectangle("line", 439.5, 430.5, 221, 36, 9)
    text(key, 439, 442, "small", tint, 222, "center")
end

local function footer(game)
    color(white, 0.05)
    rectangle("fill", 40, 641, 249, 53, 11)
    rectangle("fill", 811, 641, 249, 53, 11)
    text("PLAYER 01", 56, 653, "small", cyan)
    text("LEFT PADDLE", 56, 671, "small", muted)
    keycap("W", 207, 655, 29, cyan)
    keycap("S", 243, 655, 29, cyan)
    text("PLAYER 02", 827, 653, "small", amber)
    text("RIGHT PADDLE", 827, 671, "small", muted)
    keycap("UP", 957, 655, 37, amber)
    keycap("DN", 1001, 655, 43, amber)

    text("SPACE  Serve     P  Pause     R  Reset", 309, 650, "body", white, 482, "center")
    text("M  Sound     ESC  Quit     |     Best rally  " .. game.bestRally,
        309, 675, "small", muted, 482, "center")
    text("TWO PLAYERS. ONE KEYBOARD.", 40, 706, "small", muted)
    text("LOCAL DUEL / FIRST TO " .. game.winningScore, 760, 706, "small", muted, 300, "right")
end

function ui.draw(game)
    love.graphics.setLineWidth(1)
    header(game)
    court(game)
    paddle(game.player1)
    paddle(game.player2)
    ballAndEffects(game)
    overlay(game)
    footer(game)
    love.graphics.setColor(1, 1, 1, 1)
end

return ui

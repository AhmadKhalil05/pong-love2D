function love.conf(t)
    t.identity = "pong-love2d"
    t.version = "11.5"
    t.window.title = "Pong | Local Duel"
    t.window.width = 1100
    t.window.height = 720
    t.window.resizable = false
    t.window.vsync = 1
    t.window.highdpi = false
    t.modules.joystick = false
    t.modules.physics = false
end

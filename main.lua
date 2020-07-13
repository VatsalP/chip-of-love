Chip8 = require('chip8') : new() 
local grid = {}
local scale = 15

function rgba (r, g, b, a)
  r = r or 255
  g = g or 255
  b = b or 255
  a = a or 1
  return {r/255, g/255, b/255, a}
end


function love.load(args)
    if #args < 2 then
        print("Need to be supplied a romfile")
        love.event.quit(1)
    else
        -- window resolution
        love.window.setMode(64 * scale, 32 * scale, { msaa=2 })
        -- load the rom
        local romfile = assert(io.open(arg[2], "rb"))
        local binary = { string.byte(romfile:read("*all"), 1, -1) }
        Chip8:load_rom(binary)
        Chip8:next_opcode()
    end
end


function love.update(dt)
    Chip8.timer:count_down(dt)
end


function love.draw()
    -- display grid init
    for i = 0, 63 do
        for j = 0, 31 do
            if Chip8.display[i][j] == 1 then
                love.graphics.setColor(rgba(135, 245, 66))
                love.graphics.rectangle("fill", i * scale, j * scale, scale - 1, scale - 1)
            else
                love.graphics.setColor(rgba(0, 0, 0))
                love.graphics.rectangle("fill", i * scale, j * scale, scale - 1, scale - 1)
            end
        end
    end
end


function love.run()
    if love.math then love.math.setRandomSeed(os.time()) end
    if love.load then love.load(arg) end
    if love.timer then love.timer.step() end
    local dt = 0
    local fixed_dt = 1/60
    local accumulator = 0
    while true do
        if love.event then
            love.event.pump()
            for name, a,b,c,d,e,f in love.event.poll() do
                if name == 'quit' then
                    if not love.quit or not love.quit() then
                        return a
                    end
                end
                love.handlers[name](a,b,c,d,e,f)
            end
        end
        if love.timer then
            love.timer.step()
            dt = love.timer.getDelta()
        end
        accumulator = accumulator + dt
        while accumulator >= fixed_dt do
            if love.update then love.update(fixed_dt) end
            accumulator = accumulator - fixed_dt
        end
        if love.graphics and love.graphics.isActive() then
            love.graphics.clear(love.graphics.getBackgroundColor())
            love.graphics.origin()
            if love.draw then love.draw() end
            love.graphics.present()
        end
        if love.timer then love.timer.sleep(0.001) end
    end
end
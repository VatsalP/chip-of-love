chip8 = require('chip8') : new()


local scale = 15

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
        chip8:load_rom(binary)
        chip8:next_opcode()
    end
end


function love.update(dt)
    chip8:next_opcode()
    chip8.timer:count_down(dt)
end


function love.keypressed(key)
    if key == "1" then
        chip8.keys[0x1] = true
    elseif key == "2" then
        chip8.keys[0x2] = true
    elseif key == "3" then
        chip8.keys[0x3] = true
    elseif key == "4" then
        chip8.keys[0xC] = true
    elseif key == "q" then
        chip8.keys[0x4] = true
    elseif key == "w" then
        chip8.keys[0x5] = true
    elseif key == "e" then
        chip8.keys[0x6] = true
    elseif key == "r" then
        chip8.keys[0xD] = true
    elseif key == "a" then
        chip8.keys[0x7] = true
    elseif key == "s" then
        chip8.keys[0x8] = true
    elseif key == "d" then
        chip8.keys[0x9] = true
    elseif key == "f" then
        chip8.keys[0xE] = true
    elseif key == "z" then
        chip8.keys[0xA] = true
    elseif key == "x" then
        chip8.keys[0x0] = true
    elseif key == "c" then
        chip8.keys[0xB] = true
    elseif key == "v" then
        chip8.keys[0xF] = true
    end
 end


function love.keyreleased(key)
    if key == "1" then
        chip8.keys[0x1] = false
    elseif key == "2" then
        chip8.keys[0x2] = false
    elseif key == "3" then
        chip8.keys[0x3] = false
    elseif key == "4" then
        chip8.keys[0xC] = false
    elseif key == "q" then
        chip8.keys[0x4] = false
    elseif key == "w" then
        chip8.keys[0x5] = false
    elseif key == "e" then
        chip8.keys[0x6] = false
    elseif key == "r" then
        chip8.keys[0xD] = false
    elseif key == "a" then
        chip8.keys[0x7] = false
    elseif key == "s" then
        chip8.keys[0x8] = false
    elseif key == "d" then
        chip8.keys[0x9] = false
    elseif key == "f" then
        chip8.keys[0xE] = false
    elseif key == "z" then
        chip8.keys[0xA] = false
    elseif key == "x" then
        chip8.keys[0x0] = false
    elseif key == "c" then
        chip8.keys[0xB] = false
    elseif key == "v" then
        chip8.keys[0xF] = false
    end
 end


function love.draw()
    -- display grid init
    for j = 0, 31 do
        for i = 0, 63 do
            if chip8.display[j][i] == 1 then
                love.graphics.setColor(135 / 255, 245 / 255, 66 / 255)
                love.graphics.rectangle("fill", i * scale, j * scale, scale, scale)
            else
                love.graphics.setColor(0, 0, 0)
                love.graphics.rectangle("fill", i * scale, j * scale, scale, scale)
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
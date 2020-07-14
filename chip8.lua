local Chip8 = {}

function Chip8:new()
    local t = setmetatable({}, { __index = Chip8 })


    -- keyboard used by chip 8 is hexadecimal
    -- 0x0 to 0xF hex digits
    t.keys = {}
    for i = 0, 0xF do
        t.keys[i] = false
    end
    -- display is 64 * 32 pixels
    t.display = {}
    for j = 0, 31 do
        t.display[j] = {}
        for i = 0, 63 do
            t.display[j][i] = 0
        end
    end
    -- 4096 bytes of memory
    t.memory = {}
    for i = 0, 4095 do
        t.memory[i] = 0
    end
    -- chip 8 programs are loaded at location 0x200 in memory
    t.pc = 0x200
    -- stack pointer points to memory location 0xEA0
    t.sp = 0xEA0
    -- 16 8 bit data register
    t.v = {}
    for i = 0, 15 do
        t.v[i] = 0
    end
    -- 16 bit register that points to memory
    t.i = 0
    t.timer = {
        delay = 0, sound = 0,
        count_down = function (it, dt)
            it.delay = it.delay - dt < 0 and 0 or it.delay - dt
            it.sound = it.sound - dt < 0 and 0 or it.sound - dt
        end,
    }
    return t
end

function Chip8:load_font()
    -- storing hexadecimal digit sprites in memory starting from location 0
    local font = {
        0xF0, 0x90, 0x90, 0x90, 0xF0, -- 0
        0x20, 0x60, 0x20, 0x20, 0x70, -- 1
        0xF0, 0x10, 0xF0, 0x80, 0xF0, -- 2
        0xF0, 0x10, 0xF0, 0x80, 0xF0, -- 3
        0x90, 0x90, 0xF0, 0x10, 0x10, -- 4
        0xF0, 0x80, 0xF0, 0x10, 0xF0, -- 5
        0xF0, 0x80, 0xF0, 0x90, 0xF0, -- 6
        0xF0, 0x10, 0x20, 0x40, 0x40, -- 7
        0xF0, 0x90, 0xF0, 0x90, 0xF0, -- 8
        0xF0, 0x90, 0xF0, 0x10, 0xF0, -- 9
        0xF0, 0x90, 0xF0, 0x90, 0x90, -- a
        0xE0, 0x90, 0xE0, 0x90, 0xE0, -- b
        0xF0, 0x80, 0x80, 0x80, 0xF0, -- c
        0xE0, 0x90, 0x90, 0x90, 0xE0, -- d
        0xF0, 0x80, 0xF0, 0x80, 0xF0, -- e
        0xF0, 0x80, 0xF0, 0x80, 0x80, -- f
    }
    for i, byte in ipairs(font) do
        self.memory[i - 1] = byte
    end
end


function Chip8:load_rom(rom_data)
    self:load_font()
    -- load rom data to memory starting from pc location
    for i, byte in ipairs(rom_data) do
        self.memory[self.pc + i - 1] = byte
    end
end


function Chip8:next_opcode()
    local instr = self:instruction_data(false)
    self.pc = self.pc + 2
    self:opcode_switch(instr)
end


-- parse the instruction and return all necessary parts
-- chip 8 opcode are 2 bytes long and stored big-endian
function Chip8:instruction_data(debug)
    -- first, second byte that makes the instuction
    local first, second = self.memory[self.pc], self.memory[self.pc + 1]
    if debug then
        print(string.format("PC: %x Instruction %x %x", self.pc, first, second))
        print(string.format("I: %x", self.i))
        print("Stack: ")
        for i = 0, 0xF do
            print(i.." "..self.v[i])
        end
        print()
    end
    local instr = {}
    instr.first = first
    instr.nn = second
    instr.opcode = bit.bor(bit.lshift(first, 8), second)
    instr.f_nibble = bit.rshift(first, 4)
    instr.n = bit.band(second, 0x0F)
    instr.nnn = bit.band(instr.opcode, 0x0FFF)
    instr.x = bit.band(first, 0x0F)
    instr.y = bit.rshift(second, 4)
    return instr
end


function Chip8:opcode_switch(instr)
    if instr.f_nibble == 0x0 then
        if instr.x == 0x0 and instr.nn == 0xE0 then
            -- 0x00E0
            -- clear the display
            for j = 0, 31 do
                for i = 0, 63 do
                    self.display[j][i] = 0
                end
            end
        elseif instr.x == 0x0 and instr.nn == 0xEE then
            -- 0x00EE
            -- return from subroutine
            -- pop the stack
            -- not protecting the lower limit of stack
            self.sp = self.sp - 1
            self.pc = self.memory[self.sp]
        end
    elseif instr.f_nibble == 0x1 then
        -- 0x1NNN
        -- jump to address nnn
        self.pc = instr.nnn
    elseif instr.f_nibble == 0x2 then
        -- 0x2NNN
        -- execute subroutine at NNN
        -- not protecting upper limit
        self.memory[self.sp] = self.pc
        self.sp = self.pc + 1
        self.pc = instr.nnn
    elseif instr.f_nibble == 0x3 then
        -- 0x3XNN
        -- Skip the following instruction if the value of register VX equals NN
        if self.v[instr.x] == instr.nn then
            self.pc = self.pc + 2
        end
    elseif instr.f_nibble == 0x4 then
        -- 0x4XNN
        -- Skip the following instruction if the value of register VX not equals NN
        if self.v[instr.x] ~= instr.nn then
            self.pc = self.pc + 2
        end
    elseif instr.f_nibble == 0x5 and instr.n == 0 then
        -- 0x5XY0
        -- Skip the following instruction if the value of register VX is equal to the value of register VY
        if self.v[instr.x] == self.v[instr.y] then
            self.pc = self.pc + 2
        end
    elseif instr.f_nibble == 0x6 then
        -- 0x6XNN
        -- Store number NN in register VX
        self.v[instr.x] = instr.nn
    elseif instr.f_nibble == 0x7 then
        -- 0x7XNN
        -- Add the value NN to register VX
        self.v[instr.x] = (self.v[instr.x] + instr.nn) % 256
    elseif instr.f_nibble == 0x8 then
        if instr.n == 0x0 then
            -- 0x8XY0
            -- Store the value of register VY in register VX
            self.v[instr.x] = self.v[instr.y]
        elseif instr.n == 0x1 then
            -- 0x8XY1
            -- Set VX to VX OR VY
            self.v[instr.x] = bit.bor(self.v[instr.x], self.v[instr.y])
        elseif instr.n == 0x2 then
            -- 0x8XY2
            -- Set VX to VX AND VY
            self.v[instr.x] = bit.band(self.v[instr.x], self.v[instr.y])
        elseif instr.n == 0x3 then
            -- 0x8XY3
            -- Set VX to VX XOR VY
            self.v[instr.x] = bit.bxor(self.v[instr.x], self.v[instr.y])
        elseif instr.n == 0x4 then
            -- 0x8XY4
            -- Subtract the value of register VY from register VX
            -- Set VF to 01 if a carry occurs
            -- Set VF to 00 if a carry does not occur
            self.v[instr.x] = self.v[instr.x] + self.v[instr.y]
            if self.v[instr.x] > 255 then
                self.v[instr.x] = self.v[instr.x] % 256
                self.v[0xF] = 1
            else
                self.v[0xF] = 0
            end
        elseif instr.n == 0x5 then
            -- 0x8XY5
            -- Subtract the value of register VY from register VX
            -- Set VF to 00 if a borrow occurs
            -- Set VF to 01 if a borrow does not occur
            local val = self.v[instr.x] - self.v[instr.y]
            if val < 0 then
                self.v[0xF] = 0
                self.v[instr.x] = val + 256
            else
                self.v[0xF] = 1
                self.v[instr.x] = val
            end
        elseif instr.n == 0x6 then
            -- 0x8XY6
            -- Store the value of register VY shifted right one bit in register VX
            -- Set register VF to the least significant bit prior to the shift
            local lsb = bit.band(self.v[instr.x], 0x1)
            self.v[0xF] = lsb
            self.v[instr.x] = bit.rshift(self.v[instr.y], 1)
        elseif instr.n == 0x7 then
            -- 0x8XY7
            -- Set register VX to the value of VY minus VX
            -- Set VF to 00 if a borrow occurs
            -- Set VF to 01 if a borrow does not occur
            local val = self.v[instr.y] - self.v[instr.x]
            if val < 0 then
                self.v[0xF] = 0
                self.v[instr.x] = val + 256
            else
                self.v[0xF] = 1
                self.v[instr.x] = val
            end
        elseif instr.n == 0xE then
            -- 0x8XYE
            -- Store the value of register VY shifted left one bit in register VX
            -- Set register VF to the most significant bit prior to the shift
            local msb = bit.rshift(self.v[instr.x], 0x7)
            self.v[0xF] = msb
            self.v[instr.x] = bit.lshift(self.v[instr.y], 1)
        end
    elseif instr.f_nibble == 0x9 and instr.n == 0x0 then
        -- 0x9XY0
        -- Skip the following instruction if the value of register VX is not equal to the value of register VY
        if self.v[instr.x] ~= self.v[instr.y] then
            self.pc = self.pc + 2
        end
    elseif instr.f_nibble == 0xA then
        -- 0xANNN
        -- Store memory address NNN in register I
        self.i = instr.nnn
    elseif instr.f_nibble == 0xB then
        -- 0xBNNN
        -- Jump to address NNN + V0
        self.pc = instr.nnn + self.v[0x0]
    elseif instr.f_nibble == 0xC then
        -- 0xCXNN
        -- Set VX to a random number with a mask of NN
        print("Stack: ")
        for i = 0, 0xF do
            print(i.." "..self.v[i])
        end
        print()
        self.v[instr.x] = bit.band(math.random(0, 255), instr.nn)
    elseif instr.f_nibble == 0xD then
        -- 0xDXYN
        -- Draw a sprite at position VX, VY with N bytes of sprite
        -- data starting at the address stored in I
        --
        -- Set VF to 01 if any set pixels are changed to unset,
        -- and 00 otherwise
        local vx, vy = self.v[instr.x], self.v[instr.y]
        local unset = false
        for y = 0, instr.n - 1 do
            local sprite_data = self.memory[self.i + y]
            for x = 0, 7 do
                if  (vy + y) >= 32 and (vx + x) >= 64 then
                else
                    local old_bit = self.display[vy + y][vx + x]
                    local new_bit = bit.rshift(
                        bit.band(sprite_data, bit.lshift(1, 8 - x - 1)), 8 - x - 1
                    )
                    local xor = bit.bxor(old_bit, new_bit)
                    if old_bit == 1 and xor == 0 then
                        unset = true
                    end
                    self.display[vy + y][vx + x] = xor
                end
            end
        end 
        if unset then self.v[0xF] = 1
        else self.v[0xF] = 0
        end
    elseif instr.f_nibble == 0xE then
        if instr.nn == 0x9E then
            -- 0xEX9E
            -- Skip the following instruction if the key corresponding
            -- to the hex value currently stored in register VX is pressed
            if self.keys[self.v[instr.x]] then
                self.pc = self.pc + 2
            end
        elseif instr.nn == 0xA1 then
            -- 0xEXA1
            -- Skip the following instruction if the key corresponding
            -- to the hex value currently stored in register VX is not pressed
            if not self.keys[self.v[instr.x]] then
                self.pc = self.pc + 2
            end
        end
    elseif instr.f_nibble == 0xF then
        if instr.nn == 0x07 then
            -- 0xFX07
            -- Store the current value of the delay timer in register VX
            self.v[instr.x] = self.timer.delay
        elseif instr.nn == 0x0A then
            -- 0xFX0A
            -- Wait for a keypress and store the result in register VX
            local advance = false
            for i = 0, 0xF do
                if self.keys[i] then
                    advance = true
                    self.v[instr.x] = i
                end
            end
            if not advance then
                self.pc = self.pc - 2
            end
        elseif instr.nn == 0x15 then
            -- 0xFX15
            -- Set the delay timer to the value of register VX
            self.timer.delay = self.v[instr.x]
        elseif instr.nn == 0x18 then
            -- 0xFX18
            -- Set the sound timer to the value of register VX
            self.timer.sound = self.v[instr.x]
        elseif instr.nn == 0x1E then
            -- 0xFX1E
            -- Add the value stored in register VX to register I
            self.i = self.i + self.v[instr.x]
        elseif instr.nn == 0x29 then
            -- 0xFX29
            -- Set I to the memory address of the sprite data corresponding to the hexadecimal digit stored in register VX
            self.i = 5 * self.v[instr.x]
        elseif instr.nn == 0x33 then
            -- 0xFX33
            -- Store the binary-coded decimal equivalent of the value
            -- stored in register VX at addresses I, I+1, and I+2
            self.memory[self.i] = math.floor(self.v[instr.x] / 100)
            self.memory[self.i + 1] = math.floor((self.v[instr.x] % 100) / 10)
            self.memory[self.i + 2] = self.v[instr.x] % 10
        elseif instr.nn == 0x55 then
            -- 0xFX55
            --  Store the values of registers V0 to VX inclusive in memory starting at address I
            -- I is set to I + X + 1 after operation
            for i = 0, instr.x do
                self.memory[self.i + i] = self.v[i]
            end
            self.i = self.i + instr.x + 1
        elseif instr.nn == 0x65 then
            -- 0xFX65
            -- Fill registers V0 to VX inclusive with the values stored in memory starting at address I
            -- I is set to I + X + 1 after operation
            for i = 0, instr.x do
                self.v[i] = self.memory[self.i + i]
            end
            self.i = self.i + instr.x + 1
        end
    end
end


return Chip8
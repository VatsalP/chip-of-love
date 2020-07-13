local Chip8 = {}

function Chip8:new()
    local self = setmetatable({}, { __index = Chip8 , __tostring = __tostring })

    self.display = {}
    for i = 0, 63 do
        self.display[i] = {}
        for j = 0, 31 do
            self.display[i][j] = 0
        end
    end
    -- 4096 bytes of memory
    self.memory = {}
    for i = 0, 4095 do
        self.memory[i] = 0
    end
    -- chip 8 programs are loaded at location 0x200 in memory
    self.pc = 0x200
    -- stack pointer points to memory location 0xEA0
    self.sp = 0xEA0
    -- 16 8 bit data register
    self.vreg = {}
    for i = 0, 0xF do
        self.vreg[i] = 0
    end
    -- 16 bit register that points to memory
    self.i = 0
    self.timer = {
        delay = 0, sound = 0,
        count_down = function (t, dt)
            t.delay = t.delay - dt < 0 and 0 or t.delay - dt
            t.sound = t.sound - dt < 0 and 0 or t.sound - dt
        end,
    }
    return self
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
    self.len_rom = #rom_data
    self:load_font()
    -- load rom data to memory starting from pc location
    for i, byte in ipairs(rom_data) do
        self.memory[self.pc + i - 1] = byte
    end
end

function Chip8:next_opcode()
    print(string.format("PC %x - First: %x Second %x", self.pc, self.memory[self.pc], self.memory[self.pc + 1]))
    self.pc = self.pc + 2
    if self.len_rom >= self.pc then
        self:next_opcode()
    end
end


return Chip8
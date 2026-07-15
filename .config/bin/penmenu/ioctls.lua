local M = {}
local ffi = require("ffi")
ffi.cdef [[
struct input_absinfo {
    int32_t val;
    int32_t min;
    int32_t max;
    int32_t fuzz;
    int32_t flat;
    int32_t res;
};

int ioctl(int, int, ...);
]]
local IOC = function(dir, typ, nr, siz)
    return bit.bor(
        bit.lshift(dir, 30),
        bit.lshift(typ, 8),
        bit.lshift(nr, 0),
        bit.lshift(siz, 16)
    )
end

local IOC_READ = 2
local EVIOCGABS = function(axs)
    local magic = string.byte("E")
    local nr = 0x40 + axs
    local siz = ffi.sizeof("struct input_absinfo")
    return IOC(IOC_READ, magic, nr, siz)
end


M.get_axis_range = function(fd)
    local abs_x = ffi.new("struct input_absinfo")
    local abs_y = ffi.new("struct input_absinfo")
    ffi.C.ioctl(fd, EVIOCGABS(0), abs_x)
    ffi.C.ioctl(fd, EVIOCGABS(1), abs_y)

    return abs_x.max, abs_y.max
end

return M

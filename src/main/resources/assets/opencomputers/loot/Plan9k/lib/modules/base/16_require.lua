
kernel.userspace.package = {}

kernel.userspace.package.loaded = {}
kernel.userspace.package.preload = {}
kernel.userspace.package.loading = {}
kernel.userspace.package.searchers = {}

local function preloadSearcher(module)
    return kernel.userspace.package.preload[module]
end

local function pathSearcher(module)
    for dir in string.gmatch(kernel.userspace.os.getenv("LIBPATH"), "[^:$]+") do
        if dir:sub(1,1) ~= "/" then
            local dir = kernel.modules.vfs.concat(kernel.userspace.os.getenv("PWD") or "/", dir)
        end
        local file = kernel.modules.vfs.concat(dir, module .. ".lua")
        if kernel.modules.vfs.exists(file) then
            local loader, reason = kernel.userspace.loadfile(file, "bt", setmetatable({},{__index = kernel.userspace}))
            if loader then
                local state, mod = pcall(loader)
                if state then
                    return mod
                else
                    kernel.io.println("Module '" .. tostring(module) .. "' loading failed: " .. tostring(mod))
                end
            end
        end
    end
end

kernel.userspace.package.searchers[#kernel.userspace.package.searchers + 1] = preloadSearcher
kernel.userspace.package.searchers[#kernel.userspace.package.searchers + 1] = pathSearcher

--TODO: possibly wrap result into metatable
kernel.userspace.require = function(module)
    if kernel.userspace.package.loaded[module] then
        return kernel.userspace.package.loaded[module]
    else
        if kernel.userspace.package.loading[module] then
            error("Already loading "..tostring(module))
        else
            kernel.userspace.package.loading[module] = true
            for _, searcher in ipairs(kernel.userspace.package.searchers) do
                local res, mod = pcall(searcher, module)
                if res and mod then
                    kernel.userspace.package.loading[module] = nil
                    kernel.userspace.package.loaded[module] = mod
                    return mod
                elseif not res then
                    kernel.io.println("Searcher for '" .. tostring(module) .. "' loading failed: " .. tostring(mod))
                end
            end
            kernel.userspace.package.loading[module] = nil
            error("Could not load module " .. tostring(module))
        end
    end
end

function start()
    kernel.userspace.package.preload.filesystem = setmetatable({}, {__index = kernel.modules.vfs})
    kernel.userspace.package.preload.buffer = setmetatable({}, {__index = kernel.modules.buffer})
    kernel.userspace.package.preload.bit32 = setmetatable({}, {__index = kernel.userspace.bit32})
    kernel.userspace.package.preload.component = setmetatable({}, {__index = kernel.userspace.component})
    kernel.userspace.package.preload.computer = setmetatable({}, {__index = kernel.userspace.computer})
    kernel.userspace.package.preload.io = setmetatable({}, {__index = kernel.modules.io.io})
    kernel.userspace.package.preload.unicode = setmetatable({}, {__index = kernel.userspace.unicode})
end
local isWindows = tes3mp.GetOperatingSystemType() == "Windows"

return function(config)
    local function makeCmdPath(path)
        return "server/" .. path
    end

    local function makeDataPath(path)
        return "../" .. path
    end

    local function remove(path)
        local cmd = isWindows
            and string.format('rmdir /s /q "%s"', path)
            or string.format('rm -r "%s"', path)
        os.execute(cmd)
    end

    return {
        makeCmdPath = makeCmdPath,
        makeDataPath = makeDataPath,
        remove = remove
    }
end
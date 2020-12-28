return function(config, fs)
    local function getPath(url)
        local _, pos = string.find(url, "file://")
        return string.sub(url, pos + 1)
    end

    local function fetch(url)
        local path = getPath(url)
        local dataPath = fs.makeDataPath(config.manual .. path)
        local result = {
            url = url
        }
        result.file = jsonInterface.load(dataPath .. config.packageFilename)
        result.versions = { result.file.version }
        return result
    end

    local function install(url, directory, version)
        local path = getPath(url)
        local basePath = fs.makeCmdPath("")
        local sourcePath = fs.makeCmdPath(config.manual .. path)
        local installPath = fs.makeCmdPath(config.install .. directory)
        local code = os.execute(string.format(
            'cd "%s" && cp "%s" "%s"',
            basePath, sourcePath, installPath
        ))
        if code ~= 0 then
            error("Failed to install!")
        end
    end

    return {
        fetch = fetch,
        install = install
    }
end
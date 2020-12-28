return function(config, fs)
    local function urlToDirectory(url)
        local path = string.match(url, ".*/(.*)")
        path = string.gsub(path, "[/\\.]", "_")
        return path
    end

    local function split(source, separator)
        local result = {}
        local pos = 0
        local size = #source
        while pos < size do
            local found = string.find(source, separator, pos, true)
            if not found then break end
            table.insert(result, string.sub(source, pos, found - 1))
            pos = found + 1
        end
        table.insert(result, string.sub(source, pos))
        return result
    end

    local function loadPackageFileAsync(cmdPath, dataPath)
        local code = os.execute(string.format(
            'cd "%s" && git show "HEAD:%s" > "%s"',
            cmdPath, config.packageFilename, config.packageFilename
        ))
        if code ~= 0 then
            error("Failed to load the package file!")
        end

        return jsonInterface.load(dataPath .. config.packageFilename)
    end

    local function loadVersionsAsync(cmdPath, dataPath)
        local code = os.execute(string.format(
            'cd "%s" && git tags > "%s"',
            cmdPath, config.versionsFilename
        ))
        if code ~= 0 then
            error("Failed to load the versions list!")
        end

        local raw = fileDrive.LoadAsync(dataPath .. config.versionsFilename)
        return split(raw, "\n")
    end

    local function fetchAsync(url)
        local directory = urlToDirectory(url)
        local cmdPath = fs.makeCmdPath(config.paths.fetch .. directory)
        local dataPath = fs.makeDataPath(config.paths.fetch .. directory .. "/")

        os.execute(string.format( 'git clone -q -n --depth 1 "%s" "%s"', url, cmdPath ))

        local result = {
            url = url
        }
        async.WaitAllAsync({
            function() result.file = loadPackageFileAsync(cmdPath, dataPath) end,
            function() result.versions = loadVersionsAsync(cmdPath, dataPath) end
        })

        fs.remove(cmdPath)

        return result
    end

    local function install(url, directory, version)
        local cmdPath = fs.makeCmdPath(config.paths.install .. directory)
        local branchCmd = ""
        if version then
            branchCmd = string.format(' --branch "%s"', version)
        end
        local code = os.execute(string.format(
            'git clone --depth 1 -q"%s" "%s" "%s"',
            branchCmd, url, cmdPath
        ))
        if code ~= 0 then
            error("Failed to install!")
        end
    end

    return {
        fetch = fetchAsync,
        install = install
    }
end
local requirePath = string.sub(..., 1, -5)
return function(config)
    local fs = require(requirePath .. "fs")(config)
    local git = require(requirePath .. "git")(config, fs)
    local file = require(requirePath .. "file")(config, fs)

    local schemeMap = {
        ["git"] = git,
        ["file"] = file
    }
    local function resolve(url)
        local pos = string.find(url, "://", true)
        local scheme = string.sub(url, 1, pos - 1)
        local driver = schemeMap[scheme]
        if not driver then
            error("Unknown url scheme " .. scheme .. " !")
        end
        return driver
    end

    local function fetch(url)
        return resolve(url).fetch(url)
    end

    local function install(url, directory, version)
        return resolve(url).install(url, directory, version)
    end

    return {
        fetch = fetch,
        install = install
    }
end
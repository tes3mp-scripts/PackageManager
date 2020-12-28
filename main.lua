local requirePath = string.sub(..., 1, -5)

local config = {
    paths = {
        fetch = "scripts/custom/downloads/",
        install = "scripts/custom/",
        manual = "scripts/custom/",
        require = "scripts.custom."
    },
    packageFilename = "tes3mp-package.json",
    versionsFilename = "versions.txt",
}

local Version = require(requirePath .. "Version")()
local Range = require(requirePath .. "Range")(Version)
local Package = require(requirePath .. "Package")(Version, Range)
local loader = require(requirePath .. "loader/main")(config)

local function loadPackageList()
    local result = pcall(function()
        jsonInterface.load("packages.json")
    end)
    return result or {}
end

local function loadReferences(references)
    local packages = {}
    for _, ref in ipairs(references) do
        local data = loader.fetch(ref.url)
        local package = Package(data)
        packages[package.uuid] = package
    end
    return packages
end

local function missingDependencies(packages, optionals)
    optionals = optionals or false
    local dependencies = {}
    for _, p in pairs(packages) do
        local deps = p:Dependencies()
        for _, d in pairs(deps) do
            if not packages[d.uuid] and (optionals or not d.optional) then
                table.insert(dependencies, d)
            end
        end
    end
    return dependencies
end

local function orderDependencies(packages)
    local dependencyMap = {}
    for _, p in pairs(packages) do
        dependencyMap[p.uuid] = {}
        for _, d in pairs(p:Dependencies()) do
            dependencyMap[p.uuid][d.uuid] = true
        end
    end
    table.sort(packages, function(a, b)
        return dependencyMap[a.uuid][b.uuid] == nil
    end)
end

local function chooseVersions(packages)
    local ranges = {}
    local versions = {}
    for _, p in pairs(packages) do
        versions[p.uuid] = p:ChooseVersion(ranges[p.uuid]):ToString()
        for _, d in pairs(p:Dependencies()) do
            if d.version then
                local range = Range(d.version)
                if ranges[d.uuid] then range = range * ranges[d.uuid] end
                ranges[d.uuid] = range
            end
        end
    end
    return versions
end

local function installPackages(packages, versions)
    for _, p in ipairs(packages) do
        local version = versions[p.uuid]
        loader.install(p:Url(), p:InstallDirectory(), version)
    end
    return packages
end

serverCommandHooks.registerCommand("install", function()
    async.Wrap(function()
        local packages = loadReferences(loadPackageList())
        local dependencies = missingDependencies(packages)
        tableHelper.merge(packages, loadReferences(dependencies))
        orderDependencies(packages)
        installPackages(packages, chooseVersions(packages))
    end)
end)
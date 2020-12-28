return function(Version)
    local Package = class("Package")

    function Package:__init(data)
        self.data = data
        self.uuid = self.data.file.uuid
        self.versions = {}
        for _, v in pairs(self.data.versions or {}) do
            table.insert(self.versions, Version(v))
        end
        table.sort(self.versions, function(a, b)
            return a > b
        end)
    end

    function Package:InstallDirectory()
        return self.data.installFolder or self.data.name
    end

    function Package:Dependencies()
        return self.data.file.dependencies or {}
    end

    function Package:Url()
        return self.data.Url
    end

    function Package:ChooseVersion(range)
        if not range then
            return self.versions[1]
        end
        for _, v in pairs(self.versions) do
            if range:Test(v) then return v:ToString() end
        end
        return nil
    end

    function Package:Installed()
        if self.data.file.onInstall then
            return require(config.require .. self:InstallDirectory() .. "/" .. self.data.file.onInstall)
        end
    end
end
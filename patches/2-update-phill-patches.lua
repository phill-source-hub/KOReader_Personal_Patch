--[[
Self-updater for phill-source-hub/KOReader_Personal_Patch
=========================================================
Companion updater patch that checks the public
  https://github.com/phill-source-hub/KOReader_Personal_Patch
repository for updates to any of our own authored patches and/or
the locally-vendored copies of third-party patches.

This is a sibling of sebdelsol's 2-update-patches.lua — it uses the
same md5-checksum + updates.json mechanism, and deliberately adds a
SEPARATE menu entry under "More tools" so you can update each source
independently.

Adds:  More tools -> Update phill-source-hub/KOReader_Personal_Patch
]]
--
-- ============================================================================

local ok, guard = pcall(require, "patches/guard")
if ok and guard:korDoesNotMeet("v2025.04-107") then return end

local Blitbuffer = require("ffi/blitbuffer")
local ButtonDialog = require("ui/widget/buttondialog")
local CheckButton = require("ui/widget/checkbutton")
local ConfirmBox = require("ui/widget/confirmbox")
local DataStorage = require("datastorage")
local Geom = require("ui/geometry")
local InfoMessage = require("ui/widget/infomessage")
local LineWidget = require("ui/widget/linewidget")
local NetworkMgr = require("ui/network/manager")
local Size = require("ui/size")
local UIManager = require("ui/uimanager")
local Version = require("version")
local VerticalSpan = require("ui/widget/verticalspan")
local http = require("socket/http")
local json = require("json")
local lfs = require("libs/libkoreader-lfs")
local ltn12 = require("ltn12")
local md5 = require("ffi/MD5")
local userPatch = require("userpatch")
local _ = require("gettext")
local T = require("ffi/util").template
local logger = require("logger")

-- =====  CONFIG  ==============================================================
local UPDATES        = "updates.json"
local GITHUB_REPO    = "phill-source-hub/KOReader_Personal_Patch"
local REMOTE_BRANCH  = "main"
local REMOTE_SUBDIR  = "patches/"   -- where the .lua files live in the repo
local LOCAL_PATCHES  = DataStorage:getDataDir() .. "/patches/"
-- Include the icons dir so check.svg and any future ours icons can be
-- auto-refreshed too. (Optional: set to nil to disable icon syncing.)
local SYNC_ICONS_DIR = true
local LOCAL_ICONS    = DataStorage:getDataDir() .. "/icons/"
local REMOTE_ICONS_SUBDIR = "icons/"
-- =============================================================================

local ONLINE_BASE    = "https://github.com/" .. GITHUB_REPO
                    .. "/raw/refs/heads/" .. REMOTE_BRANCH .. "/"
local ONLINE_PATCHES = ONLINE_BASE .. REMOTE_SUBDIR
local ONLINE_UPDATES = ONLINE_BASE .. UPDATES  -- updates.json lives at repo root

-- HTTP helpers
local function httpRequest(options)
    local req_ok, r_val, r_code, _, r_status_str = pcall(http.request, options)
    if req_ok and r_code == 200 then return true end
    logger.err("phill-patches updater: network request failed: ",
               tostring(r_val), r_code, r_status_str)
end

local function downloadFile(url, path)
    local file, err = io.open(path, "wb")
    if file then
        local options = {
            url = url,
            method = "GET",
            headers = { ["User-Agent"] = GITHUB_REPO },
            sink = ltn12.sink.file(file),
            redirect = true,
        }
        if httpRequest(options) then return true end
        pcall(os.remove, path)
        return
    end
    logger.err("phill-patches updater: failed to open target file: ",
               err or "Unknown error")
end

-- version requirement check (reads top of each file)
local cur_kor_version = Version:getNormalizedCurrentVersion()
local function doMeetRequirement(path)
    local count = 0
    for line in io.lines(path) do
        count = count + 1
        if count > 3 then break end
        local min_ver = line:match(':korDoesNotMeet%(%"(v.+)%"%)')
        min_ver = Version:getNormalizedVersion(min_ver)
        if min_ver and cur_kor_version < min_ver then return false end
    end
    return true
end

local function sortedPairs(tbl)
    local keys = {}
    for k in pairs(tbl) do table.insert(keys, k) end
    table.sort(keys)
    local i = 0
    return function()
        i = i + 1
        local key = keys[i]
        if key ~= nil then return key, tbl[key] end
    end
end

-- ui helpers (namespaced so we don't collide with sebdelsol's 'ui')
local phill_ui = {}
function phill_ui:close()
    if self.shown then
        UIManager:close(self.shown)
        self.shown = nil
    end
end
function phill_ui:info(text)
    self:close()
    self.shown = InfoMessage:new { text = text, timeout = 5 }
    UIManager:show(self.shown)
end
function phill_ui:process(func, text)
    self:close()
    self.shown = InfoMessage:new { text = text, dismissable = false }
    UIManager:show(self.shown)
    UIManager:scheduleIn(0.1, func)
end
function phill_ui:confirm(options)
    self:close()
    local params = {
        text = options.text,
        no_ok_button = options.one_button,
    }
    params[options.one_button and "cancel_text" or "ok_text"] = options.ok
    params[options.one_button and "cancel_callback" or "ok_callback"] = options.callback
    self.shown = ConfirmBox:new(params)
    UIManager:show(self.shown)
end
function phill_ui:confirmCheckList(options)
    self:close()
    self.shown = ButtonDialog:new {
        title = options.title,
        buttons = {
            {
                { text = _("Cancel"),
                  callback = function() self.shown:onClose() end },
                { text = options.ok_text,
                  callback = function()
                      self.shown:onClose()
                      options.ok_callback()
                  end },
            },
        },
    }
    self.shown:addWidget(LineWidget:new{
        dimen = Geom:new{
            w = self.shown.width - 2 * (Size.border.window + Size.padding.button),
            h = Size.line.medium,
        },
        background = Blitbuffer.COLOR_GRAY,
    })
    self.shown:addWidget(VerticalSpan:new{ width = Size.padding.default })
    for _, check in ipairs(options.checks or {}) do
        check.parent = self.shown
        self.shown:addWidget(CheckButton:new(check))
    end
    UIManager:show(self.shown)
end

-- file helpers
local function isFile(path) return lfs.attributes(path, "mode") == "file" end
local function isDir(path)  return lfs.attributes(path, "mode") == "directory" end
local function copy(src, dst) return os.execute('cp -vf "' .. src .. '" "' .. dst .. '"') == 0 end
local function remove(path)  return os.execute('rm -vf "' .. path .. '"') == 0 end

-- ota
local ota = {
    local_updates  = LOCAL_PATCHES .. UPDATES .. ".phill",  -- separate file so sebdelsol's manifest is not overwritten
    online_updates = ONLINE_UPDATES,
}

function ota:checkUpdates()
    if downloadFile(self.online_updates, self.local_updates) then
        local f = io.open(self.local_updates, "r")
        if f then
            local ok2, updates = pcall(json.decode, f:read("*a"))
            f:close()
            return ok2 and updates
        end
    end
end

function ota:targetDir(name)
    if name:match("%.svg$") and SYNC_ICONS_DIR then
        return LOCAL_ICONS, REMOTE_ICONS_SUBDIR
    end
    return LOCAL_PATCHES, REMOTE_SUBDIR
end

function ota:install(name, md5sum)
    local dir, remote_subdir = self:targetDir(name)
    local file = dir .. name
    local install = {
        name      = name,
        installed = false,
        skip      = false,
        exists    = isFile(file),
    }
    function install.isNew()
        return (not install.exists) or (md5.sumFile(file) ~= md5sum)
    end
    function install.apply()
        if install.skip then return end
        local url = ONLINE_BASE .. remote_subdir .. name
        local new_file = file .. ".new"
        -- Ensure target dir exists (covers /icons/ on first run)
        if not isDir(dir) then
            os.execute('mkdir -p "' .. dir .. '"')
        end
        if downloadFile(url, new_file) then
            if md5.sumFile(new_file) == md5sum and doMeetRequirement(new_file) then
                if install.exists then
                    copy(file, file .. ".old")
                end
                install.installed = copy(new_file, file)
            end
            remove(new_file)
        end
    end
    return install
end

function ota:getInstalls(updates)
    local installs = {}
    for name, md5sum in sortedPairs(updates) do
        local inst = self:install(name, md5sum)
        if inst.isNew() then table.insert(installs, inst) end
    end
    function installs.apply()
        for _, i in ipairs(installs) do
            if not i.skip then i.apply() end
        end
    end
    function installs.checks()
        local checks = {}
        for _, i in ipairs(installs) do
            i.skip = not i.exists
            table.insert(checks, {
                text = i.name,
                checked = not i.skip,
                callback = function() i.skip = not i.skip end,
            })
        end
        return checks
    end
    function installs.text(installed)
        local t = {}
        for _, i in ipairs(installs) do
            if not i.skip and i.installed == installed then
                table.insert(t, "\n · " .. i.name)
            end
        end
        return table.concat(t)
    end
    function installs.empty(installed)
        for _, i in ipairs(installs) do
            if not i.skip and i.installed == installed then return false end
        end
        return true
    end
    return installs
end

function ota:_update()
    local function _update()
        local updates = self:checkUpdates()
        if not updates then
            phill_ui:info(_("Can't download phill-source-hub updates"))
            return
        end
        local installs = self:getInstalls(updates)
        if installs.empty(false) then
            phill_ui:info(_("No phill-source-hub updates found"))
            return
        end
        local function _install()
            installs.apply()
            local texts = {}
            if not installs.empty(false) then
                table.insert(texts, _("Patches that failed to update:") .. installs.text(false))
            end
            if not installs.empty(true) then
                table.insert(texts, _("Patches updated:") .. installs.text(true))
            end
            phill_ui:confirm {
                text = table.concat(texts, "\n"),
                ok = _("OK"),
                one_button = true,
                callback = function()
                    if not installs.empty(true) then
                        UIManager:askForRestart(_("You need to restart!"))
                    end
                end,
            }
        end
        phill_ui:confirmCheckList {
            title = _("Personal patch updates available:"),
            checks = installs.checks(),
            ok_text = _("Update"),
            ok_callback = function()
                if not installs.empty(false) then
                    phill_ui:process(_install, _("Update patches:") .. installs.text(false))
                end
            end,
        }
    end
    phill_ui:process(_update, _("Check for personal patch updates..."))
end

function ota:update()
    if not isDir(LOCAL_PATCHES) then
        phill_ui:info(_("You have no patches folder."))
        return
    end
    if NetworkMgr:isOnline() then
        self:_update()
    else
        phill_ui:confirm {
            text = "Would you like to turn Wi-fi on ?",
            ok = _("Wi-fi on"),
            callback = function()
                NetworkMgr:turnOnWifiAndWaitForConnection(function() self:_update() end)
            end,
        }
    end
end

function ota:menu()
    return {
        text = T(_("Update %1"), GITHUB_REPO),
        callback = function() self:update() end,
    }
end

-- menu integration (new entry with distinct key so sebdelsol's isn't clobbered)
local FileManagerMenu = require("apps/filemanager/filemanagermenu")
local ReaderMenu      = require("apps/reader/modules/readermenu")
local function patch(menu, order)
    table.insert(order.more_tools, "----------------------------")
    table.insert(order.more_tools, "patch_update_phill")
    menu.menu_items.patch_update_phill = ota:menu()
end
local orig_FM = FileManagerMenu.setUpdateItemTable
function FileManagerMenu:setUpdateItemTable()
    patch(self, require("ui/elements/filemanager_menu_order"))
    orig_FM(self)
end
local orig_RM = ReaderMenu.setUpdateItemTable
function ReaderMenu:setUpdateItemTable()
    patch(self, require("ui/elements/reader_menu_order"))
    orig_RM(self)
end

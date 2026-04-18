--[[
Finished-book checkmark
=======================
Marks books that are 100% read with a small check icon at the bottom-right
of the cover in the Cover Grid.

Rework of the original "minimalist trophy" patch from
https://www.reddit.com/r/koreader/comments/1op2mrq/my_minimalistic_setup/
with these changes for our combined setup:

  - Uses our own /koreader/icons/check.svg (shipped alongside this patch)
  - Uses target.dimen (not target.width/height) to match SH's patch
    conventions, so we position correctly regardless of whether
    2--stretched-rounded-covers has resized the inner image widget
  - Hoists `require` calls out of the paint hot path
  - Sets show_progress_bar = false / been_opened = false on finished
    books as belt-and-braces so any other overlay gets suppressed

Load order:
  This file is named 2-z-... so it sorts AFTER 2-new-progress-bar.lua
  and AFTER 2--stretched-rounded-covers.lua, guaranteeing our paintTo
  wraps theirs (i.e. we draw on top of them). 20-faded-finished-books.lua
  still runs last and dims the whole cover including our checkmark —
  that's intentional: on finished books you see a dimmed cover with a
  crisp check in the corner.
]]
--
-- ============================================================================
-- Config
-- ============================================================================
local show_finished_check_in_corner = true
local icon_size_px                  = 16   -- base size, scaled by screen DPI
local corner_inset_px               = 1    -- nudge inward from the cover edge
-- ============================================================================

local userpatch      = require("userpatch")
local logger         = require("logger")
local FrameContainer = require("ui/widget/container/framecontainer")
local Blitbuffer     = require("ffi/blitbuffer")
local ImageWidget    = require("ui/widget/imagewidget")
local DataStorage    = require("datastorage")
local Device         = require("device")
local Screen         = Device.screen

local CHECK_PATH = DataStorage:getDataDir() .. "/icons/check.svg"

local function patchFinishedCheckmark(plugin)
    local MosaicMenu = require("mosaicmenu")
    local MosaicMenuItem = userpatch.getUpValue(MosaicMenu._updateItemsBuildUI, "MosaicMenuItem")

    if not MosaicMenuItem then
        logger.warn("2-z-finished-checkmark: MosaicMenuItem not found; is ProjectTitle loaded?")
        return
    end

    if MosaicMenuItem.patched_finished_checkmark then
        return
    end
    MosaicMenuItem.patched_finished_checkmark = true

    local status_icon_size = Screen:scaleBySize(icon_size_px)
    local inset = Screen:scaleBySize(corner_inset_px)
    local orig_MosaicMenuItem_paintTo = MosaicMenuItem.paintTo

    MosaicMenuItem.paintTo = function(self, bb, x, y)
        local is_finished = (self.status == "complete") or (self.percent_finished == 1)

        -- Belt-and-braces: suppress any other finished-book overlays
        -- (we want just the dimmed cover + our check, nothing else)
        if is_finished then
            self.show_progress_bar = false
            self.been_opened = false
        end

        orig_MosaicMenuItem_paintTo(self, bb, x, y)

        if not (show_finished_check_in_corner and is_finished) then
            return
        end

        -- Find the cover-frame widget the same way SH's patches do:
        -- self[1][1][1] is the inner cover frame, and its .dimen gives us
        -- the actual painted size (after 2:3 stretching, rounded corners etc).
        local target = self[1] and self[1][1] and self[1][1][1]
        if not (target and target.dimen) then
            return
        end

        local tw, th = target.dimen.w, target.dimen.h
        -- Outer item position → inner cover position (cover is centered in item cell)
        local fx = x + math.floor((self.width  - tw) / 2)
        local fy = y + math.floor((self.height - th) / 2)
        -- Bottom-right of the cover, nudged in by `inset`
        local pos_x = fx + tw - status_icon_size - inset
        local pos_y = fy + th - status_icon_size - inset

        local finished_img = FrameContainer:new{
            radius     = 0,
            bordersize = 0,
            padding    = 0,
            margin     = 0,
            background = Blitbuffer.COLOR_TRANSPARENT,
            ImageWidget:new{
                file                   = CHECK_PATH,
                alpha                  = true,
                width                  = status_icon_size,
                height                 = status_icon_size,
                scale_factor           = 0,
                original_in_nightmode  = false,
            },
        }
        finished_img:paintTo(bb, pos_x, pos_y)
    end
end

userpatch.registerPatchPluginFunc("coverbrowser", patchFinishedCheckmark)

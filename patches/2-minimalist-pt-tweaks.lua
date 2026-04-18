--[[
Minimalist Project: Title tweaks
================================
Replaces the plugin-file-drop approach from the r/koreader minimalist
setup with a proper user-patch that survives ProjectTitle updates.

In the upstream ProjectTitle code, three visual divider elements are
drawn in the Cover Grid:

  1. A thick black line under the top-bar icons
     (drawn by mosaicmenu.lua line ~1294: `ptutil.mediumBlackLine(...)`)

  2. Thin grey lines between rows of books
     (drawn by mosaicmenu.lua line ~1354 etc.: `ptutil.thinGrayLine(...)`)

  3. A thick black line above the footer
     (drawn by covermenu.lua line ~724: `ptutil.mediumBlackLine(...)`)

Items (1) and (3) share the same helper function, so hiding one hides
both — which is exactly what the minimalist aesthetic wants.

Item (2) also has variants for "recent items" highlighting
(`ptutil.thinBlackLine`) and a last-row special case
(`ptutil.thinWhiteLine`). We swap the visible variants to point to the
already-invisible whiteLine so layout height is preserved and the grid
math in `_recalculateDimen` still works correctly.

Source of inspiration:
  https://www.reddit.com/r/koreader/comments/1op2mrq/my_minimalistic_setup/

The "removed cover borders" and "2:3 stretched covers" aspects of the
original minimalist setup are handled by:
  - 2--disable-all-PT-widgets.lua  (border removal)
  - 2--stretched-rounded-covers.lua (2:3 stretch + rounded corners)
--]]
--
-- ============================================================================
-- Toggle each feature independently (set to false to keep the line visible)
-- ============================================================================
local hide_thick_black_lines = true  -- the top + footer thick black lines
local hide_thin_row_lines    = true  -- the dividers between rows of books
-- ============================================================================

local userpatch = require("userpatch")
local logger = require("logger")

local function patchMinimalistTweaks(plugin)
    local ok, ptutil = pcall(require, "ptutil")
    if not (ok and ptutil) then
        logger.warn("2-minimalist-pt-tweaks: ptutil not loadable — is ProjectTitle active?")
        return
    end

    if ptutil.patched_minimalist_lines then
        -- Idempotent: a second pass through would double-wrap and break ordering
        return
    end
    ptutil.patched_minimalist_lines = true

    ------------------------------------------------------------
    -- 1 & 3. Hide the thick black line at top-of-grid and above-footer
    ------------------------------------------------------------
    if hide_thick_black_lines and ptutil.mediumBlackLine then
        local LineWidget  = require("ui/widget/linewidget")
        local Size        = require("ui/size")
        local Blitbuffer  = require("ffi/blitbuffer")
        local Geom        = require("ui/geometry")
        -- Keep the same height as the original to preserve layout math
        local med_h = (Size.line and Size.line.medium)
                   or (Size.line and Size.line.thin)
                   or 1
        ptutil.mediumBlackLine = function(width)
            return LineWidget:new{
                dimen      = Geom:new{ w = width, h = med_h },
                background = Blitbuffer.COLOR_WHITE,
            }
        end
        logger.info("2-minimalist-pt-tweaks: thick black lines (top + footer) hidden")
    end

    ------------------------------------------------------------
    -- 2. Hide the thin grey (and recent-item black) row dividers
    ------------------------------------------------------------
    -- thinWhiteLine is already-invisible. We alias the visible variants
    -- to it so the height contribution stays identical.
    if hide_thin_row_lines and ptutil.thinWhiteLine then
        if ptutil.thinGrayLine then
            ptutil.thinGrayLine = ptutil.thinWhiteLine
        end
        if ptutil.thinBlackLine then
            ptutil.thinBlackLine = ptutil.thinWhiteLine
        end
        logger.info("2-minimalist-pt-tweaks: row separator lines hidden")
    elseif hide_thin_row_lines then
        logger.warn("2-minimalist-pt-tweaks: ptutil.thinWhiteLine not found — cannot hide row lines")
    end
end

userpatch.registerPatchPluginFunc("coverbrowser", patchMinimalistTweaks)

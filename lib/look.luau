-- SPDX-License-Identifier: GPL-2.0-only
-- Regionativo: a drafting sheet as a bar. Overrides on top of default/lib/skin.luau; every widget
-- not styled here falls back to Default.
--
-- The site's rules, carried over:
--   * a drafting sheet: square corners, strong rules, a title block of cells divided by lines
--   * Anton for headlines (workspace names, the clock, panel headings), uppercase
--   * JetBrains Mono for annotations and numbers, Inter for everything you read
--   * colour is flat and rare: one solid purple block for where you are, orange for "now"

local HEAVY = "Anton"
local SANS = "Inter"
local MONO = "JetBrains Mono"
local HOVER = "foreground/0.08"
local BASE = 38

-- Uppercase ASCII letters only: safe for any UTF-8 (accents, "·", CJK pass through untouched).
local function caps(text: string): string
    return (string.gsub(text, "%l", string.upper))
end

local function scale(ctx): number
    return ctx.data.bar.style.height / BASE
end

local function text(props)
    if props.color == nil and props.role == "secondary" then
        props.color = "secondaryForeground"
    end
    props.role = nil
    if props.font == nil then
        if props.style == "mono" then
            props.font = MONO
        elseif props.style == nil or props.style == "body" or props.style == "bold" or props.style == "small"
            or props.style == "rounded" or props.style == "caption" then
            props.font = SANS
            if props.style == "bold" and props.weight == nil then
                props.weight = "semibold"
            end
        end
    end
    if props.font ~= nil then
        props.style = nil
    end
    return ui.text(props)
end

-- A small mono annotation, like the site's "SPINE HEIGHT = PAGE COUNT" labels.
local function note(label: string, size: number, color: string?)
    return ui.text{ text = caps(label), font = MONO, size = size, weight = "medium", color = color or "secondaryForeground" }
end

-- Title-block cell: each bar item is a cell, separated from the previous one by a rule.
local function bar(ctx, props)
    local style = ctx.data.bar.style
    local s = scale(ctx)
    local size = style.height - 6
    props.gap = props.gap or 6 * s
    props.pad = props.pad or 6 * s
    props.radius = 0
    if props.onClick or props.onRightClick then
        props.hover = props.hover or HOVER
    end
    if props.symbol then
        table.insert(props, 1, ui.symbol{ name = props.symbol, size = 13 * s, weight = "medium",
            color = props.tint or "foreground" })
    end
    props.symbol, props.tint, props.hue, props.joined = nil, nil, nil, nil
    if style.vertical then
        props.w = props.w or size
        return ui.column(props)
    end
    props.h = props.h or size
    return ui.row(props)
end

-- The popout window rounds its own corners, so a square outline can't sit on the edge.
-- Instead the frame is inset, like the border line of a drawing sheet.
local function panel(props)
    props.pad = props.pad or 16
    props.gap = props.gap or 12
    props.radius = 0
    props.border = "border"
    props.borderWidth = 1.5
    props.center = false
    return ui.column{ pad = 7, gap = 0, radius = 14, material = "clear", fill = "background", center = false,
        ui.column(props) }
end

-- A title-block cell, like the site's "53 / DAYS LEFT THIS YEAR": a mono label over an
-- Anton value, with a rule on its leading edge. `value` is text or an element.
local function cell(ctx, label: string, value, color: string?, labelColor: string?, reserve: string?)
    local style = ctx.data.bar.style
    local s = scale(ctx)
    local h = style.height - 6
    local shown = if type(value) == "string"
        then ui.text{ text = caps(value), font = HEAVY, size = 17 * s, color = color or "foreground", reserve = reserve }
        else value
    return ui.row{ h = h, gap = 0, hover = HOVER,
        ui.box{ w = 1, h = h * 0.62, fill = "border/0.4" },
        ui.box{ w = 8 * s, h = 1 },
        ui.column{ gap = 0, center = true, -- label and value centred in the cell
            ui.text{ text = caps(label), font = MONO, size = 8.5 * s, weight = "semibold",
                color = labelColor or "secondaryForeground" },
            ui.row{ h = 20 * s, gap = 0, shown } }, -- fixed value line: labels align across cells
        ui.box{ w = 8 * s, h = 1 } }
end

-- One colour rule for every level: purple = good/calm, amber = middling,
-- orange = needs attention, red = critical. `good` says which end of 0..100 is good.
local function ramp(value: number, good: "high" | "low"): string
    local v = if good == "high" then value else 100 - value
    if v >= 60 then return "purple" end
    if v >= 35 then return "yellow" end
    if v >= 15 then return "accent" end
    return "red"
end

-- Signal as a little row of book spines (the site's bookshelf), lit up to `level` of 4.
local function spines(ctx, level: number, color: string)
    local s = scale(ctx)
    local row = { gap = 2 * s, h = 15 * s }
    for i = 1, 4 do
        row[#row + 1] = ui.stack{ w = 3.5 * s, h = 15 * s,
            ui.box{ align = "bottom", w = 3.5 * s, h = (4 + i * 2.75) * s,
                fill = if i <= level then color else "foreground/0.18" } }
    end
    return ui.row(row)
end

-- "BOOKS" with a rule under it.
local function heading(label: string, width: number?)
    local w = width or 280
    return ui.column{ w = w, gap = 6, center = false,
        ui.text{ text = caps(label), font = HEAVY, size = 22, color = "foreground" },
        ui.box{ w = w, h = 1.5, fill = "border" } }
end

local function button(name: string, action, props)
    props = props or {}
    local color = props.color
    props.color = nil
    props.w = props.w or 28
    props.h = props.h or 28
    props.radius = 0
    props.border = props.border or "border/0.7"
    props.borderWidth = props.borderWidth or 1.5
    props.hover = props.hover or HOVER
    props.onClick = action
    props[#props + 1] = ui.symbol{ name = name, size = 12, weight = "semibold", color = color or "foreground" }
    return ui.stack(props)
end

return require("./skin")({
    base = BASE,
    hover = HOVER,
    hiddenBarHover = "accent/0.15",
    width = 320,
    size = { text = 13, small = 11, symbol = 14, icon = 24, slot = 28, time = 13, glyph = 17 },
    radius = function()
        return 0
    end,
    text = text,
    bar = bar,
    panel = function(_, props)
        return panel(props)
    end,
    group = function(props)
        props.pad = props.pad or 12
        props.gap = props.gap or 8
        props.radius = 0
        props.fill = props.fill or nil
        props.border = props.border or "border/0.45"
        props.borderWidth = props.borderWidth or 1
        props.center = false
        return ui.column(props)
    end,
    heading = heading,
    section = function(label: string, width: number?)
        return ui.row{ w = width, note(label, 10.5) }
    end,
    button = button,
    primaryButton = { w = 34, h = 34, radius = 0, fill = "accent", color = "accentForeground" },

    -- Widgets can ask the style for a chip (look.chip): here a plain
    -- cell glyph in its hue, no tile, so it sits in the title block like everything else.
    chip = function(ctx, o)
        if o.label then
            return cell(ctx, o.label, o.value or "", if o.quiet then "secondaryForeground" else o.hue)
        end
        local size = o.size or (ctx.data.bar.style.height - 6)
        return ui.stack{ w = size, h = size,
            ui.symbol{ name = o.symbol, size = math.floor(size * 0.48), weight = "semibold",
                color = if o.quiet then "secondaryForeground" else o.hue } }
    end,

    -- 22:41 in Anton, the date as a mono annotation.
    clockBar = function(ctx, m)
        if ctx.data.bar.style.vertical then
            return nil
        end
        local s = scale(ctx)
        local row = { gap = 8 * s, hover = HOVER }
        if m.showDate then
            row[#row + 1] = note(m.date, 10.5 * s)
        end
        row[#row + 1] = ui.text{ text = caps(m.time), font = HEAVY, size = 20 * s, color = "foreground",
            reserve = "00:00 PM" }
        return bar(ctx, row)
    end,

    activeWindowBar = function(ctx, m)
        local s = scale(ctx)
        local item = { gap = 7 * s, hover = HOVER }
        if m.showIcon then
            item[#item + 1] = ui.icon{ app = m.bundle, w = 16 * s, h = 16 * s, placeholder = "app.dashed" }
        end
        if m.showText then
            item[#item + 1] = note(m.app or "", 10 * s, "accent")
            if m.title and m.title ~= "" and m.title ~= m.app then
                item[#item + 1] = text{ text = m.title, size = 12.5 * s, weight = "medium",
                    color = "foreground", maxWidth = m.maxWidth }
            end
        end
        return bar(ctx, item)
    end,

    -- Control Center: a dark rounded tile with a menu mark; the middle bar is orange and
    -- shorter, like the rule under a heading.
    controlCenterBar = function(ctx)
        local s = scale(ctx)
        local h = ctx.data.bar.style.height - 6
        local size = math.round(26 * s)
        local u = size / 64
        local function bar(y, w, color)
            return ui.box{ align = "topLeading", dx = 16 * u, dy = y * u, w = w * u, h = 6 * u, fill = color }
        end
        return ui.row{ h = h, gap = 0,
            ui.box{ w = 6 * s, h = 1 },
            ui.stack{ w = size, h = size, radius = 14 * u, fill = "#1D1C1AFF", border = "border/0.35",
                borderWidth = 1, hoverOpacity = 0.85,
                bar(19, 32, "#FBFAF7FF"), bar(29, 22, "orange"), bar(39, 32, "#FBFAF7FF") },
            ui.box{ w = 6 * s, h = 1 } }
    end,
    wifiBar = function(ctx, state)
        if not state.power then
            return cell(ctx, "Wi-Fi", "Off", "mutedForeground")
        end
        if not state.connected then
            return cell(ctx, "Wi-Fi", "—", "accent")
        end
        local level = math.clamp(state.level or 0, 0, 4)
        return cell(ctx, "Wi-Fi", spines(ctx, level, ramp(level * 25, "high")))
    end,
    -- Bluetooth: just the radio. ON in purple, OFF in red (device count lives in the panel).
    bluetoothBar = function(ctx, state)
        if state.granted and not state.power then
            return cell(ctx, "BT", "Off", "red")
        end
        return cell(ctx, "BT", "On", "purple")
    end,
    -- Privacy (only shown while something records): a cell naming what is live, red for the
    -- camera, orange for the microphone alone.
    privacyBar = function(ctx, m)
        local cam, mic = false, false
        for _, indicator in m.indicators do
            if indicator.key == "camera" then cam = true elseif indicator.key == "microphone" then mic = true end
        end
        local label = if cam and mic then "Cam+Mic" elseif cam then "Cam" else "Mic"
        local color = if cam then "red" else "accent"
        return cell(ctx, label, "On", color, color)
    end,
    volumeBar = function(ctx, m)
        if not m.volume then
            return cell(ctx, "Vol", "—", "mutedForeground")
        end
        if m.muted then
            return cell(ctx, "Vol", "Mute", "accent", "accent")
        end
        -- loudness: quiet is calm (purple), very loud is red
        return cell(ctx, "Vol", tostring(m.volume), ramp(m.volume, "low"), nil, "88")
    end,
    batteryBar = function(ctx, state)
        local label = if state.charging then "Pwr +" else "Pwr"
        return cell(ctx, label, state.text, ramp(state.level, "high"), if state.charging then "purple" else nil, "100")
    end,
    batteryDetailsBar = function(ctx, state)
        local label = if state.charging then "Pwr +" else "Pwr"
        return cell(ctx, label, state.text, ramp(state.level, "high"), if state.charging then "purple" else nil, "100")
    end,
    -- System stats: the frame's first child is replaced by the widget's glyph, so it is hidden
    -- and the cell carries live CPU instead.
    systemStatsButton = function(ctx, glyph)
        glyph.size, glyph.w, glyph.h, glyph.opacity = 1, 0, 0, 0
        local cpu = ctx.data.cpu
        -- fixed width ("88%" is the widest two-digit value in Anton): no jump from 9% to 10%
        local c = cell(ctx, "CPU", if cpu then tostring(math.round(cpu)) .. "%" else "—",
            if cpu then ramp(cpu, "low") else "foreground", nil, "88%")
        return { gap = 0, ui.box{ w = 0, h = 0 }, c }
    end,

    -- Workspaces read like the site's REVISION HISTORY: the current one is the solid
    -- purple RELEASED block, the others are plain Anton, empty ones are struck through in orange.
    workspaceMarker = function(ctx, workspace, style, m, occupied)
        if m.indicator == "dots" or (m.compact and not style.labels) then
            return nil
        end
        local s = m.scale
        local label = ui.text{ text = caps(workspace.name), font = HEAVY, size = 17 * s,
            color = if workspace.focused then "#EFE9DCFF" else "mutedForeground" }
        if not occupied and not workspace.focused then
            label.opacity = 0.55
            return ui.stack{ label, ui.box{ w = 1, h = 1.5, fill = "accent", grow = 1 } }
        end
        return label
    end,
    -- The active workspace is one solid purple block (name and its apps). The others step
    -- back through their muted names only: app icons stay at full strength so similar
    -- icons remain tellable apart.
    workspacePill = function(pill, workspace, style, m, occupied)
        pill.radius = 5 * m.scale  -- soft corners on the purple block (and the hover fill)
        pill.border = nil
        if workspace.focused then
            pill.fill = "indigo"
            pill.hover = nil
            pill.opacity = 1
        else
            pill.fill = nil
            pill.hover = HOVER
            pill.opacity = 1
        end
        -- A Dock-like lift under the pointer. Paint-only (neighbours don't move) and
        -- kept small: the bar window clips anything taller than the bar.
        pill.hoverScale = 1.15
        pill.hoverAnimate = "spring"
    end,
    -- The focused window's icon: OmniWM marks it with a glow (accent at 50%, which goes
    -- lavender over the purple block), set after windowIcon and workspacePill run. Once the
    -- pills are built, swap the glow for a short orange rule under the icon, like the rule
    -- under a heading. Returns nil: the stock layout is kept.
    workspaceGroup = function(ctx, pills, cells, style, m)
        local s = m.scale
        local function mark(node)
            local hit = false
            for _, child in ipairs(node) do
                if type(child) == "table" then
                    if child.shadow ~= nil and child.shadowRadius ~= nil then
                        child.shadow = nil
                        child.shadowRadius = nil
                        hit = true
                    else
                        mark(child)
                    end
                end
            end
            if hit then
                -- a short orange rule under the icon, nearly its full width
                local h = math.max(2, math.round(2.5 * s))
                node[#node + 1] = ui.box{ align = "bottom", dy = 0,
                    w = math.round(m.icon * 0.85), h = h, radius = h / 2, fill = "orange" }
            end
        end
        mark(pills)
        return nil
    end,
    -- App icons inside a workspace take the hover before the pill does, so they get the same
    -- lift on their own (Default: 1.05).
    windowIcon = function(icon, glyph, item, style, m)
        icon.hoverScale = 1.12
        icon.hoverAnimate = "spring"
    end,
    -- Floating windows: the stock marker is a thin grey SF symbol. Here it is two overlapping
    -- rounded squares in the style's muted cream, the front one solid-edged, sized to sit with
    -- the app icons that follow it.
    floatingGroup = function(icons, style, m)
        local s = m.scale
        local size = math.round(m.icon * 0.42)
        local edge = math.max(1.5, 1.5 * s)
        local off = math.round(size * 0.35)
        local marker = ui.stack{ w = size + off, h = size + off,
            ui.box{ align = "topTrailing", w = size, h = size, radius = 3 * s,
                border = "mutedForeground", borderWidth = edge },
            ui.box{ align = "bottomLeading", w = size, h = size, radius = 3 * s,
                fill = "background", border = "secondaryForeground", borderWidth = edge } }
        local gap = math.round(3 * s)
        local row = { gap = gap, ui.box{ w = 2 * s, h = 1 }, marker }
        for _, icon in ipairs(icons) do
            row[#row + 1] = icon
        end
        return ui.row(row), 2 * s + size + off + #icons * m.slot + (#icons + 1) * gap
    end,
    countBadge = function(label)
        return ui.row{ h = 13, fill = "accent",
            ui.box{ w = 3, h = 1 },
            ui.text{ text = label, font = MONO, size = 9.5, weight = "bold", color = "accentForeground" },
            ui.box{ w = 3, h = 1 } }
    end,

    -- Sound panel: Default's content (it brings its own SOUND heading) plus a MICROPHONE box
    -- drawn like the content's own boxed sections.
    audioPanel = function(ctx, m)
        local audio = require("./audio")
        local props = { w = 348, audio.content(ctx, 320, m) }
        local mic = require("./mic").content(ctx, 296)
        if mic then
            props[#props + 1] = ui.column{ w = 320, pad = 12, gap = 10, radius = 0, center = false,
                border = "border/0.45", borderWidth = 1, heading("Microphone", 296), mic }
        end
        return panel(props)
    end,
})

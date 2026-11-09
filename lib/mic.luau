-- Microphone controls for a sound panel: state, input level slider and mute.
-- Uses OmniWM's built-in `microphone set <0-100>` / `microphone mute` commands.
-- Regio draws its own version inside its audio panel; other styles use this.
local look = require("./look")

local mic = {}

function mic.content(ctx, width: number)
    local data = ctx.data.microphone
    if not data or (data.muted == nil and data.volume == nil) then
        return nil
    end
    local live = not data.muted and (ctx.data.privacy or {}).microphone == true
    local tone = if data.muted then "error" elseif live then "accent" else "secondaryForeground"
    local header = { w = width, gap = 10,
        look.glyph{ name = if data.muted then "mic.slash.fill" else "mic.fill", w = 18, h = 16, color = tone },
        ui.column{ gap = 1, center = false, grow = 1,
            look.text{ text = "Microphone", size = 13, weight = "semibold" },
            look.text{ text = if data.muted then "Muted" elseif live then "In use" else "On", size = 11, color = tone } } }
    if data.volume then
        header[#header + 1] = look.text{ text = ctx.format.percent(data.volume / 100), style = "mono", size = 12,
            color = if data.muted then "mutedForeground" else "foreground", reserve = ctx.format.percent(1) }
    end
    if data.muted ~= nil then
        header[#header + 1] = look.button(if data.muted then "mic.slash.fill" else "mic.fill", "microphone mute",
            { help = if data.muted then "Unmute microphone" else "Mute microphone", color = tone })
    end
    local rows = { w = width, gap = 8, center = false, ui.row(header) }
    if data.volume then
        rows[#rows + 1] = ui.slider{ value = data.volume / 100, w = width, h = 16,
            color = if data.muted then "mutedForeground" else "accent",
            onChange = function(_, event)
                if event.value then
                    omniwm.run(string.format("microphone set %d", math.round(event.value * 100)))
                end
            end }
    end
    return ui.column(rows)
end

return table.freeze(mic)

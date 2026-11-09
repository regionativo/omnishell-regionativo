-- SPDX-License-Identifier: GPL-2.0-only
local look = require("./look")
local presentation = require("./notification-presentation")

return presentation({
    scale = look.scale,
    bar = look.bar,
    hover = look.hover,
    buttonRadius = 0,
    text = function(props)
        props.size = props.size or (if props.style == "small" then 11 else 13)
        props.weight = props.weight or (if props.style == "bold" then "semibold" else nil)
        props.style = nil
        return look.text(props)
    end,
    group = look.group,
    panel = look.panel,
})

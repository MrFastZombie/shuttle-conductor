local default = data.raw["gui-style"].default

default["shuttle-conductor-main-frame"] = {
    type = "frame_style",
    parent = "frame",
    minimal_height=256,
    maximal_height=2048,
    width = 385,
    natural_height = 256, --Make sure to use natural height when defining stretchaable elements.
    vertically_stretchable = "on",
    horizontally_stretchable = "off"
}

default["shuttle-conductor-main-vflow"] = { --I probably don't need this one anymore
    type="vertical_flow_style",
    parent="vertical_flow",
    minimal_height=32,
    natural_height=32,
    vertically_stretchable="on"
}

default["shuttle-conductor-scroll-frame"] = {
    type="scroll_pane_style",
    parent="scroll_pane_in_shallow_frame",
    height=335,
    frame_style = {
        type="frame_style",
        parent="deep_frame_in_shallow_frame",
        vertically_stretchable="off"
    }
}

default["shuttle-conductor-button-container"] = {
    type="frame_style",
    parent="deep_frame_in_shallow_frame",
    natural_height=324,
    vertically_stretchable="on",
    horizontally_stretchable="on"
}

default["shuttle-conductor-station-button"] = {
    type = "button_style",
    parent = "button",
    horizontally_stretchable = "on",
    horizontally_squashable = "on",
    left_padding = 16,
    right_padding = 16,
    maximal_width = 337,
    minimal_width = 317
}

default["shuttle-conductor-search"] = {
    type="textbox_style",
    parent = "textbox",
    horizontally_stretchable = "on",
    maximal_width = 1000,
    vertical_align="center", --This is not working :(
    --vertically_stretchable="on",
    top_margin=6 --This centers the search bar vertically.
}

default ["shuttle-conductor-minimap"] = {
    type="minimap_style",
    parent = "minimap",
    height=128,
    minimal_height=128,
    maximal_width=1024,
    horizontal_align="center",
    horizontally_stretchable ="on",
}
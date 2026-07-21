local theme = {
    background = colors.black,
    desktop = colors.black,
    topbar = colors.blue,
    panel = colors.gray,
    panelAlt = colors.lightGray,
    accent = colors.cyan,
    accentDark = colors.blue,
    text = colors.white,
    muted = colors.lightGray,
    success = colors.lime,
    warning = colors.orange,
    danger = colors.red,
    button = colors.gray,
    buttonHover = colors.lightBlue,
    buttonText = colors.white,
    selectedText = colors.black,
    footer = colors.blue,
    material = {
        iron = colors.lightGray,
        gold = colors.yellow,
        diamond = colors.lightBlue,
        redstone = colors.red,
        copper = colors.orange,
        coal = colors.gray,
        emerald = colors.lime,
        lapis = colors.blue
    }
}

function theme.apply(target)
    if not target or not target.setPaletteColor then return end
    local palette = {
        [colors.black] = 0x10151C,
        [colors.gray] = 0x26313D,
        [colors.lightGray] = 0x718096,
        [colors.blue] = 0x243B66,
        [colors.lightBlue] = 0x51A8D6,
        [colors.cyan] = 0x55D6C2,
        [colors.white] = 0xF3F6F8,
        [colors.red] = 0xD85D68,
        [colors.orange] = 0xE39A50,
        [colors.yellow] = 0xE5CE70,
        [colors.lime] = 0x79C98D
    }
    for colour, rgb in pairs(palette) do
        pcall(target.setPaletteColor, colour, rgb)
    end
end

return theme

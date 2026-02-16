-- vim-sneak: Jump to any location with two characters

-- Smart visual s/S: sneak if char/blockwise with no movement, else fallback
local function smart_visual_s(sneak_plug, fallback)
    if vim.fn.mode() == "V" then return fallback end
    local start_pos = vim.fn.getpos("v")
    local cur_pos = vim.fn.getpos(".")
    if start_pos[2] == cur_pos[2] and start_pos[3] == cur_pos[3] then
        return sneak_plug
    end
    return fallback
end

return {
    "justinmk/vim-sneak",
    init = function()
        -- Label mode: show jump labels like EasyMotion
        vim.g["sneak#label"] = 1

        -- Clever-s disabled (set to 1 to press s/S again for next/prev match)
        vim.g["sneak#s_next"] = 0

        -- Respect 'ignorecase' and 'smartcase' settings
        vim.g["sneak#use_ic_scs"] = 1
    end,
    keys = {
        -- 2-character Sneak
        { "s", "<Plug>Sneak_s", mode = { "n", "o" } },
        { "S", "<Plug>Sneak_S", mode = { "n", "o" } },

        -- Visual: sneak if no selection yet, else substitute/surround
        { "s", function() return smart_visual_s("<Plug>Sneak_s", "c") end,
            mode = "x", expr = true },
        { "S", function() return smart_visual_s("<Plug>Sneak_S", "<Plug>VSurround") end,
            mode = "x", expr = true },

        -- 1-character Sneak with label-mode for f/F
        -- Use :<c-u> instead of <Cmd> to properly clear state between invocations
        { "f", ":<c-u>call sneak#wrap('', 1, 0, 1, 1)<CR>", mode = "n" },
        { "F", ":<c-u>call sneak#wrap('', 1, 1, 1, 1)<CR>", mode = "n" },
        { "f", ":<c-u>call sneak#wrap(visualmode(), 1, 0, 1, 1)<CR>", mode = "x" },
        { "F", ":<c-u>call sneak#wrap(visualmode(), 1, 1, 1, 1)<CR>", mode = "x" },
        { "f", ":<c-u>call sneak#wrap(v:operator, 1, 0, 1, 1)<CR>", mode = "o" },
        { "F", ":<c-u>call sneak#wrap(v:operator, 1, 1, 1, 1)<CR>", mode = "o" },
    },
}

-- vim-sneak: Jump to any location with two characters

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
        -- 2-character Sneak (visual surround is R, see tpope.lua)
        { "s", "<Plug>Sneak_s", mode = { "n", "o", "x" } },
        { "S", "<Plug>Sneak_S", mode = { "n", "o", "x" } },

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

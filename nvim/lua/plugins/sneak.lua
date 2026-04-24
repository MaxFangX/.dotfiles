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

        -- Disable f/t reset: sneak#reset() unmaps f/t even when sneak didn't
        -- create the mapping, which clears our DVORAK t→k mapping.
        vim.g["sneak#t_reset"] = 0
        vim.g["sneak#f_reset"] = 0
    end,
    keys = {
        -- 2-character Sneak (visual surround is R, see tpope.lua)
        { "s", "<Plug>Sneak_s", mode = { "n", "o", "x" } },
        { "S", "<Plug>Sneak_S", mode = { "n", "o", "x" } },

        -- 1-character Sneak with label-mode for f/F (normal and operator-pending)
        --
        -- NOTE: We don't use sneak's f/F because it consumes the `R` keypress
        -- that we use to trigger vim-surround when we have text selected, even
        -- if we configure sneak's labels to exclude 'R'.
        { "f", ":<c-u>silent call sneak#wrap('', 1, 0, 1, 1)<CR>", mode = "n" },
        { "F", ":<c-u>silent call sneak#wrap('', 1, 1, 1, 1)<CR>", mode = "n" },
        -- { "f", ":<c-u>silent call sneak#wrap(visualmode(), 1, 0, 1, 1)<CR>", mode = "x" },
        -- { "F", ":<c-u>silent call sneak#wrap(visualmode(), 1, 1, 1, 1)<CR>", mode = "x" },
        { "f", ":<c-u>silent call sneak#wrap(v:operator, 1, 0, 1, 1)<CR>", mode = "o" },
        { "F", ":<c-u>silent call sneak#wrap(v:operator, 1, 1, 1, 1)<CR>", mode = "o" },
    },
}

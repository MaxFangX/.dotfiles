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
        -- 2-character Sneak
        { "s", "<Plug>Sneak_s", mode = { "n", "x", "o" } },
        { "S", "<Plug>Sneak_S", mode = "n" },

        -- Replace f/F with 1-character Sneak (does not invoke label-mode)
        { "f", "<Plug>Sneak_f", mode = { "n", "x", "o" } },
        { "F", "<Plug>Sneak_F", mode = { "n", "x", "o" } },
    },
}

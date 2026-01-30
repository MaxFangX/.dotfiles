-- vim-sneak: Jump to any location with two characters

-- Smart visual s/S: sneak if char/blockwise with no movement, else substitute
local function smart_visual_s(forward)
    if vim.fn.mode() == "V" then return "c" end  -- linewise always substitutes
    local start_pos = vim.fn.getpos("v")
    local cur_pos = vim.fn.getpos(".")
    if start_pos[2] == cur_pos[2] and start_pos[3] == cur_pos[3] then
        return forward and "<Plug>Sneak_s" or "<Plug>Sneak_S"
    end
    return "c"
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

        -- Visual: sneak if no selection yet, substitute otherwise
        { "s", function() return smart_visual_s(true) end, mode = "x", expr = true },
        { "S", function() return smart_visual_s(false) end, mode = "x", expr = true },

        -- Replace f/F with 1-character Sneak (does not invoke label-mode)
        { "f", "<Plug>Sneak_f", mode = { "n", "x", "o" } },
        { "F", "<Plug>Sneak_F", mode = { "n", "x", "o" } },
    },
}

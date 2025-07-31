return {
    -- Automatically highlight other uses of the word under the cursor
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        require("illuminate").configure({
            -- delay before highlighting
            delay = 100,

            -- filetypes to not illuminate
            filetypes_denylist = {
                "dirbuf",
                "dirvish",
                "fugitive",
                "NvimTree",
                "nerdtree",
                "TelescopePrompt",
            },

            -- minimum number of matches required to perform highlighting
            min_count_to_highlight = 2,

            -- disable default keymaps since we'll define dvorak-friendly ones
            disable_keymaps = true,
        })

        -- Radical keymap change: j/J for illuminate, <Leader>j/J for search

        -- j to go to next reference (replaces regular find next)
        vim.keymap.set("n", "j", function()
            require("illuminate").goto_next_reference()
        end, { desc = "Next reference" })

        -- J to go to previous reference (replaces regular find previous)
        vim.keymap.set("n", "J", function()
            require("illuminate").goto_prev_reference()
        end, { desc = "Previous reference" })

        -- <Leader>j for regular vim search next (moved from j)
        vim.keymap.set("n", "<Leader>j", "n",
            { desc = "Find next (regular search)" })

        -- <Leader>J for regular vim search previous (moved from J)
        vim.keymap.set("n", "<Leader>J", "N",
            { desc = "Find previous (regular search)" })

        -- Text object for the reference under cursor
        vim.keymap.set({ "o", "x" }, "ir", function()
            require("illuminate").textobj_select()
        end, { desc = "Select reference" })
    end,
}

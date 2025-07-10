-- File system explorer plugin
return {
    "preservim/nerdtree",
    enabled = false,  -- Disabled for now as I don't really use it
    config = function()
        -- Toggle show NERDTree with Option+8
        vim.keymap.set("n", "•", ":NERDTreeToggle<CR>")

        -- No existing mapping h
        -- Undo existing mapping t
        vim.g.NERDTreeMapOpenInTab = '<Nul>'
        -- No existing mapping v
        -- Undo existing mapping s
        vim.g.NERDTreeMapOpenVSplit = '<Nul>'
        -- Undo existing mapping T
        vim.g.NERDTreeMapOpenInTabSilent = '<Nul>'

        -- Set my own mappings
        vim.g.NERDTreeMenuDown = 'h'      -- Navigation
        vim.g.NERDTreeMenuUp = 't'        -- Navigation
        vim.g.NERDTreeMapOpenVSplit = 'v' -- vsplit
        vim.g.NERDTreeMapOpenSplit = 's'  -- split
        -- vim.g.NERDTreeMenuOpenInTabSilent = 'T' -- can't get tab to work
        -- vim.g.NERDTreeMenuOpenInTab = 'T'       -- can't get tab to work

        -- Autocommands for NERDTree behavior
        local augroup = vim.api.nvim_create_augroup("NERDTree", {})

        -- Start NERDTree if Vim is started with 0 file arguments or >=2
        -- file args, move the cursor to the other window if so
        -- vim.api.nvim_create_autocmd("VimEnter", {
        --     group = augroup,
        --     callback = function()
        --         if vim.fn.argc() == 0 or vim.fn.argc() >= 2 then
        --             vim.cmd("NERDTree")
        --         end
        --     end,
        -- })
        -- vim.api.nvim_create_autocmd("VimEnter", {
        --     group = augroup,
        --     callback = function()
        --         if vim.fn.argc() == 0 or vim.fn.argc() >= 2 then
        --             vim.cmd("wincmd p")
        --         end
        --     end,
        -- })

        -- Open the existing NERDTree on each new tab.
        vim.api.nvim_create_autocmd("BufWinEnter", {
            group = augroup,
            callback = function()
                if vim.fn.getcmdwintype() == '' then
                    vim.cmd("silent NERDTreeMirror")
                end
            end,
        })

        -- If another buffer tries to replace NERDTree, put it in the other
        -- window, and bring back NERDTree.
        vim.api.nvim_create_autocmd("BufEnter", {
            group = augroup,
            callback = function()
                if vim.fn.winnr() == vim.fn.winnr('h')
                    and vim.fn.bufname('#'):match('NERD_tree_%d+')
                    and not vim.fn.bufname('%'):match('NERD_tree_%d+')
                    and vim.fn.winnr('$') > 1 then
                    local buf = vim.fn.bufnr()
                    vim.cmd("buffer#")
                    vim.cmd("normal! \\<C-W>w")
                    vim.cmd("buffer" .. buf)
                end
            end,
        })

        -- Exit Vim if NERDTree is the only window remaining in the only tab.
        vim.api.nvim_create_autocmd("BufEnter", {
            group = augroup,
            callback = function()
                if vim.fn.tabpagenr('$') == 1
                    and vim.fn.winnr('$') == 1
                    and vim.b.NERDTree
                    and vim.b.NERDTree.isTabTree() then
                    vim.cmd("quit")
                end
            end,
        })

        -- Close the tab if NERDTree is the only window remaining in it.
        vim.api.nvim_create_autocmd("BufEnter", {
            group = augroup,
            callback = function()
                if vim.fn.winnr('$') == 1
                    and vim.b.NERDTree
                    and vim.b.NERDTree.isTabTree() then
                    vim.cmd("quit")
                end
            end,
        })
    end,
}

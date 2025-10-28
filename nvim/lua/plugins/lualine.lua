-- Modern statusline and tabline (replacement for lightline.vim)
return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },

    config = function()
        -- Auto-unlist empty/unnamed buffers so they don't clutter buffer list
        local group = vim.api.nvim_create_augroup("UnlistEmptyBuffers",
          { clear = true })
        vim.api.nvim_create_autocmd("BufEnter", {
            group = group,
            pattern = "*",
            callback = function()
                local bufnr = vim.api.nvim_get_current_buf()
                local bufname = vim.api.nvim_buf_get_name(bufnr)
                -- If buffer has no name, mark it as unlisted
                if bufname == "" then
                    vim.bo[bufnr].buflisted = false
                end
            end,
        })
        -- Custom component: hide fileformat on narrow windows
        local function fileformat()
            if vim.fn.winwidth(0) >= 80 then
                return vim.o.fileformat
            end
            return ''
        end

        -- Custom component: hide filetype on narrow windows
        local function filetype()
            if vim.fn.winwidth(0) >= 80 then
                return vim.o.filetype ~= '' and vim.o.filetype or 'no ft'
            end
            return ''
        end

        -- Custom component: hide encoding on narrow windows
        local function encoding()
            if vim.fn.winwidth(0) >= 80 then
                return vim.o.fileencoding
            end
            return ''
        end

        require('lualine').setup({
            options = {
                theme = 'gruvbox',
                component_separators = { left = '', right = '' },
                section_separators = { left = '', right = '' },
                globalstatus = false,
            },

            -- Bottom statusline (matches lightline config)
            sections = {
                lualine_a = {'mode'},
                lualine_b = {
                    {
                        'filename',
                        path = 1,  -- Relative path
                        symbols = {
                            modified = ' ●',
                            -- modified = '[+]',
                            readonly = '[RO]',
                        }
                    }
                },
                lualine_c = {},
                lualine_x = { fileformat, encoding, filetype },
                lualine_y = {'progress'},
                lualine_z = {'location'}
            },

            inactive_sections = {
                lualine_a = {},
                lualine_b = {
                    {
                        'filename',
                        path = 1,  -- Relative path
                        symbols = {
                            modified = ' ●',
                            -- modified = '[+]',
                            readonly = '[RO]',
                        }
                    }
                },
                lualine_c = {},
                lualine_x = {},
                lualine_y = {},
                lualine_z = {}
            },

            -- Top tabline: tabs on outer left, buffers on inner left
            tabline = {
                lualine_a = {
                    {
                        'tabs',
                        mode = 0,  -- 0=tab#, 1=name, 2=tab#+name
                        path = 0,  -- 0=just filename, 1=relative, 2=abs, 3=~
                        show_modified_status = true,
                        symbols = {
                            modified = ' ●',
                            -- modified = '[+]',
                        },
                    }
                },
                lualine_b = {
                    -- Visual separator between tabs and buffers
                    { function() return '█' end, padding = 0 },
                    {
                        'buffers',
                        show_filename_only = false,  -- Show relative paths
                        show_modified_status = true,
                        icons_enabled = false,  -- Disable file type icons
                        symbols = {
                            modified = ' ●',
                            -- modified = '[+]',
                            alternate_file = '',  -- Remove # for alternate file
                            directory = '',
                        },
                    }
                },
                lualine_c = {},
                lualine_x = {},
                lualine_y = {},
                lualine_z = {}
            },

            extensions = {}
        })
    end,
}

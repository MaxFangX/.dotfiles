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
                        -- Custom formatter: abbreviate based on flags below
                        fmt = function(name, context)
                            -- - false -> "backend/src/server/lexe.rs"
                            -- - true  -> "b/s/s/lexe.rs"
                            local abbreviate_relative = false
                            -- - false -> "/Users/fang/.dotfiles/nvim/init.lua"
                            -- - true  -> "/U/f/.d/n/init.lua"
                            local abbreviate_absolute = false

                            local file = vim.api.nvim_buf_get_name(
                              context.bufnr)
                            if file == '' then
                                return name  -- [No Name]
                            end

                            local home = vim.env.HOME

                            -- Handle Cargo registry sources
                            -- Pattern: "$HOME/.cargo/registry/src/<registry>/..."
                            -- Output: "<index.crates.io>/webpki-roots-0.26.7/src/lib.rs"
                            local cargo_pattern = '^' .. home ..
                              '/.cargo/registry/src/([^/]+)/(.+)$'
                            local registry, cargo_path = file:match(
                              cargo_pattern)
                            if registry then
                                -- Extract registry name (strip hash suffix)
                                local registry_name = registry:match(
                                  '^(.-)%-[0-9a-f]+$') or registry
                                return '<' .. registry_name .. '>/' ..
                                  cargo_path
                            end

                            -- Handle Rust standard library sources
                            -- Pattern: "$HOME/.rustup/toolchains/*/lib/rustlib/src/rust/..."
                            -- Output: "<rust>/library/core/src/option.rs"
                            local rustup_pattern = '^' .. home ..
                              '/.rustup/toolchains/[^/]+/lib/rustlib/src/' ..
                              'rust/(.+)$'
                            local rust_path = file:match(rustup_pattern)
                            if rust_path then
                                return '<rust>/' .. rust_path
                            end

                            -- Get relative path from cwd
                            local rel_path = vim.fn.fnamemodify(file, ':p:.')
                            -- If starts with /, it's outside cwd (absolute)
                            if rel_path:match('^/') then
                                if abbreviate_absolute then
                                    return vim.fn.pathshorten(rel_path)
                                else
                                    return rel_path
                                end
                            end
                            -- Otherwise it's relative to cwd
                            if abbreviate_relative then
                                return vim.fn.pathshorten(rel_path)
                            else
                                return rel_path
                            end
                        end,
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

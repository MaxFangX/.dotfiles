-- Clean and minimal bottom bar
return {
    "itchyny/lightline.vim",

    -- Main configuration - see `:help lightline` for the default config.
    -- - use relativepath (default: %f) instead of filename (default: %t)
    -- - relativepath overflows into the right side (%<)
    -- - fileformat and fileencoding are empty in narrow windows (<80 chars)
    -- - inactive windows still show left components, but nothing on the right
    -- - colorscheme is set via lightline.colorscheme in a different section
    config = function()
        -- Preserve existing lightline settings (like colorscheme from themes)
        local existing_lightline = vim.g.lightline or {}

        vim.g.lightline = vim.tbl_extend("force", {
            -- Default colorscheme (change in themes.lua if switching themes)
            colorscheme = 'gruvbox',

            active = {
                left = {
                    { 'mode', 'paste' },
                    { 'readonly', 'relativepath', 'modified' }
                },
                right = {
                    { 'lineinfo' },
                    { 'percent' },
                    { 'fileformat', 'fileencoding', 'filetype' }
                }
            },
            inactive = {
                left = {
                    { 'mode', 'paste' },
                    { 'readonly', 'relativepath', 'modified' }
                },
                right = { }
            },
            tabline = {
                left = { { 'tabs' } },
                right = { { 'close' } }
            },
            component = {
                relativepath = '%f%<'
            },
            component_function = {
                fileformat = 'LightlineFileformat',
                filetype = 'LightlineFiletype',
            },
        }, existing_lightline)

        -- No file format and encoding information on narrow windows
        function _G.LightlineFileformat()
            return vim.fn.winwidth(0) >= 80 and vim.o.fileformat or ''
        end

        function _G.LightlineFiletype()
            return vim.fn.winwidth(0) >= 80 and
                (vim.o.filetype ~= '' and vim.o.filetype or 'no ft') or ''
        end

        -- Refresh lightline after colorscheme changes
        local group = vim.api.nvim_create_augroup("LightlineRefresh",
          { clear = true })
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = group,
            pattern = "*",
            callback = function()
                -- Reinitialize lightline with the current settings
                vim.cmd("call lightline#init()")
                vim.cmd("call lightline#colorscheme()")
                vim.cmd("call lightline#update()")
            end,
        })
    end,
}

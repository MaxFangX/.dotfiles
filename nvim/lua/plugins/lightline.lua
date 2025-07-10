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
        vim.g.lightline = {
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
        }

        -- No file format and encoding information on narrow windows
        function _G.LightlineFileformat()
            return vim.fn.winwidth(0) >= 80 and vim.o.fileformat or ''
        end

        function _G.LightlineFiletype()
            return vim.fn.winwidth(0) >= 80 and
                (vim.o.filetype ~= '' and vim.o.filetype or 'no ft') or ''
        end
    end,
}

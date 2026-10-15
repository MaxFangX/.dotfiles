-- GitHub Copilot configuration
return {
    {
        "github/copilot.vim",
        lazy = false,
        init = function()
            -- Disable tab mapping before plugin loads
            vim.g.copilot_no_tab_map = true

            -- Copilot doesn't help with prose, and configs (toml, json,
            -- nix) and shell scripts may contain secrets, so enable it
            -- only on code filetypes.
            vim.g.copilot_filetypes = {
                ['*'] = false,
                -- Systems
                c = true,
                cpp = true,
                rust = true,
                go = true,
                zig = true,
                -- Scripting
                python = true,
                ruby = true,
                lua = true,
                perl = true,
                -- Web
                javascript = true,
                javascriptreact = true,
                typescript = true,
                typescriptreact = true,
                html = true,
                css = true,
                scss = true,
                vue = true,
                svelte = true,
                -- JVM / mobile
                java = true,
                kotlin = true,
                scala = true,
                swift = true,
                dart = true,
                -- Functional
                haskell = true,
                ocaml = true,
                elixir = true,
                erlang = true,
                clojure = true,
                -- Other
                sql = true,
                proto = true,
                solidity = true,
                vim = true,
            }
        end,
        config = function()
            -- Use <Ctrl-r> to accept a Copilot suggestion
            vim.keymap.set('i', '<C-r>', 'copilot#Accept("\\<CR>")', {
                expr = true,
                replace_keycodes = false,
                silent = true
            })
        end,
    }
}

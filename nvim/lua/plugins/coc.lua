-- Plugin Options - coc.nvim
-- NOTE: Use :CocConfig to open the coc.nvim config file.

return {
  "neoclide/coc.nvim",
  branch = "release",
  config = function()
    -- CoC extensions
    vim.g.coc_global_extensions = {
      "coc-flutter",
      "coc-json",
      "coc-rust-analyzer",
      "coc-tsserver",
    }

    -- TODO(max): Integrate snippets: `:help coc-snippets`

    --- { Main keybindings
        -- List of all CoC actions: `:help coc-actions`

        local opts = { noremap = true, silent = true }

        -- === Global (non-namespaced) mappings === --

        -- Double click: Hover (show type/documentation)
        vim.keymap.set("n", "<2-LeftMouse>",
          ":call CocActionAsync('doHover')<CR>", opts)
        -- (h)over item
        vim.keymap.set("n", "<Leader>h", ":call CocActionAsync('doHover')<CR>",
          opts)
        -- Go to (d)efinition of this item
        vim.keymap.set("n", "<Leader>d",
          ":call CocActionAsync('jumpDefinition')<CR>", opts)
        -- Go to the definition of the (t)ype of this item
        vim.keymap.set("n", "<Leader>t",
          ":call CocActionAsync('jumpTypeDefinition')<CR>", opts)
        -- Go to (r)eferences of this item (includes the definition)
        -- vim.keymap.set("n", "<Leader>r",
        --   ":call CocActionAsync('jumpReferences')<CR>", opts)
        -- Go to (r)references of this item (excludes the definition)
        vim.keymap.set("n", "<Leader>r",
          ":call CocActionAsync('jumpUsed')<CR>", opts)
        -- Go to (i)mplementation of this item
        vim.keymap.set("n", "<Leader>i",
          ":call CocActionAsync('jumpImplementation')<CR>", opts)
        -- View code (a)ctions at cursor.
        -- - This usually works for auto-importing the item under the cursor.
        vim.keymap.set("n", "<Leader>c", "<Plug>(coc-codeaction-cursor)", opts)
        -- Do code action to quickfi(x) the current line, if any.
        -- TODO(max): Would be nice to auto open buffer diff view on select
        vim.keymap.set("n", "<Leader>x", "<Plug>(coc-fix-current)", opts)
        -- Structural (r)e(n)ame of this item
        vim.keymap.set("n", "<LocalLeader>rn",
          ":call CocActionAsync('rename')<CR>", opts)
        -- Open a (r)e(f)actor window for this item
        vim.keymap.set("n", "<LocalLeader>rf",
          ":call CocActionAsync('refactor')<CR>", opts)

        -- === <LocalLeader> mappings === --
        -- All are namespaced with <LocalLeader>c: (c)oc

        -- (c)oc: Toggle (i)nlay hints
        vim.keymap.set("n", "<LocalLeader>ci",
          ":CocCommand document.toggleInlayHint<CR>", opts)

        -- Code actions: `:help coc-code-actions`
        --
        -- NOTE: Some sources say that we should not use `noremap` for <Plug>
        -- mappings, as plugins themselves may rely upon recursive mappings.
        -- This seems dumb, since few if any users would know this, and using
        -- recursive mappings within plugin code creates footguns that users are
        -- likely to forget. So I'm ignoring this unless something breaks.
        -- https://github.com/autozimu/LanguageClient-neovim#quick-start

        -- (c)oc: View code actions at current (l)ine.
        vim.keymap.set("n", "<LocalLeader>cl", "<Plug>(coc-codeaction-line)",
          opts)
        -- (c)oc: View code actions of current file (entirely).
        vim.keymap.set("n", "<LocalLeader>ce", "<Plug>(coc-codeaction)", opts)
        -- (c)oc: View code action of current file (s)ource.
        vim.keymap.set("n", "<LocalLeader>cs", "<Plug>(coc-codeaction-source)",
          opts)
        -- (c)oc: View code action to (r)efactor at the cursor position.
        vim.keymap.set("n", "<LocalLeader>cr",
          "<Plug>(coc-codeaction-refactor)", opts)

        -- Visual mode code actions:
        -- (c)oc: View code (a)ctions for the selected range.
        vim.keymap.set("v", "<LocalLeader>ca",
          "<Plug>(coc-codeaction-selected)", opts)
        -- (c)oc: View code actions to (r)efactor the selected range
        vim.keymap.set("v", "<LocalLeader>cr",
          "<Plug>(coc-codeaction-refactor-selected)", opts)

        -- rust-analyzer commands
        -- See full list at
        -- https://github.com/fannheyward/coc-rust-analyzer?tab=readme-ov-file#commands
        -- or type :CocCommand and tab through rust-analyzer.<command>
        --
        -- (c)oc: Run fly(c)heck
        vim.keymap.set("n", "<LocalLeader>cc",
          ":CocCommand rust-analyzer.runFlycheck<CR>", opts)
        -- vim.keymap.set("n", "<LocalLeader>cxxx",
        --   ":CocCommand rust-analyzer.cancelFlycheck<CR>", opts)
        -- vim.keymap.set("n", "<LocalLeader>cxxx",
        --   ":CocCommand rust-analyzer.reload<CR>", opts)

        -- Flutter commands
        -- See full list at :CocList --input=flutter commands
        --
        -- (f)lutter (r)un
        vim.keymap.set("n", "<LocalLeader>fr",
          ":CocCommand flutter.run<CR>", opts)
        -- (f)lutter (a)ttach
        vim.keymap.set("n", "<LocalLeader>fa",
          ":CocCommand flutter.attach<CR>", opts)
        -- (f)lutter hot (r)eload
        vim.keymap.set("n", "<LocalLeader>fR",
          ":CocCommand flutter.dev.hotReload<CR>", opts)
        -- (f)lutter hot re(s)tart
        vim.keymap.set("n", "<LocalLeader>fs",
          ":CocCommand flutter.dev.hotRestart<CR>", opts)
        -- (f)lutter (q)uit
        vim.keymap.set("n", "<LocalLeader>fq",
          ":CocCommand flutter.dev.quit<CR>", opts)
        -- (f)lutter (d)evices
        vim.keymap.set("n", "<LocalLeader>fd",
          ":CocList FlutterDevices<CR>", opts)
        -- (f)lutter (e)mulators
        vim.keymap.set("n", "<LocalLeader>fe",
          ":CocList FlutterEmulators<CR>", opts)
        -- (f)lutter (l)og
        vim.keymap.set("n", "<LocalLeader>fl",
          ":CocCommand flutter.dev.openDevLog<CR>", opts)
        -- (f)lutter (p)ub get
        vim.keymap.set("n", "<LocalLeader>fp",
          ":CocCommand flutter.pub.get<CR>", opts)

        -- (e)rrors: Show all diagnostics in telescope
        vim.keymap.set("n", "<Leader>e",
          ":lua require('coc_telescope').diagnostics()<CR>", opts)
    --- }

    --- { General configuration
        -- Adapted from the coc.nvim example config:
        -- https://github.com/neoclide/coc.nvim#example-vim-configuration

        -- Some servers have issues with backup files, see #649
        vim.opt.backup = false
        vim.opt.writebackup = false

        -- Having longer updatetime (default is 4000 ms = 4 s) leads to
        -- noticeable delays and poor user experience.
        vim.opt.updatetime = 300

        -- Always show the signcolumn, otherwise it would shift the text each
        -- time diagnostics appear/become resolved.
        vim.opt.signcolumn = "yes"

        -- Map :CR to :CocRestart
        vim.cmd("command! CR CocRestart")
    --- }

    --- { coc.nvim completion options
        -- Also adapted from the coc.nvim example config.
        -- https://github.com/neoclide/coc.nvim#example-vim-configuration

        -- NOTE: An item is always selected by default, you may want to enable
        -- no select by `"suggest.noselect": true` in your configuration file.

        -- Required for the next snippet
        local function CheckBackspace()
          local col = vim.fn.col('.') - 1
          return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s')
        end

        -- Tab to navigate to next autocompletion suggestion
        -- Shift+Tab to navigate to previous autocompletion suggestion
        --
        -- If you want to simulate the 'noinsert' option, you can pass 0 (falsy)
        -- into coc#pum#next() & coc#pum#prev() instead of 1 (truthy).
        -- See `:help coc#pum#next`
        vim.keymap.set("i", "<TAB>",
          [[coc#pum#visible() ? coc#pum#next(1) : ]] ..
          [[v:lua.CheckBackspace() ? "<Tab>" : ]] ..
          [[coc#refresh()]],
          { expr = true, silent = true })
        vim.keymap.set("i", "<S-TAB>",
          [[coc#pum#visible() ? coc#pum#prev(1) : "<C-h>"]],
          { expr = true })

        -- Make CheckBackspace function accessible to vimscript
        _G.CheckBackspace = CheckBackspace

        -- Enter to confirm selection or notify coc.nvim to format
        -- NOTE: <C-g>u breaks current undo, please make your own choice.
        -- NOTE: Breaks abbreviations that include <CR>. Switch to snippets.
        vim.keymap.set("i", "<CR>",
          [[coc#pum#visible() ? coc#pum#confirm() : ]] ..
          [["<C-g>u<CR><c-r>=coc#on_enter()<CR>"]],
          { expr = true, silent = true })
    --- }

    --- { CoC statusline
        -- Info: `help coc-status`
        -- vim.opt.statusline:append("%{coc#status()}")
        -- vim.api.nvim_create_autocmd("User", {
        --   pattern = "CocStatusChange",
        --   command = "redrawstatus",
        -- })
    --- }

    --- { Custom root patterns per language for monorepo support
        -- Problem: CoC's default root detection uses the top-level .git in
        -- monorepos as the workspace for ALL files. When a session opens
        -- with a Dart file first, CoC locks to the monorepo root, preventing
        -- rust-analyzer from attaching to Rust files in subdirectories.
        --
        -- Fix: Set b:coc_root_patterns per filetype to prioritize
        -- language-specific project markers over .git:
        local group = vim.api.nvim_create_augroup("CocRootPatterns", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
          group = group,
          pattern = "rust",
          callback = function()
            -- Look for Cargo.toml before .git
            vim.b.coc_root_patterns = {'Cargo.toml', '.git'}
          end,
        })
        vim.api.nvim_create_autocmd("FileType", {
          group = group,
          pattern = "dart",
          callback = function()
            -- Look for pubspec.yaml before .git
            vim.b.coc_root_patterns = {'pubspec.yaml', '.git'}
          end,
        })
        vim.api.nvim_create_autocmd("FileType", {
          group = group,
          pattern = {"typescript", "typescriptreact", "javascript", "javascriptreact"},
          callback = function()
            -- Look for package.json or tsconfig.json before .git
            vim.b.coc_root_patterns = {'package.json', 'tsconfig.json', '.git'}
          end,
        })
        vim.api.nvim_create_autocmd("FileType", {
          group = group,
          pattern = "nix",
          callback = function()
            -- Look for flake.nix before .git
            vim.b.coc_root_patterns = {'flake.nix', '.git'}
          end,
        })
        -- This ensures each language server finds its correct project root
        -- instead of sharing the monorepo root.
        --
        -- References:
        -- https://github.com/neoclide/coc.nvim/wiki/Using-workspaceFolders
        -- https://github.com/neoclide/coc.nvim/issues/4938
        -- https://chatgpt.com/share/6892c011-f818-800d-b1a6-39c5fb96f724
    --- }

    --- { Old vim built-in completion options
        -- coc.nvim does not use vim's builtin completion, so these options are
        -- not respected. See :help coc-completion for more info.

        -- Set completeopt to have a better completion experience
        -- - :help completeopt
        -- - menuone: popup even when there's only one match
        -- - noinsert: Do not insert text until a selection is made
        -- - noselect: Do not select, force user to select one from the menu
        vim.opt.completeopt = "menuone,noinsert,noselect"

        -- Make <Enter> input a newline if no item was selected in the
        -- autocomplete pop up menu ('pum')
        -- - See 'pumvisible()' in :help eval.txt
        -- vim.keymap.set("i", "<CR>",
        --   [[pumvisible() ? ]] ..
        --   [[(complete_info().selected == -1 ? '<C-y><CR>' : '<C-y>') : ]] ..
        --   [['<CR>']],
        --   { expr = true })

        -- Avoid showing extra messages when using completion
        -- vim.opt.shortmess:append("c")
    --- }
  end,
}

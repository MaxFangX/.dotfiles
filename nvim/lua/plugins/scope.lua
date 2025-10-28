-- Tab-scoped buffers: makes each tab have its own buffer list
-- Commands like :bnext/:bprev only cycle through current tab's buffers
return {
    "tiagovla/scope.nvim",

    config = function()
        require("scope").setup({})
    end,
}

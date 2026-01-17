-- Treat JSON as JSONC to allow comments
vim.bo.filetype = "jsonc"

-- Clear the error highlighting on comments
vim.cmd("highlight link jsonCommentError Comment")

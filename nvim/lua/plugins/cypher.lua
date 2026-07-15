-- ponytail: cypher support — filetype, treesitter highlighting, and LSP via mason
vim.filetype.add({
  extension = {
    cypher = "cypher",
    cql = "cypher",
  },
})

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "cypher" },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = { "cypher_ls" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        cypher_ls = {},
      },
    },
  },
}

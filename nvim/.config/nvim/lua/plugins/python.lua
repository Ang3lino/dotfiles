-- ponytail: ruff managed externally via uv, skip Mason install
return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {},
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(server)
        return server ~= "ruff"
      end, opts.ensure_installed or {})
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff = {
          mason = false,
        },
      },
    },
  },
}

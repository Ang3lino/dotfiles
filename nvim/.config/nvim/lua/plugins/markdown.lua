-- markdownlint-cli2 is invoked via stdin (no file path), so config discovery
-- by directory walk never runs. Pass the home-level config explicitly so
-- global rule overrides (e.g. MD013 disabled) always apply.
return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          args = { "--config", vim.fn.expand("~/.markdownlint-cli2.jsonc"), "-" },
        },
      },
    },
  },
}

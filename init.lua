-- =========================
-- Neovim 0.11+ C/C++ setup (modern APIs)
-- ~/.config/nvim/init.lua
-- =========================

-- ---------- Basics ----------
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.signcolumn = "yes"
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase  = true


-- ---------- lazy.nvim bootstrap ----------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git","clone","--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "lewis6991/gitsigns.nvim", opts = {}, },
  { "tpope/vim-fugitive", },
  { "sindrets/diffview.nvim", dependencies = { "nvim-lua/plenary.nvim" }, },

  { "neovim/nvim-lspconfig" },

  -- Colorschemes
  { "rafi/awesome-vim-colorschemes" },
  { "EdenEast/nightfox.nvim" },

  -- Core utils/UI
  { "nvim-lua/plenary.nvim" },
  { "nvim-telescope/telescope.nvim", tag = "0.1.5", dependencies = { "nvim-lua/plenary.nvim" } },
  { "nvim-lualine/lualine.nvim" },
  { "lewis6991/gitsigns.nvim", opts = {} },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "c", "cpp", "cmake", "make", "lua", "vim", "vimdoc", "rust", "toml", "markdown", "markdown_inline" },
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts) require("nvim-treesitter.configs").setup(opts) end,
  },

  -- LSP tooling (install servers/binaries easily)
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" }, -- only to auto-install servers

  -- Completion
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "L3MON4D3/LuaSnip" },
  { "rafamadriz/friendly-snippets" },

  -- Formatting & Linting
  { "stevearc/conform.nvim" },
  { "mfussenegger/nvim-lint" },

  -- Debugging
  { "mfussenegger/nvim-dap" },
  { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },

  { "saecki/crates.nvim", tag = "stable", dependencies = { "nvim-lua/plenary.nvim" },
    config = function() require("crates").setup() end },

}, { checker = { enabled = false } })

vim.cmd.colorscheme("nightfox")

-- ---------- Telescope ----------
local telescope = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", telescope.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", telescope.live_grep,  { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", telescope.buffers,    { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", telescope.help_tags,  { desc = "Help" })

-- ---------- Statusline ----------
require("lualine").setup({ options = { theme = "auto" } })

-- ---------- Mason (server installer) ----------
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "clangd", "pyright", "rust_analyzer" }, -- auto-install server binaries
})

-- ---------- Completion (nvim-cmp) ----------
local cmp = require("cmp")
local cmp_lsp = require("cmp_nvim_lsp")
local capabilities = cmp_lsp.default_capabilities()

cmp.setup({
  snippet = { expand = function(args) require("luasnip").lsp_expand(args.body) end },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"]      = cmp.mapping.confirm({ select = true }),
    ["<Tab>"]     = cmp.mapping.select_next_item(),
    ["<S-Tab>"]   = cmp.mapping.select_prev_item(),
  }),
  sources = {
    { name = "nvim_lsp" }, { name = "path" }, { name = "buffer" },
  },
})

-- ---------- LSP (modern API) ----------
-- Buffer-local keymaps on attach
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
    end
    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "gr", require("telescope.builtin").lsp_references, "References")
    map("n", "gi", vim.lsp.buf.implementation, "Implementation")
    map("n", "K",  vim.lsp.buf.hover, "Hover")
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
    map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
    map("n", "<leader>e",  vim.diagnostic.open_float, "Line diagnostics")
    map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
    map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
  end,
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

vim.lsp.config("rust_analyzer", {
  capabilities = capabilities,
  settings = {
    ["rust-analyzer"] = {
      cargo = { allFeatures = true },         -- or features = { "your_feature" }
      check = { command = "clippy" },         -- on-the-fly clippy diagnostics
      procMacro = { enable = true },
      inlayHints = { bindingModeHints = { enable = true } },
    },
  },
})
vim.lsp.enable("rust_analyzer")

vim.lsp.config("pyright", {
  capabilities = capabilities,
  settings = {
    python = {
      analysis = {
        autoImportCompletions = true,
        diagnosticMode = "workspace",   -- or "openFilesOnly" if you prefer
        typeCheckingMode = "standard",  -- "off" | "basic" | "standard" | "strict"
        useLibraryCodeForTypes = true,
      },
    },
  },
})
vim.lsp.enable("pyright")

-- Define clangd via core API
vim.lsp.config("clangd", {
  cmd = { "clangd", "--background-index", "--clang-tidy",
          "--completion-style=detailed", "--header-insertion=iwyu" },
  capabilities = capabilities,
})
-- Enable clangd (starts on matching filetypes)
vim.lsp.enable("clangd")

-- ---------- Formatting (Conform) ----------
require("conform").setup({
  formatters_by_ft = {
    c = { "clang_format" },
    cpp = { "clang_format" },
    cmake = { "cmake_format" },
    python = { "isort", "black" },   -- run isort then black
    rust = { "rustfmt" },
    toml = { "taplo" },
  },
})
vim.api.nvim_create_autocmd("BufWritePre", { 
  callback = function(args)
    require("conform").format({ bufnr = args.buf, lsp_fallback = true, quiet = true })
end,
})

-- ---------- Linting (clang-tidy) ----------
require("lint").linters_by_ft = {
  c = { "clangtidy" },
  cpp = { "clangtidy" },
  python = { "ruff" },
}
vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
  callback = function()
    require("lint").try_lint()
  end,
})

-- ---------- Debugging (LLDB) ----------
local dap, dapui = require("dap"), require("dapui")
dapui.setup()
vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "DAP UI" })

dap.adapters.lldb = {
  type = "executable",
  command = "lldb-vscode", -- from Ubuntu's lldb package
  name = "lldb",
}
dap.configurations.cpp = {
  {
    name = "Launch",
    type = "lldb",
    request = "launch",
    program = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/build/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    args = {},
  },
}
dap.configurations.c = dap.configurations.cpp

dap.adapters.python = {
  type = "executable",
  command = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python",
  args = { "-m", "debugpy.adapter" },
}

dap.configurations.python = {
  {
    type = "python",
    request = "launch",
    name = "Launch file",
    program = "${file}",
    console = "integratedTerminal",
    justMyCode = true,
    pythonPath = function()
      -- Prefer project venv if present
      local venv = vim.fn.getcwd() .. "/.venv/bin/python"
      if vim.fn.executable(venv) == 1 then return venv end
      return "python3"
    end,
  },
}

local mason = vim.fn.stdpath("data") .. "/mason"
local codelldb_root = mason .. "/packages/codelldb/extension/"
local codelldb_path = codelldb_root .. "adapter/codelldb"
local liblldb_path = codelldb_root .. "lldb/lib/liblldb.so"  -- Linux

dap.adapters.codelldb = {
  type = "server",
  port = "${port}",
  executable = { command = codelldb_path, args = { "--port", "${port}" } },
  -- env = { LLDB_LIBRARY_PATH = codelldb_root .. "lldb/lib" }, -- rarely needed
}

dap.configurations.rust = {
  {
    name = "Debug (cargo build)",
    type = "codelldb",
    request = "launch",
    program = function()
      -- build first if needed: os.execute("cargo build")
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
  },
}

-- ---------- QoL ----------
vim.keymap.set("n", "<leader>ve", function()
  vim.cmd.edit(vim.fn.stdpath("config") .. "/init.lua")
end, { desc = "Edit init.lua" })
vim.keymap.set("n", "<leader>vr", function()
  vim.cmd.source(vim.fn.stdpath("config") .. "/init.lua")
end, { desc = "Reload init.lua" })

-- ----------- Colorschemes ----------
vim.keymap.set("n", "<leader>cs", function()
  require("telescope.builtin").colorscheme({ enable_preview = true })
end, { desc = "Choose Colorscheme" })

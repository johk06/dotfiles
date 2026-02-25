local utils = require "config.utils"
local mason_PATH = vim.fn.stdpath("data") .. "/mason/bin"

---@type table<string, string|false>
---All the programs that need to be available
local needed_programs = {
    typstyle = false,
}

---@param pkg Package
local install_package = function(pkg, is_update)
    utils.message("Mason", ("%s '%s"):format(is_update and "updating" or "installing", pkg.name))
    pkg:once("install:success", vim.schedule_wrap(function()
        utils.message("Mason", ("%s '%s"):format(is_update and "updated" or "installed", pkg.name))
    end))
    pkg:once("install:failed", vim.schedule_wrap(function()
        utils.error("Mason", ("Failed to %s '%s'"):format(is_update and "update" or "install", pkg.name))
    end))

    pkg:install()
end

---@param program string The executable that needs to be installed
---@param package_name string|boolean? Alternative package name
local ensure_program_installed = function(program, package_name)
    if not package.loaded["mason"] then
        needed_programs[program] = package_name or false
        return
    end

    local path = vim.fn.exepath(program)
    -- package is installed via the system, do not touch it
    if path ~= "" and not vim.startswith(path, mason_PATH) then
        return
    end

    local package = require("mason-registry").get_package(package_name or program)
    if package:is_installed() then
        local latest = package:get_latest_version()
        if latest ~= package:get_installed_version() then
            install_package(package, true)
        end
    else
        install_package(package)
    end
end

Jhk.require_program = ensure_program_installed

local ensure_all_installed = function()
    for prog, pkg in pairs(needed_programs) do
        ensure_program_installed(prog, pkg)
    end
end

---@type MasonSettings
local opts = {
    PATH = "skip", -- it's already added to $PATH when loading the plugin spec
    ui = {
        width = 0.8,
        height = 0.8,
        border = "rounded",
        icons = {
            package_installed   = "i",
            package_pending     = "…",
            package_uninstalled = "~",
        }
    }
}

---@type LazySpec
local M = {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUninstallAll", "MasonLog", "MasonUpdate" },
    event = { "VeryLazy" },
    init = function()
        -- make packages available before Mason is actually loaded
        vim.env.PATH = mason_PATH .. ":" .. vim.env.PATH
    end,
    config = function()
        require("mason").setup(opts)
        vim.defer_fn(ensure_all_installed, 600)
    end
}

return M

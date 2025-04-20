-- tests/init.lua
-- Busted test runner entry point for Neogit

-- Add lua/ to the package path for Neovim plugin-style structure
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

require("tests.test_status")

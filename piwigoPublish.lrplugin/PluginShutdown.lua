--[[

    PluginShutdown.lua - run by Lightroom when the application quits (LrShutdownApp)

    This file is part of PiwigoPublish

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

---@diagnostic disable: undefined-global

return {
    LrShutdownFunction = function(doneFunction, progressFunction)
        -- #16: the shared Piwigo session (cookies + token) must not stay in the prefs file.
        -- doneFunction must be called whatever happens, or Lightroom shows a stuck
        -- background-task window on quit (upstream #77).
        pcall(function()
            if PWConnectionManager then
                PWConnectionManager.clearAll()
            end
        end)
        doneFunction()
    end,
}

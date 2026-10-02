local engineRoot = os.getenv("GEN1RECOMP_ROOT") or "gen1recomp"
package.path = engineRoot .. "/?.lua;" .. engineRoot .. "/?/init.lua;" .. package.path

local T = require("tests.modkit")
local GameVersion = require("src.core.GameVersion")
local Profile = require("src.core.game3.profile")
local Options = require("src.core.game3.options")
local Pokemon = require("src.core.game3.pokemon")

local previousVersion = GameVersion.get()
GameVersion.set("emerald")
Profile.reset()

local modPath = os.getenv("SHINY_ODDS_MOD_PATH") or "mods/shiny_odds"
local run = T.sdk.loadMod(modPath, {
  root = modPath:sub(1, 1) == "/" and "/" or nil,
  data = T.sdk.gen3Data(),
  generation = 3,
})
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")
T.check(run.mod ~= nil, "the SDK loader discovers this mod path")

local session = { version = "emerald" }
local game = { options = {}, session = session }
Options.bind(session, game.options)

local GameRuntime = require("src.core.game3.runtime")
local previousSession = GameRuntime.session
GameRuntime.session = session

local Rows = require("src.ui.game3.option_rows")
Rows._shinyOddsOriginalBuild = function() return {} end

local context = { options = game.options, session = session, game = game }
local rows = Rows.build(context)
local shinyRow, shinyIndex
for index, row in ipairs(rows) do
  if row.id == "shinyOddsRate" then shinyRow, shinyIndex = row, index end
end
T.check(shinyRow ~= nil, "SHINY ODDS is in the options rows")

if shinyRow then
  T.eq(shinyRow.value(game), "DEFAULT", "the default rate is DEFAULT")

  local labels = { "1/4096", "1/2048", "1/1024", "1/512", "1/256", "1/128",
                   "1/64", "1/32", "100%", "DEFAULT" }
  for _, label in ipairs(labels) do
    shinyRow.step(context, 1)
    T.eq(shinyRow.value(game), label, "right selects " .. label)
  end
  shinyRow.step(context, -1)
  T.eq(shinyRow.value(game), "100%", "left selects the previous rate")
end

-- Pure math: 100% always forces shiny; DEFAULT always matches the vanilla
-- personality/OT formula, with no ROM data required for either path.
local vanillaMon = { personality = 12345, otId = 1, otSecretId = 2 }
local vanillaShiny = Pokemon._shinyOddsOriginalIsShiny(vanillaMon)

session.options["shinyOddsRate"] = "default"
T.eq(Pokemon.isShiny({ personality = 12345, otId = 1, otSecretId = 2 }), vanillaShiny,
  "DEFAULT keeps the vanilla shiny formula")

session.options["shinyOddsRate"] = "100"
local forced = { personality = 999, otId = 9, otSecretId = 9 }
T.eq(Pokemon.isShiny(forced), true, "100% always forces a shiny result")
T.eq(forced.isShiny, true, "the roll is cached on the mon")
T.eq(Pokemon.isShiny(forced), true, "the cached result is stable on repeat checks")

session.options["shinyOddsRate"] = nil
GameRuntime.session = previousSession
run.release()
local unloadedRows = Rows.build({})
local rowRemains = false
for _, row in ipairs(unloadedRows) do
  if row.id == "shinyOddsRate" then rowRemains = true end
end
T.eq(rowRemains, false, "the menu row is hidden when the mod unloads")
GameVersion.set(previousVersion)
Profile.reset()
T.finish("shiny_odds")

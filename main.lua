local Options = require("src.core.game3.options")
local Rows = require("src.ui.game3.option_rows")
local Runtime = require("src.mods.Runtime")
local GameRuntime = require("src.core.game3.runtime")
local Pokemon = require("src.core.game3.pokemon")

-- DEFAULT (chance = nil) leaves the vanilla personality/OT shiny formula
-- untouched; every other rate rolls once per mon and caches on mon.isShiny,
-- the same field Pokemon.isShiny already treats as an explicit override.
local ODDS = {
  { id = "default", label = "DEFAULT" },
  { id = "1_4096", label = "1/4096", chance = 1 / 4096 },
  { id = "1_2048", label = "1/2048", chance = 1 / 2048 },
  { id = "1_1024", label = "1/1024", chance = 1 / 1024 },
  { id = "1_512", label = "1/512", chance = 1 / 512 },
  { id = "1_256", label = "1/256", chance = 1 / 256 },
  { id = "1_128", label = "1/128", chance = 1 / 128 },
  { id = "1_64", label = "1/64", chance = 1 / 64 },
  { id = "1_32", label = "1/32", chance = 1 / 32 },
  { id = "100", label = "100%", chance = 1 },
}
local OPTION_KEY = "shinyOddsRate"
local ROW_ID = "shinyOddsRate"

local function rateId(options)
  local value = options and options[OPTION_KEY]
  for _, entry in ipairs(ODDS) do
    if entry.id == value then return entry.id end
  end
  return "default"
end

local function rateIndex(id)
  for index, entry in ipairs(ODDS) do
    if entry.id == id then return index end
  end
  return 1
end

local function labelFor(id)
  for _, entry in ipairs(ODDS) do
    if entry.id == id then return entry.label end
  end
  return "DEFAULT"
end

local function chanceFor(id)
  for _, entry in ipairs(ODDS) do
    if entry.id == id then return entry.chance end
  end
  return nil
end

local function optionsFor(ctx)
  if not ctx or type(ctx.options) ~= "table" then return nil end
  return Options.block(ctx.options, Options.blockId(ctx.session))
end

-- shiny.roll never fires on Game3 today; it's a zero-cost, always-legal
-- hook to own purely so Hooks:removeOwner can tell us the mod unloaded.
local function installed()
  local chains = Runtime.hooks and Runtime.hooks.chains
  for _, hook in ipairs(chains and chains["shiny.roll"] or {}) do
    if hook.owner == "shiny_odds" then return true end
  end
  return false
end

if not Pokemon._shinyOddsOriginalIsShiny then
  Pokemon._shinyOddsOriginalIsShiny = Pokemon.isShiny
  Pokemon.isShiny = function(mon)
    if not installed() or type(mon) ~= "table" or mon.isShiny ~= nil then
      return Pokemon._shinyOddsOriginalIsShiny(mon)
    end
    local session = GameRuntime.getSession and GameRuntime.getSession()
    local chance = chanceFor(rateId(session and session.options))
    if not chance then return Pokemon._shinyOddsOriginalIsShiny(mon) end
    mon.isShiny = math.random() < chance
    return mon.isShiny
  end
end

return function(mod)
  mod.hooks:wrap("shiny.roll", function(next, ...) return next(...) end)

  local extrasGroup
  for _, group in ipairs(Rows.GROUPS) do
    if group.id == "group.extras" then extrasGroup = group end
  end
  if extrasGroup then
    local found = false
    for _, id in ipairs(extrasGroup.members) do
      if id == ROW_ID then found = true end
    end
    if not found then extrasGroup.members[#extrasGroup.members + 1] = ROW_ID end
  end

  if not Rows._shinyOddsOriginalBuild then
    Rows._shinyOddsOriginalBuild = Rows.build
    Rows.build = function(ctx)
      local out = Rows._shinyOddsOriginalBuild(ctx)
      if not installed() then return out end
      for _, row in ipairs(out) do
        if row.id == ROW_ID then return out end
      end
      out[#out + 1] = {
        id = ROW_ID,
        label = "SHINY ODDS",
        value = function(c)
          return labelFor(rateId(optionsFor(c)))
        end,
        step = function(c, direction)
          local options = optionsFor(c)
          if not options then return false end
          local current = rateIndex(rateId(options))
          local delta = direction and direction < 0 and -1 or 1
          local nextIndex = (current - 1 + delta) % #ODDS + 1
          options[OPTION_KEY] = ODDS[nextIndex].id
          return true
        end,
      }
      return out
    end
  end
end

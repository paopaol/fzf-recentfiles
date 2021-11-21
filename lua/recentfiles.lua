if not pcall(require, 'fzf') then return end

local core = require('fzf-lua.core')
local config = require "fzf-lua.config"
local utils = require "fzf-lua.utils"

do
  -- declare local variables
  -- // exportstring( string )
  -- // returns a "Lua" portable version of the string
  local function exportstring(s) return string.format("%q", s) end

  -- // The Save Function
  function table.save(tbl, filename)
    local charS, charE = "   ", "\n"
    local file, err = io.open(filename, "wb")
    if err then return err end

    -- initiate variables for save procedure
    local tables, lookup = {tbl}, {[tbl] = 1}
    file:write("return {" .. charE)

    for idx, t in ipairs(tables) do
      file:write("-- Table: {" .. idx .. "}" .. charE)
      file:write("{" .. charE)
      local thandled = {}

      for i, v in ipairs(t) do
        thandled[i] = true
        local stype = type(v)
        -- only handle value
        if stype == "table" then
          if not lookup[v] then
            table.insert(tables, v)
            lookup[v] = #tables
          end
          file:write(charS .. "{" .. lookup[v] .. "}," .. charE)
        elseif stype == "string" then
          file:write(charS .. exportstring(v) .. "," .. charE)
        elseif stype == "number" then
          file:write(charS .. tostring(v) .. "," .. charE)
        end
      end

      for i, v in pairs(t) do
        -- escape handled values
        if (not thandled[i]) then

          local str = ""
          local stype = type(i)
          -- handle index
          if stype == "table" then
            if not lookup[i] then
              table.insert(tables, i)
              lookup[i] = #tables
            end
            str = charS .. "[{" .. lookup[i] .. "}]="
          elseif stype == "string" then
            str = charS .. "[" .. exportstring(i) .. "]="
          elseif stype == "number" then
            str = charS .. "[" .. tostring(i) .. "]="
          end

          if str ~= "" then
            stype = type(v)
            -- handle value
            if stype == "table" then
              if not lookup[v] then
                table.insert(tables, v)
                lookup[v] = #tables
              end
              file:write(str .. "{" .. lookup[v] .. "}," .. charE)
            elseif stype == "string" then
              file:write(str .. exportstring(v) .. "," .. charE)
            elseif stype == "number" then
              file:write(str .. tostring(v) .. "," .. charE)
            end
          end
        end
      end
      file:write("}," .. charE)
    end
    file:write("}")
    file:close()
  end

  -- // The Load Function
  function table.load(sfile)
    local ftables, err = loadfile(sfile)
    if err then return _, err end
    local tables = ftables()
    if not tables then return nil end
    for idx = 1, #tables do
      local tolinki = {}
      for i, v in pairs(tables[idx]) do
        if type(v) == "table" then tables[idx][i] = tables[v[1]] end
        if type(i) == "table" and tables[i[1]] then
          table.insert(tolinki, {i, tables[i[1]]})
        end
      end
      -- link indices
      for _, v in ipairs(tolinki) do
        tables[idx][v[2]], tables[idx][v[1]] = tables[idx][v[1]], nil
      end
    end
    return tables[1]
  end
  -- close do
end

local recentfiles = {}
local cache = '/home/jz/.cache/nvim/recentfiles.txt'

local M = {}

M.push_latest_used_file = function(absolute_path, timestamp)
  local item = {path = absolute_path, time = timestamp}
  recentfiles[absolute_path] = item
  table.save(recentfiles, cache)
end

M.update_history = function()
  if not next(recentfiles) then
    recentfiles = table.load(cache)
    recentfiles = recentfiles or {}
  end

  local absolute = vim.fn.expand('%:p')
  if vim.fn.filereadable(absolute) == 1 then
    M.push_latest_used_file(absolute, os.time())
  end
end

M.get_histories = function()
  local files = {}
  for _, item in pairs(recentfiles) do table.insert(files, item) end

  table.sort(files, function(a, b) return a.time > b.time end)
  return files
end

M.fzf_recentfiles = function()
  local files = M.get_histories()

  local items = {}
  for _, task in pairs(files) do
    setmetatable(task, {__tostring = function(table) return table.path end})
    table.insert(items, task)
    items[tostring(task)] = task
  end

  local opts = config.normalize_opts({}, config.globals.files)
  opts.prompt = 'RecentFiles❯ '

  opts.fzf_fn = function(cb)
    for _, x in ipairs(items) do
      x = core.my_make_entry_file(opts, x.path)
      if x then
        cb(x, function(err)
          if err then return end
          cb(nil, function() end)
        end)
      end
    end
    utils.delayed_cb(cb)
  end

  core.my_fzf_files(opts)
end

return M

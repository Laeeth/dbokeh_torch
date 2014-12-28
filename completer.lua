--- Completion engine
-- Compute possible matches for input text.
-- Based on [lua-rlcompleter](https://github.com/rrthomas/lua-rlcompleter) by 
-- Patrick Rapin and Reuben Thomas.
-- @alias M

local lfs = pcall(require, "lfs") and require"lfs"
local cowrap, coyield = coroutine.wrap, coroutine.yield

local M = { }

--- The list of Lua keywords
M.keywords = {
  'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for',
  'function', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat',
  'return', 'then', 'true', 'until', 'while'
}

--- Callback function to set final character.
-- Called to set the final chracter if a single match occur. Typically, it is used
-- to close a string if completion occurs inside an open string. It is intended
-- to be redefined as default function does nothing.
-- @param[type=string]  char  Either an empty string or a string of length 1.
M.final_char_setter = function(char) end

--- References all completion generators (completers).
-- Completion is context sensitive and there is 2 *contexts* : values 
-- (@{completers.value}) and strings (@{completers.string}). Some arguments are
-- given to the completer the first time it's called.
--
-- Each context has its corresponding table (sequence) with *completers* inside.
-- These tables works a bit like `package.loaders` : each loader is called as a 
-- coroutine and can generate possible matches (by yielding strings). But, unlike 
-- `package.loaders`, all completers are always called; even if matches has been 
-- generated by previous ones.
--
-- It it not the completer job to filter matches with current text (this is done
-- by the complettion engine), but just generate all possible matches.
M.completers = { }

--- Completers for Lua values.
-- Completers are called with two arguments :
--
--  * `value` to complete (not necessarily a table)
--  * `separator` used to index value (`.`, `:` or `[`)
--
-- Default completers for values are :
--
--  1. Table field completer: searches for fields inside `value` if it's a table.
--  2. Metatable completer: if `value` has a metatable, calls first completer 
--     with that table.
--
-- @table completers.value
M.completers.value = { }

--- Completers for strings.
-- Completers are called with the string to complete.
-- If `lfs` is can be loaded, a completer for files and folders is provided, it
-- search for items starting with given string in current directory.
-- @table completers.string
M.completers.string = { }

-- Table fields completer
table.insert(M.completers.value, function(t, sep)
  if type(t) ~= "table" then return end
  for k, v in pairs(t) do
    if type(k) == "number" and sep == "[" then 
      coyield(k.."]")
    elseif type(k) == "string" and (sep ~= ":" or type(v) == "function") then
      coyield(k)
    end
  end
end)

-- Metamethod completer
table.insert(M.completers.value, function(t, sep)
  local mt = getmetatable(t)
  if mt and type(mt.__index) == "table" then
    return M.completers.value[1](mt.__index, sep) -- use regular table completer on metatable
  end
end)

-- tensor/storage/torch-classes completer
table.insert(M.completers.value, function(t, sep)
  local function enumerate_metatable(typename)
    if typename == nil then return end
    local metatable = torch.getmetatable(typename)
    for k, v in pairs(metatable) do
      if type(k) == "number" and sep == "[" then
        coyield(k.."]")
      elseif type(k) == "string" and (sep ~= ":" or type(v) == "function") then
        coyield(k)
      end
    end
    if torch.typename(metatable) ~= typename then
      enumerate_metatable(torch.typename(metatable))
    end
  end
  enumerate_metatable(torch.typename(t))
end)


-- This function does the same job as the default completion of readline,
-- completing paths and filenames. Rewritten because
-- rl_basic_word_break_characters is different.
-- Uses LuaFileSystem (lfs) module for this task (if present).
if lfs then
  table.insert(M.completers.string, function(str)
    local path, name = str:match("(.*)[\\/]+(.*)")
    path = (path or ".") .. "/"
    name = name or str
    -- avoid to trigger an error if folder does not exists
    if not lfs.attributes(path) then return end
    for f in lfs.dir(path) do
      if (lfs.attributes(path .. f) or {}).mode == 'directory' then
        coyield(f .. "/")
      else
        coyield(f)
      end
    end
  end)
end

-- This function is called back by C function do_completion, itself called
-- back by readline library, in order to complete the current input line.
function M.complete(word, line, startpos, endpos)
  -- Helper function registering possible completion words, verifying matches.
  local matches = {}
  local function add(value)
    value = tostring(value)
    if value:match("^" .. word) then
      matches[#matches + 1] = value
    end
  end
  
  local function call_completors(completers, ...)
    for _, completer in ipairs(completers) do
      local coro = cowrap(completer)
      local match = coro(...) -- first call => give parameters
      if match then
        add(match)
        -- continue calling to get next matches
        for match in coro do add(match) end
      end
    end
  end

  -- This function is called in a context where a keyword or a global
  -- variable can be inserted. Local variables cannot be listed!
  local function add_globals()
    for _, k in ipairs(M.keywords) do
      add(k)
    end
    call_completors(M.completers.value, _G)
  end

  -- Main completion function. It evaluates the current sub-expression
  -- to determine its type. Currently supports tables fields, global
  -- variables and function prototype completion.
  local function contextual_list(expr, sep, str)
    if str then
      M.final_char_setter('"')
      return call_completors(M.completers.string, str)
    end
    M.final_char_setter("")
    if expr and expr ~= "" then
      local v = loadstring("return " .. expr)
      if v then
        call_completors(M.completers.value, v(), sep)
      end
    end
    if #matches == 0 then
      add_globals()
    end
  end

  -- This complex function tries to simplify the input line, by removing
  -- literal strings, full table constructors and balanced groups of
  -- parentheses. Returns the sub-expression preceding the word, the
  -- separator item ( '.', ':', '[', '(' ) and the current string in case
  -- of an unfinished string literal.
  local function simplify_expression(expr)
    -- Replace annoying sequences \' and \" inside literal strings
    expr = expr:gsub("\\(['\"])", function (c)
                                    return string.format("\\%03d", string.byte(c))
                                end)
    local curstring
    -- Remove (finished and unfinished) literal strings
    while true do
      local idx1, _, equals = expr:find("%[(=*)%[")
      local idx2, _, sign = expr:find("(['\"])")
      if idx1 == nil and idx2 == nil then
        break
      end
      local idx, startpat, endpat
      if (idx1 or math.huge) < (idx2 or math.huge) then
        idx, startpat, endpat = idx1, "%[" .. equals .. "%[", "%]" .. equals .. "%]"
      else
        idx, startpat, endpat = idx2, sign, sign
      end
      if expr:sub(idx):find("^" .. startpat .. ".-" .. endpat) then
        expr = expr:gsub(startpat .. "(.-)" .. endpat, " STRING ")
      else
        expr = expr:gsub(startpat .. "(.*)", function (str)
                                               curstring = str
                                               return "(CURSTRING "
                                           end)
      end
    end
    expr = expr:gsub("%b()"," PAREN ") -- Remove groups of parentheses
    expr = expr:gsub("%b{}"," TABLE ") -- Remove table constructors
    -- Avoid two consecutive words without operator
    expr = expr:gsub("(%w)%s+(%w)","%1|%2")
    expr = expr:gsub("%s+", "") -- Remove now useless spaces
    -- This main regular expression looks for table indexes and function calls.
    return curstring, expr:match("([%.%w%[%]_]-)([:%.%[%(])" .. word .. "$")
  end

  -- Now call the processing functions and return the list of results.
  local str, expr, sep = simplify_expression(line:sub(1, endpos))
  contextual_list(expr, sep, str)
  return matches
end

return M
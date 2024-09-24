
local pass = {}

local core = require "core"

------------------------------------------------------------------------
-- alas we... do the Monkey Patch... AGAIN

------------------------------------------------------------------------
-- Monkey patch core.doc

local Doc = require "core.doc"

local origLoad = Doc.load
local load = function(self, filename)
  local startIndx, endIndx = string.find(filename, "%.gpg$")
  if not startIndx then
    return origLoad(self, filename)
  end
  local passFileName = string.sub(filename, 1, startIndx-1)
  local fp = assert(io.popen("pass show " .. passFileName .. " 2>&1", "r"))
  self:reset()
  self.lines = {}
  local i = 1
  for line in fp:lines() do
    if line:byte(-1) == 13 then
      line = line:sub(1, -2)
      self.crlf = true
    end
    table.insert(self.lines, line .. "\n")
    self.highlighter.lines[i] = false
    i = i + 1
  end
  if #self.lines == 0 then
    table.insert(self.lines, "\n")
  end
  if not fp:close() then
    core.error("Could open " .. filename .. " using pass")
  end
  self:reset_syntax()
end
Doc.load = load

local save = function(self, filename, abs_filename)
  if not filename then
    assert(self.filename, "no filename set to default to")
    filename = self.filename
    abs_filename = self.abs_filename
  else
    assert(self.filename or abs_filename, "calling save on unnamed doc without absolute path")
  end
  local fp = assert(io.popen("pass insert " .. filename, "wb"))
  for _, line in ipairs(self.lines) do
    if self.crlf then line = line:gsub("\n", "\r\n") end
    fp:write(line)
  end
  fp:close()
  self:set_filename(filename, abs_filename)
  self.new_file = false
  self:clean()
end
Doc.save = save

------------------------------------------------------------------------
-- Monkey patch RootView

local RootView = require "core.rootview"

local preOpenExtRootViewOpenDoc = RootView.open_doc

------------------------------------------------------------------------
-- Monkey patch core.init


local origCoreInit = core.init
local wrappedInit = function()
  -- call the origiinal core init
  -- this will load the plugins
  --  (and Open_Ext will monkey patch RootView.open_doc)
  origCoreInit()

  -- Do our own Monkey Patch to check for ".gpg" extension
  local postOpenExtRootViewOpenDoc = RootView.open_doc
  local openDoc = function(self, doc)
    if string.find(doc.filename, "%.gpg$") then
      preOpenExtRootViewOpenDoc(self, doc)
    else
      postOpenExtRootViewOpenDoc(self, doc)
    end
  end
  RootView.open_doc = openDoc
end
core.init = wrappedInit

------------------------------------------------------------------------
-- implement any required pass initializations

function pass.init()

  local homeDir = os.getenv("HOME")
  if not homeDir then
    error("cannot get the user's HOME directory")
  end
  system.chdir(homeDir .. "/.password-store")
end

return pass
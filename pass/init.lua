
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
-- extend the DocView ContextMenu

local ContextMenu = require "core.contextmenu"
local menu = require "plugins.contextmenu"

local function doc()
  return core.active_view.doc
end

local function getPassword()
  return doc().lines[1]
end

local function findValueForKey(aKey)
  for _, line in ipairs(doc().lines) do
    local startIndx, endIndx = string.find(line, aKey..':')
    if startIndx then
      aValue = line:sub(endIndx, -1)
      aValue = aValue:gsub("\n", "")
      aValue = aValue:gsub("\r", "")
      return aValue
    end
  end
  return nil
end

local function getUserName()
  return findValueForKey('UserName')
end

local function getURL()
  return findValueForKey('URL')
end

-- see /usr/lib/password-store/extensions/otp.bash
-- for details (otp_parse_uri)
-- see also the oathtool
--
local function getOTP()
  return findValueForKey('otpauth')
end

local command = require "core.command"

local DocView = require "core.docview"

-- see data/core/command.lua :: command.generate_predicate
--
local function checkGPG(...)
  local addMenu = false
  if core.active_view:extends(DocView) then
    if string.find(doc().filename, "%.gpg$") then
      addMenu = true
    end
  end
  return addMenu, core.active_view, ...
end

local style = require "core.style"

local function tellUser(aMessage)
  if core.status_view then
    local s = style.log["INFO"]
    core.status_view:show_message(s.icon, s.color, aMessage)
  else
    print(aMessage)
  end
  print(aMessage)
end

local xselCopyCmd  = "/usr/bin/xsel -i -t 40000 -b"
local xselClearCmd = "/usr/bin/xsel -c -b"
local otpCmd       = "oathtool --totp -"

command.add(checkGPG, {
	["pass:copy-password"] = function()
	  local aPassword = getPassword()
	  if aPassword then
      local fp = io.popen(xselCopyCmd, "w")
      if fp then
        tellUser("Copied password to clipboard")
        fp:write(aPassword)
        fp:close()
      else
        tellUser("No password found in Password Entry")
      end
    end
	end,
	["pass:copy-user-name"] = function()
	  local aUserName = getUserName()
	  if aUserName then
      local fp = io.popen(xselCmd, "w")
      if fp then
        tellUser("Copied UserName")
        fp:write(aUserName)
      else
        tellUser("No UserName found in Password Entry")
      end
    end
	end,
	["pass:copy-url"] = function()
	  local aURL = getURL()
	  if aURL then
      local fp = io.popen(xselCmd, "w")
      if fp then
        tellUser("Copied URL")
        fp:write(aURL)
      else
        tellUser("No URL found in Password Entry")
      end
    end
	end,
	["pass:copy-otp"] = function()
	  local anOTP = getOTP()
	  if anOTP then
      local fp = io.popen(xselCmd, "w")
      if fp then
        tellUser("Copies TOTP")
        fp:write(anOTP)
      else
        tellUser("otpauth not found in Password Entry")
      end
    end
	end
})

-- could use keymap.add to add these commands to keys

local cmds = {
  ContextMenu.DIVIDER,
	{ text = "Copy password", command = "pass:copy-password" },
	{ text = "Copy username", command = "pass:copy-user-name" },
	{ text = "Copy URL",      command = "pass:copy-url" },
	{ text = "Copy OTP",      command = "pass:copy-otp" }
}

menu:register(checkGPG, cmds)

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
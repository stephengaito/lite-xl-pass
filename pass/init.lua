
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

local origSave = Doc.save
local save = function(self, filename, abs_filename)
  if not filename then
    assert(self.filename, "no filename set to default to")
    filename = self.filename
    abs_filename = self.abs_filename
  else
    assert(self.filename or abs_filename, "calling save on unnamed doc without absolute path")
  end
  local startIndx, endIndx = string.find(filename, "%.gpg$")
  if not startIndx then
    return origSave(self, filename, abs_filename)
  end
  local passFileName = string.sub(filename, 1, startIndx-1)
  local fp = assert(io.popen("pass insert -m -f " .. passFileName, "w"))
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
-- provide some helper tools

local style = require "core.style"

local function tellUser(aMessage)
  if core.status_view then
    local s = style.log["INFO"]
    core.status_view:show_message(s.icon, s.color, aMessage)
  else
    print(aMessage)
  end
  --print(aMessage)
end

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
      local aValue = line:sub(endIndx+1, -1)
      aValue = aValue:gsub("\n", "")
      aValue = aValue:gsub("\r", "")
      return aValue
    end
  end
  return nil
end

local function addKey(aKey)
  local aValue = findValueForKey(aKey)
  if not aValue then
    if aKey == "password" then
      doc():insert(1, 1, '')
    else
      local theValue = aKey..': '
      if aKey == 'otpauth' then
        theValue = 'otpauth://totp/<issuer>:<username>?secret=<secrectInBase32>&period=30s&digits=6&algorithm=<SHA1|SHA256|SHA512>'
      end
      local theDoc = doc()
      theDoc:insert(#theDoc.lines+1, 1, '\n'..theValue)
    end
  end
end

local function generatePassword()
  local pwLength  = findValueForKey('pwLength')
  local pwOptions = findValueForKey('pwOptions')
  if not pwLength  then pwLength  = '20'   end
  if not pwOptions then pwOptions = '-s' end
  local fp = io.popen('pwgen ' .. pwOptions .. ' ' .. pwLength .. ' 1', "r")
  if fp then
    local aPassword = fp:read('L')
    if aPassword then
      doc():insert(1, 1, aPassword)
    end
    fp:close()
    tellUser("Generated password " .. aPassword)
  else
    tellUser("Could not popen the pwgen command for reading")
  end
end

local function getUserName()
  return findValueForKey('username')
end

local function getURL()
  return findValueForKey('url')
end

-- see /usr/lib/password-store/extensions/otp.bash
-- for details (otp_parse_uri)
-- see also the oathtool
-- see also:
--   https://github.com/google/google-authenticator/wiki/Key-Uri-Format
--   https://github.com/remjey/luaotp/blob/master/src/otp.lua

local function splitStr(aStr, aSep)
  if aSep == nil then aSep = "%s" end
  local result = {}
  for aField in string.gmatch(aStr, "([^"..aSep.."]+)") do
    table.insert(result, aField)
  end
  return result
end

local function getParams(aStr)
  local rawKeyValues = splitStr(aStr, "%&")
  local params = {}
  for _, rawKeyValue in pairs(rawKeyValues) do
    local keyValue = splitStr(rawKeyValue, "%=")
    params[keyValue[1]] = keyValue[2]
  end
  return params
end

local function getOTP()
  local result = {}
  local otpUri = findValueForKey('otpauth')
  if not otpUri then
    tellUser("No otpauth found in password entry")
    return result
  end

  local parts = splitStr(otpUri, '%?')
  if #parts < 2 then
    tellUser("Could not parse otpauth... do you need to wrap it?")
    return result
  end

  local params = getParams(parts[2])
  if params['secret'] then
    result['secret'] = params['secret']
  end

  local cmd      = "oathtool -b "

  if params['digits'] then
    cmd = cmd .. ' -d ' .. params['digits']
  end

  if params['period'] then
    cmd = cmd .. ' -s ' .. params['period']
  end

  if params['algorithm'] then
    cmd = cmd .. ' --totp=' ..  params['algorithm']:upper()
  else
    cmd = cmd .. ' --totp'
  end

  result['cmd'] = cmd .. ' - '
  return result
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

local xselCopyCmd  = "/usr/bin/xsel -i -t 40000 -b"
local xselClearCmd = "/usr/bin/xsel -c -b"

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
        tellUser("Could not copy Password to the clipboard")
      end
    else
      tellUser("No password found in Password Entry")
    end
	end,
	["pass:copy-user-name"] = function()
	  local aUserName = getUserName()
	  if aUserName then
      local fp = io.popen(xselCopyCmd, "w")
      if fp then
        tellUser("Copied UserName")
        fp:write(aUserName)
	      fp:close()
      else
        tellUser("Could not copy UserName to the clipboard")
      end
    else
      tellUser("No UserName found in Password Entry")
    end
	end,
	["pass:copy-url"] = function()
	  local aURL = getURL()
	  if aURL then
      local fp = io.popen(xselCopyCmd, "w")
      if fp then
        tellUser("Copied URL")
        fp:write(aURL)
	      fp:close()
      else
        tellUser("Could not copy URL to the clipboard")
      end
    else
      tellUser("No URL found in Password Entry")
    end
	end,
	["pass:copy-otp"] = function()
	  local anOTP = getOTP()
	  if anOTP['secret'] and anOTP['cmd'] then
	    local otpCmd = anOTP['cmd'] .. ' | ' .. xselCopyCmd
	    -- print(otpCmd)
      local fp = io.popen(otpCmd, "w")
      if fp then
        tellUser("Copied TOTP")
        fp:write(anOTP['secret'])
	      fp:close()
      else
        tellUser("Could not copy the TOTP to the clipboard")
      end
    end
	end,
	["pass:clear-clipboard"] = function ()
	  local fp = io.popen(xselClearCmd, "w")
	  if fp then
	    tellUser("Clipboard cleared")
	    fp:close()
	  else
	    tellUser("Could not clear the clipboard")
	  end
	end,
  ["pass:generate-password"] = function ()
    generatePassword()
  end,
	["pass:add-password"] = function()
	  addKey('password')
	end,
	["pass:add-user-name"] = function()
	  addKey('username')
	end,
	["pass:add-url"] = function()
	  addKey('url')
	end,
	["pass:add-otp"] = function()
	  addKey('otpauth')
  end
})

-- could use keymap.add to add these commands to keys

local cmds = {
  ContextMenu.DIVIDER,
	{ text = "Copy password", command = "pass:copy-password" },
	{ text = "Copy username", command = "pass:copy-user-name" },
	{ text = "Copy URL",      command = "pass:copy-url" },
	{ text = "Copy OTP",      command = "pass:copy-otp" },
  ContextMenu.DIVIDER,
	{ text = "Clear clipboard", command = "pass:clear-clipboard" },
  ContextMenu.DIVIDER,
	{ text = "Generate password", command = "pass:generate-password" },
  ContextMenu.DIVIDER,
	{ text = "Add password", command = "pass:add-password" },
	{ text = "Add username", command = "pass:add-user-name" },
	{ text = "Add URL",      command = "pass:add-url" },
	{ text = "Add OTP",      command = "pass:add-otp" },
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
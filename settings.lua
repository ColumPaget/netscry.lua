settings={
debug=false,
nerdfonts=false,
long_results=false,
result_text_len=80 * 4,
browser="",

load_boolean=function(self, input)
local str

if input == nil then return(false) end

str=string.lower(input)

if str == "y" then return(true)
elseif str == "yes" then return(true)
elseif str == "true" then return(true)
elseif str == "1" then return(true)
end

return(false)
end,


addkey=function(self, key, mod)
if strutil.strlen(key) > 0
then
  mod.api_key=key
end

end,


load_api_key=function(self, input)
local pos, name, value, source

pos=string.find(input, '=')
if pos ~= nil
then
  name=string.sub(input, 1, pos -1)
  value=string.sub(input, pos+1)
  value=strutil.stripQuotes(value)
  
  source=sources:get(name)
  if source ~= nil then source.api_key=value end
end

end,


load_config_file=function(self, dir)
local str, S

str=dir .. "netscry.conf"
S=stream.STREAM(str, "r")
if S ~= nil
then
  str=S:readln()
  while str ~= nil
  do
    str=strutil.trim(str)

    if string.sub(str, 1, 4) == "key:" then self:load_api_key(string.sub(str, 5)) 
    elseif string.sub(str, 1, 10) == "nerdfonts=" then self.nerdfonts=self:load_boolean(string.sub(str, 11))
    elseif string.sub(str, 1, 8) == "browser=" then self.browser=string.sub(str, 9)
    end
    str=S:readln()
  end
S:close()
end

end,



init=function(self)
local str

self:addkey(process.getenv("NETSCRY_ASKAI_APIKEY"), ask_ai)
self:addkey(process.getenv("NETSCRY_TAVILY_APIKEY"), tavily_ai)
self:addkey(process.getenv("NETSCRY_GEMINI_APIKEY"), google_ai)
self:addkey(process.getenv("NETSCRY_LANGSEARCH_APIKEY"), langsearch)

self:load_config_file("/etc/")
self:load_config_file(process.getenv("HOME") .. "/.config/netscry/")

end,


}


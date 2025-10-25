
interactive={

results_list=nil,


--name can be either the short or long name of the source
change_source=function(self, name)
if strutil.strlen(name) == 0 then return end

    self.source=sources:get_short(name)
    if self.source == nil then self.source=sources:get(name) end
    if self.source ~= nil then query.sources=self.source.name
    else Out:puts("~runknown source~0: '"..name.."'. Type  '/sources' to see list.\n")
    end

  if self.source ~= nil 
  then 
  Out:puts("Switching to: ~ename~0: ~e~c".. self.source.name .. "~0  type: ~e" .. tostring(self.source.type) .. "~0  ")
  if strutil.strlen(self.source.url) > 0 then Out:puts("~e~b" .. self.source.url.."~0  features: ") end
  if self.source.has_downloads==true then Out:puts("~edownloads~0,") end
  if self.source.has_top==true then Out:puts("~e'top' page~0,") end
  if self.source.has_top==true then Out:puts("~e'new' page~0,") end
  Out:puts("~0\n") 
  end


end,


build_prompt=function(self, active_sources)
local tok, toks
local prompt=""

toks=strutil.TOKENIZER(active_sources, "\\S")
tok=toks:next()
while tok
do
  source=sources:get(tok)
  if source ~= nil 
  then 
  if settings.nerdfonts == true then prompt=prompt .. " " .. icons:find(source.type) .. "  " .. source.short_name .. " " 
  else prompt=prompt .. " " .. source.short_name .. " "
  end
  end

  tok=toks:next()
end

--return "~Y~b" .. prompt.."~0~y~Ueb70~0 "

if settings.nerdfonts == true
then
return "~Y~b" .. prompt.."~0~y~Ue0b0~0 "
else
return prompt .. "> "
end

end,

--this function does not have 'self' object
--because it's used outside of this, or any
--object that could be 'self'
display_source_status=function(source)
local str

str=string.format("%5s %25s:", source.short_name, source.name)
if source.needs_api_key == true
then
  if strutil.strlen(source.api_key) > 0 then str=str.." ~gready~0"
  else str=str.." ~rno api key~0"
  end
else
  str=str.." ~gready~0"
end

Out:puts(str.."\n")
end,


download_item=function(self, item)
local url, parts, fname

      url=item.download

      if strutil.strlen(url) == 0
      then
      source=sources:get(item.source)
      if source ~= nil and source.get_download ~= nil then url=source:get_download(item)  end
      end


      if url ~= nil
      then
        parts=net.parseURL(url)
        fname=filesys.basename(parts.path)
        if strutil.strlen(fname) == 0 then fname=item.title end
        Download(url, fname)
      end

end,


download_items=function(self, toks)
local tok, pos, item

    tok=toks:next()
    while tok ~= nil
    do
       pos=tonumber(tok)
       if pos > 0
       then
         item=self.results_list[pos]
         self:download_item(item)
       end
       tok=toks:next()
    end
end,


view_page=function(self, toks)
local tok, pos, item

    tok=toks:next()
    while tok ~= nil
    do
       pos=tonumber(tok)
       if pos > 0
       then
         item=self.results_list[pos]
         if item ~= nil then ViewWebpage(item.url) end
       end
       tok=toks:next()
    end
end,


launch_program=function(self, toks)
local tok, pos, item, program

    pos=tonumber(toks:next())
    program=toks:remaining()

    if (pos > 0)
    then
         item=self.results_list[pos]
         if item ~= nil then ViewInBrowser(item.url, program) end
    end
end,



display_help=function(self)
print()
print("  type a command starting with '/', or a service shortname starting with '@' to switch service")
print("  otherwise type a line of text to send as a query to the current service")
print()
print("  commands:")
print("    @<short name>                - switch to datasource using it's short name, e.g. '@ddg'")
print("    /goto <short name>           - switch to datasource using it's short name, e.g. '/goto ddg'")
print("    /sources                     - list datasources")
print("    /info                        - display information about current source");
print("    /top                         - list 'top' results (e.g. flagged most popular) for datasources that support this");
print("    /new                         - list 'new' results (e.g. recent/today's news) for datasources that support this");
print("    /get <item id>               - download an item for datasources that support this")
print("    /view <item id>              - view details, or view URL of an item, for datasources that support this")
print("    /launch <item id>            - launch item url in default browser")
print("    /launch <item id> <program>  - launch item url with specified program")
print("    /help                        - list this help")
print("    /quit                        - exit program")
print()

end,



process_command=function(self, str)
local toks, tok, item, pos
local action=""

toks=strutil.TOKENIZER(str, "\\S")
if toks ~= nil
then
   tok=toks:next()
   if tok=="/goto" then self:change_source(toks:next())
   elseif tok=="/get" then self:download_items(toks) 
   elseif tok=="/view" then self:view_page(toks) 
   elseif tok=="/launch" then self:launch_program(toks) 
   elseif tok=="/top" then action="top"
   elseif tok=="/new" then action="new"
   elseif tok=="/info" then action="info"
   elseif tok=="/sources" then sources:iterate(self.display_source_status)
   elseif tok=="/debug" 
   then 
     if settings.debug == true then settings.debug=false
     else settings.debug=true
     Out:puts("debug: " .. tostring(settings.debug) .. "\n")
  end
   elseif tok=="/help" then self:display_help() 
   elseif tok=="/quit" then action="done"
   else Out:puts("~runrecognised command~0: "..tok.."\n")
   end
end

return action
end,


run=function(self, Out, query)
local prompt, str, action


sources:iterate(self.display_source_status)
self:change_source(query.source)


while true
do
  Out:puts("~etype /help for help~0\n")
  prompt=self:build_prompt(query.sources)
  str=Out:prompt(prompt)
  Out:puts("\n")

  if str=="quit" then break
  elseif string.sub(str, 1, 1)=="@" then self:change_source(string.sub(str, 2))
  elseif string.sub(str, 1, 1)=="/"
  then
      action=self:process_command(str)
      if action == "top" 
      then 
        query.question="!top"
        self.results_list=sources:query(query)
      elseif action == "new"
      then
        query.question="!new"
        self.results_list=sources:query(query)
      elseif action == "info"
      then
        query.question="!info"
        self.results_list=sources:query(query)
      elseif action == "done" then break
      end
  else
      query.question=strutil.trim(str)
      self.results_list=sources:query(query)
  end

end

end


}

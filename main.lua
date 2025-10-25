




terminal.utf8(3)
Out=terminal.TERM(NULL, "rawkeys save")

--use this user agent for all connections
process.lu_set("HTTP:UserAgent", "NetScry (1.0)")

-- sources must be set up before settings
sources:init()
settings:init()

act,query=ParseCommandLine(arg)

--process.lu_set("Debug", "Y")
if settings.debug == true then process.lu_set("HTTP:Debug", "Y") end
if strutil.strlen(settings.proxy) > 0 then net.setProxy(settings.proxy) end

if act == "help" then PrintHelp()
elseif act == "view_page" then ViewWebpage(query.url)
elseif act == "list_topics" then sources:list_topics(query)
else
  if strutil.strlen(query.question) > 0 then sources:query(query) 
  else interactive:run(Out, query)
end
end

Out:reset()
print()

function PrintHelp()

print("usage:")
print("   netscry.lua                                         - interactive mode")
print("   netscry.lua [options]                               - interactive mode")
print("   netscry.lua <service> <query string>                - send <query string> to service")
print("   netscry.lua [options] <service> <query string>      - send <query string> to service")
print("   netscry.lua -?                                      - this help")
print("   netscry.lua -h                                      - this help")
print("   netscry.lua -help                                   - this help")
print("   netscry.lua --help                                  - this help")
print()
print("services:")
print("   -ddg                                                - use duckduckgo");
print("   -ar                                                 - use archive.org");
print("   -ask                                                - use ask.ai");
print("   -askai                                              - use ask.ai");
print("   -tav                                                - use tavily.ai");
print("   -gem                                                - use google gemini-flash");
print("   -wp                                                 - use wikipedia");
print("   -ls                                                 - use langsearch");
print("   -so                                                 - use stackoverflow");
print("   -sx                                                 - use stackexchange");
print("   -dict                                               - use dictionary.dev");
print("   -bht                                                - use bighugethesaurus");
print("   -sfn                                                - use spaceflightnewsapi");
print("   -wn                                                 - use worldnewsapi");
print("   -gn                                                 - use gnews");
print("   -gnews                                              - use gnews");
print("   -hn                                                 - use hackernews");
print("   -bb                                                 - use bigbookapi");
print("   -db                                                 - use dbooks");
print("   -dbooks                                             - use dbooks");
print("   -ol                                                 - use openlibrary");
print("   -gb                                                 - use project gutenberg");
print("   -fo                                                 - use fossies");
print()
print("service options:")
print("   -n <max>                                            - maximum results to return (tavily.ai, bigbookapi, worldnewsapi, langsearch, gnews, hackernews)")
print("   -top                                                - return 'top' results (usually today's 'top' news) (gnews, worldnewsapi, hackernews)")
print("   -new                                                - return 'new' results (dbooks, hackernews)")
print("   -info                                               - return info about a source")
print("   -topic <topic>                                      - specify topic/category/subject for search (gnews, bigbookapi)")
print("   -t <topic>                                          - specify topic/category/subject for search (gnews, bigbookapi)")
print("   -list-topics                                        - print list of topics for specified source")
print("   -lang <iso code>                                    - specify language iso-code for search (gnews, worldnewsapi)")
print("   -l <iso code>                                       - specify language iso-code for search (gnews, worldnewsapi)")
print("   -country <country code>                             - specify country iso-code for search (gnews, worldnewsapi)")
print("   -c <country code>                                   - specify country iso-code for search (gnews, worknewsapi)")
print("   -item <id>                                          - specify item-id of specific item or article to lookup")
print("   -deep                                               - use deep/advanced search (tavily.ai)")
print()
print("general options:")
print("   -proxy <url>                                        - set proxy for network comms. e.g. '-proxy socks5:127.0.0.1:8080");
print("   -debug                                              - output debugging");
print("   -D                                                  - output debugging");
print("   -?                                                  - print this help");
print("   -help                                               - print this help");
print("   --help                                              - print this help");
end




function ParseCommandLine(cmd)
local arg, i, query
local act="query"

query=new_query()
for i,arg in ipairs(cmd)
do
  if arg=="-ddg" then query.sources=query.sources .. "duckduckgo "
  elseif arg=="-ar" then query.sources=query.sources .. "archive.org "
  elseif arg=="-ask" then query.sources=query.sources .. "ask_ai "
  elseif arg=="-askai" then query.sources=query.sources .. "ask_ai "
  elseif arg=="-tav" then query.sources=query.sources .. "tavily "
  elseif arg=="-gem" then query.sources=query.sources .. "gemini "
  elseif arg=="-wp" then query.sources=query.sources .. "wikipedia "
  elseif arg=="-so" then query.sources=query.sources .. "stackoverflow "
  elseif arg=="-ls" then query.sources=query.sources .. "langsearch "
  elseif arg=="-sx" then query.sources=query.sources .. "stackexchange "
  elseif arg=="-sfn" then query.sources=query.sources .. "spaceflightnewsapi "
  elseif arg=="-dict" then query.sources=query.sources .. "dictionary_dev "
  elseif arg=="-bht" then query.sources=query.sources .. "bighugethesaurus "
  elseif arg=="-wn" then query.sources=query.sources .. "worldnewsapi"
  elseif arg=="-bb" then query.sources=query.sources .. "bigbookapi"
  elseif arg=="-hn" then query.sources=query.sources .. "hackernews"
  elseif arg=="-gn" then query.sources=query.sources .. "gnews"
  elseif arg=="-gnews" then query.sources=query.sources .. "gnews"
  elseif arg=="-db" then query.sources=query.sources .. "dbooks"
  elseif arg=="-ol" then query.sources=query.sources .. "openlibrary"
  elseif arg=="-gb" then query.sources=query.sources .. "gutenberg"
  elseif arg=="-fo" then query.sources=query.sources .. "fossies"
  elseif arg=="-info" then query.question="!info" --anyting to do with sources goes through a query
  elseif arg=="-list-topics" then query.question="!topics" -- anything to do with sources goes through as a query
  elseif arg=="-top" then query.question="!top"
  elseif arg=="-new" then query.question="!new"
  elseif arg=="-l" or arg=="-lang"
  then
  query.language=cmd[i+1]
  cmd[i+1]=""
  elseif arg=="-c" or arg=="-country"
  then
  query.country=cmd[i+1]
  cmd[i+1]=""
  elseif arg=="-t" or arg=="-topic"
  then
  query.category=cmd[i+1]
  cmd[i+1]=""
  elseif arg=="-item"
  then
  query.item_id=cmd[i+1]
  query.question="!item"
  cmd[i+1]=""
  elseif arg=="-n"
  then 
  query.max_results=tonumber(cmd[i+1])
  cmd[i+1]=""
  elseif arg=="-view"
  then 
  act="view_page"
  query.url=cmd[i+1]
  cmd[i+1]=""
  elseif arg=="-proxy" 
  then 
  settings.proxy=cmd[i+1]
  cmd[i+1]=""
  elseif arg=="-deep" then query.search_level="deep"
  elseif arg=="-debug" then settings.debug=true
  elseif arg=="-l" then settings.long_results=true
  elseif arg=="-D" then settings.debug=true
  elseif arg=="-?" then act="help"
  elseif arg=="-h" then act="help"
  elseif arg=="-help" then act="help"
  elseif arg=="--help" then act="help"
  else
  query.question=query.question .. arg .. " "
  end
end

if strutil.strlen(query.sources) == 0 then query.sources="duckduckgo " end
query.question=strutil.trim(query.question)

return act, query
end




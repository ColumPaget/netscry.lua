
sources={
list={},
last_search_results={},

add=function(self, name, item)

if strutil.strlen(name) == 0 then OutputError("????", "attempt to add datasource with no name")
elseif item==nil then OutputError(name, "attempt to add datasource with no implementation object")
else self.list[name]=item
end

end,


get=function(self, name)
item=self.list[name]
if item== nil then item=self:get_short(name) end
return(item)
end,


get_short=function(self, name)
local key, item

for key,item in pairs(self.list)
do
  if item.short_name == name then return item end
end

return nil
end,


iterate=function(self, func)
local key, item

for key,item in pairs(self.list)
do
  func(item)
end

end,


source_check_category=function(self, source, query)

    if strutil.strlen(query.category) == 0 then return true end

    if source.categories == nil then return true end

    for i,item in ipairs(source.categories)
    do
      if item==query.category then return true end
    end

    return false
end,


query_source_api=function(self, source, query)
local response

if source ~= nil
then
  if source.needs_api_key == true and strutil.strlen(source.api_key) == 0
  then
  OutputError(source.name, "no API key")
  else
    if self:source_check_category(source, query) == false then Out:puts("\r~yWARNING~0: '" .. query.category .. "' is not a known category for source '" .. source.name .. "'.\n") end
    Out:puts("\r~gQUERY: " .. source.name .. "~0  '"..query.question.."'\n")
    response=source:query(query)
  end
 else OutputError(source.name, "Unknown source")
end


return response, source
end,


query_source=function(self, source, query)
local response, i, answer

  response=self:query_source_api(source, query)
  if response ~= nil
  then 
      OutputResponse(response, source) 
      if response.search_results ~= nil 
      then
      for i,answer in ipairs(response.search_results) do table.insert(self.last_search_results, answer) end
      end
  else OutputError(source.name, "No response to query")
  end

end,

output_source_topics=function(self, source)
local str, i, item

if source.categories ~= nil
then 
  str="~eknown topics~0: "
  for i,item in ipairs(source.categories) do str=str..item..", " end
  Out:puts(str .. "\n")
else Out:puts("source has no topics\n")
end

end,



output_source_info=function(self, source)
local str

Out:puts("~ename~0: ~e~c"..source.name.."~0  ~eshort name~0: "..source.short_name .. " ~etype~0: " .. source.type .."\n")
if strutil.strlen(source.url) > 0 then Out:puts("~ehome url~0: ~e~b" .. source.url.."~0\n") end

str="~e" .. "api-key needed" .. "~0: "
if source.needs_api_key ==true 
then 
   if strutil.strlen(source.api_key) > 0 then str=str.. "~g yes - present ~0 ".. source.api_key
   else str=str .. "~r yes - missing ~0"
   end
else str=str .. "~g no ~0"
end
Out:puts(str.."\n")

if source.has_top == true then Out:puts("~ehas 'top' items listing~0: ~gyes~0\n")
else Out:puts("~ehas 'top' items listing~0: no\n")
end

if source.has_new == true then Out:puts("~ehas 'new' items listing~0: ~gyes~0\n")
else Out:puts("~ehas 'new' items listing~0: no\n")
end

if source.has_details == true then Out:puts("~ehas item detail view~0: ~gyes~0\n")
else Out:puts("~ehas item detail views~0: no\n")
end

if source.has_downloads == true then Out:puts("~ehas downloads~0: ~gyes~0\n")
else Out:puts("~ehas downloads~0: no\n")
end

self:output_source_topics(source)
end,


query=function(self, query)
local toks, tok, source

toks=strutil.TOKENIZER(query.sources, "\\S")
tok=toks:next()
while tok ~= nil
do
  source=self:get(tok)
  if source ~= nil
  then
    if query.question == "!info" then self:output_source_info(source) 
    elseif query.question == "!topics" then self:output_source_topics(source) 
    else self:query_source(source, query)
    end
  end

  tok=toks:next()
end

return self.last_search_results
end,





init=function(self)
self:add("duckduckgo", duckduckgo)
self:add("wikipedia", wikipedia)
self:add("langsearch", langsearch)
self:add("stackexchange", stackexchange)
self:add("ask_ai", ask_ai)
self:add("gemini", google_ai)
self:add("tavily", tavily)
self:add("dictionary_dev", dictionary_dev)
self:add("bighugethesaurus", bighugethesaurus)
self:add("worldnewsapi", worldnewsapi)
self:add("bigbookapi", bigbookapi)
self:add("gnews", gnews)
self:add("hackernews", hackernews)
self:add("fossies", fossies)
self:add("dbooks", dbooks)
self:add("openlibrary", openlibrary)
self:add("gutenberg", gutenberg)
self:add("spaceflightnewsapi",  spaceflightnewsapi)
self:add("archive.org",  archive_org)
end,

}

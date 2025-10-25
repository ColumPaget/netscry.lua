langsearch={

name="langsearch",
type="search",
short_name="ls",
needs_api_key=true,
url="https://langsearch.com/",

parse_item=function(self, results, item)
local result={}

result.source=self.name
result.url=item:value("url")
result.title=item:value("name") 
-- .. ":" ..  strutil.unQuote(item:value("snippet"))
result.content=strutil.unQuote(item:value("summary"))

table.insert(results, result)
end,


query=function(self, query)
local str, S, doc, JSON, items, item, qcount
local response

response={}
response.source=self.name
response.answer=""
response.query=query.question
response.search_results={}

if query.max_results == nil then qcount=10
else qcount=query.max_results
end

str="{\"query\": \""..query.question.."\", \"freshness\": \"noLimit\", \"summary\": true,\"count\": "..qcount.."}"
len=strutil.strlen(str)
S=stream.STREAM("https://api.langsearch.com/v1/web-search", "w Authorization='Bearer "..self.api_key.."' Content-Type=application/json Content-Length=" .. tostring(len))
if S ~= nil
then
S:writeln(str)
S:commit()
doc=S:readdoc()
S:close()
end

if settings.debug == true then io.stderr:write(doc.."\n") end

JSON=dataparser.PARSER("json", doc)
if JSON ~= nil
then
  items=JSON:open("data/webPages/value")
  item=items:next()
  while item ~= nil
  do
  self:parse_item(response.search_results, item)
  item=items:next()
  end
end

return response
end

}

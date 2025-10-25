

duckduckgo={

name="duckduckgo",
short_name="ddg",
type="search",
needs_api_key=false,
url="https://duckduckgo.com",



parse_result=function(self, XML)
local tag
local result={}

result.source=self.name
result.content_is_html=true
result.content=""

tag=XML:next()
while tag ~= nil
do
if tag.type=="/h2" then break
elseif tag.type=="a" then result.url="https:"..ExtractNameValue(tag.data, "href")
elseif tag.type==nil then result.title=tag.data
end

tag=XML:next()
end

return result
end,


query=function(self, query)
local S, str, doc, XML, item
local response={}

response.source=self.name
response.query=query.question
response.search_results={}

str="https://html.duckduckgo.com/html?q=" .. strutil.httpQuote(query.question) .."&t=h_&ia=web"
S=stream.STREAM(str, "r Accept=*/*")
if S ~= nil
then
doc=S:readdoc()
S:close()

if settings.debug == true then io.stderr:write(doc.."\n") end

XML=xml.XML(doc)
item=XML:next()
while item ~= nil
do
  
  if item.type == "h2" and item.data == "class=\"result__title\""
  then
  result=self:parse_result(XML)
  table.insert(response.search_results, result)
  elseif item.type == "a" 
  then
    str=ExtractNameValue(item.data, "class")
    if str == "result__snippet" then result.content=HtmlConsumeToTag(XML, "/a") end
  end

item=XML:next()
end
end

return(response)
end,
}



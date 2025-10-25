

-- https://en.wikipedia.org/w/api.php?action=help&modules=query


wikipedia={

name="wikipedia",
short_name="wp",
type="search",
needs_api_key=false,
url="https://wikipedia.org/",


add_result=function(self, search_results, title, id, content)
local result={}

result.source=self.name
result.title=title
result.id=id
result.content=content

-- if #search_results == 0 then result.answer=strutil.htmlUnQuote(item:value("export/*")) end

table.insert(search_results, result)
end,

parse_result=function(self, search_results, item)
local extract

extract=item:value("extract")
self:add_result(search_results, item:value("title"), item:value("pageid"), extract)

end,



find_disambiguation_prop=function(self, P)
local props, item

props=P:open("pageprops")
if props ~= nil
then
  item=props:next()
  while item ~= nil
  do
    if item:name() == "disambiguation" then return true end
    item=props:next()
  end
end

return false
end,


is_disambiguation=function(self, P)
local pages, props, item

pages=P:open("query/pages")
if pages ~= nil
then
item=pages:next()
while item ~= nil
do
if self:find_disambiguation_prop(item) == true then return true end
item=pages:next()
end
end

return false
end,


parse_disambiguation=function(self, P, response)
local XML, item

XML=xml.XML(P:value("query/export/*"))
if XML ~= nil
then
  item=XML:next()
  while item ~= nil
  do
    if item.type == "text"
    then
    item=XML:next()
    self:add_result(response.search_results, "~rDisambiguation Page~0", "", strutil.htmlUnQuote(item.data))
    end
    item=XML:next()
  end
end

end,


parse_page=function(self, P, response)
local pages, item

--response.answer=strutil.htmlUnQuote(P:value("query/export/*"))
pages=P:open("query/pages")

item=pages:next()
while item ~= nil
do
self:parse_result(response.search_results, item, answer)
item=pages:next()
end

return(response)
end,


send_query=function(self, props, question)
local str, doc, S, P

str="https://en.wikipedia.org/w/api.php?format=json&action=query&prop="..props.."&exintro=true&explaintext=true&export=false&redirects=1&titles=" .. strutil.httpQuote(question) 
if settings.debug == true then io.stderr:write("SEND: " .. str .."\n") end


S=stream.STREAM(str, "r Accept=*/*")
if S==nil
then
print("ERROR: Query failed to en.wikipedia.org")
else
doc=S:readdoc()
if settings.debug == true then io.stderr:write(doc.."\n") end
P=dataparser.PARSER("json", doc)
S:close()
end

return P
end,


query=function(self, query)
local S, str, doc, P, pages
local response={}

response.source=self.name
response.query=query.question
response.search_results={}


P=self:send_query("pageprops", query.question)
if self:is_disambiguation(P) == true
then
self:parse_disambiguation(P, response)
else
P=self:send_query("extracts", query.question)
self:parse_page(P, response)
end

return response
end,
}



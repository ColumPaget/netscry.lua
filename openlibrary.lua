
openlibrary={

name="openlibrary",
short_name="ol",
type="book",
needs_api_key=false,
has_downloads=true,
url="https://openlibrary.org/",


parse_item=function(self, results, json) 
local result={}
local items, item

result.source=self.name
result.content_is_html = true
result.id=json:value("key")
result.title=json:value("title")
if strutil.strlen(json:value("subtitle")) > 0 then result.title=result.title .. " - " .. json:value("subtitle") end
result.date=json:value("first_publish_year")
result.image=json:value("image")

result.author=""
items=json:open("author_name")
if items ~= nil
then
  item=items:next()
  while item ~= nil
  do
    result.author=result.author .. item:value() ..", "
    item=items:next()
  end
end

result.url=""
items=json:open("ia")
if items ~= nil
then
  item=items:next()
  while item ~= nil
  do
    result.url=result.url .. "https://archive.org/metadata/" .. item:value() ..", "
    item=items:next()
  end
end


table.insert(results, result)

end,


parse_search_response=function(self, search_results, query_details, JSON)
local results, item, items, subitems

if JSON ~= nil
then
  items=JSON:open("docs")
  if items ~= nil 
  then
     item=items:next()
     while item ~= nil
     do
       self:parse_item(search_results, item)
       item=items:next()
     end
  end
end
  

end,



parse_book=function(self, query_details, JSON)
local items, item, str

str="~ybook~0: ~c~" .. JSON:value("id") .. "~0 ~e" .. JSON:value("title") .. "~0 ~ypublisher~0: " .. JSON:value("publisher") .. "~0 ~ypublished~0: " .. JSON:value("year") .. " ~ypages~0: ".. string.format("%d", tonumber(JSON:value("pages"))).."\n"

str=str .. "~yauthors~0: " .. JSON:value("authors") .. "\n"

str=str .. "~yurl~0: ~e~b" .. JSON:value("url") .. "~0\n"
str=str .. "~yimage url~0: ~e~b" .. JSON:value("image") .. "~0\n"
str=str .. "~ydownload url~0: ~e~b" .. JSON:value("download") .. "~0\n"

str=str .. JSON:value("description") .. "\n"


return str
end,



query_api=function(self, query_details,  url)
local S, doc
local response

S=stream.STREAM(url, "")

if S ~= nil
then

response={}
response.query=query_details.question
response.source=self.name
response.search_results={}
response.quota_used=S:getvalue("HTTP:X-Api-Quota-Used")
response.quota_remain=S:getvalue("HTTP:X-Api-Quota-Left")

doc=S:readdoc()
S:close()

if settings.debug == true then io.stderr:write(doc.."\n") end

JSON=dataparser.PARSER("json", doc)
end


return response,JSON
end,


query=function(self, query_details)
local url, response, JSON


   url="https://www.openlibrary.org/search.json?q=" .. strutil.httpQuote(query_details.question)
   response, JSON = self:query_api(query_details, url)
   self:parse_search_response(response.search_results, query_details, JSON)


return response
end

}

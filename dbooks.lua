
dbooks={

name="dbooks",
short_name="db",
type="book",
needs_api_key=false,
has_downloads=true,
has_details=true,
has_new=true,
url="https://dbooks.org/",


item_details=function(self, item_id)
local url, response, JSON

url="https://www.dbooks.org/api/book/" .. item_id 
response, JSON = self:query_api(url)

return response, JSON
end,



get_download=function(self, item)
local response, JSON

if strutil.strlen(item.download) > 0 then return item.download end

response, JSON=self:item_details(item.id)

return JSON:value("download")
end,


parse_item=function(self, results, item)
local result={}

result.content_is_html = true
result.id=item:value("id")
result.title=item:value("title")
if strutil.strlen(item:value("subtitle")) > 0 then result.title=result.title .. " - " .. item:value("subtitle") end
result.url=item:value("url")
result.image=item:value("image")
result.author=item:value("authors")
result.source=self.name

table.insert(results, result)

end,


parse_search_response=function(self, search_results, query_details, JSON)
local results, item, items, subitems

if JSON ~= nil
then
  if JSON:value("status") ~= "ok"
  then
      Out:puts("~rERROR~0:" .. JSON:value("status") .. "\n")
  else
  items=JSON:open("books")
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



query_api=function(self, url)
local S, doc
local response

S=stream.STREAM(url, "")

if S ~= nil
then

response={}
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


if query_details.item_id ~= nil
then
   response, JSON = self:item_details(query_details.item_id)
   response.answer=self:parse_book(query_details, JSON)
elseif query_details.question == "!new" 
then
   url="https://www.dbooks.org/api/recent"
   response, JSON = self:query_api(url)
   self:parse_search_response(response.search_results, query_details, JSON)
else
   url="https://www.dbooks.org/api/search/" .. strutil.httpQuote(query_details.question)
   response, JSON = self:query_api(url)
   self:parse_search_response(response.search_results, query_details, JSON)
end

if response ~= nil then response.query=query_details.question end

return response
end

}

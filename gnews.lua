
gnews={

name="gnews",
short_name="gn",
type="news",
has_top=true,
needs_api_key=true,
url="https://gnews.io/",
categories={"general", "world", "nation", "business", "technology", "entertainment", "sports", "science", "health"},


parse_item=function(self, results, item)
local result={}

result.source=self.name
result.content_is_html = true
result.id=item:value("id")
result.title=item:value("title")
result.description=item:value("description")
result.content=item:value("content")
result.image=item:value("image")
result.video=item:value("video")
result.url=item:value("url")
result.author=item:value("source/name") .. " - " .. item:value("source/url")
result.date=item:value("publishedAt")
result.language=item:value("language")
result.country=item:value("source_country")

table.insert(results, result)

end,




parse=function(self, response, query_details, doc)
local JSON, results, item, items, articles


JSON=dataparser.PARSER("json", doc)
if JSON ~= nil
then
  
items=JSON:open("articles")
if items ~= nil 
then
   item=items:next()
   while item ~= nil
   do
     self:parse_item(response.search_results, item)
     item=items:next()
   end
end
 
end

end,


query=function(self, query_details)
local S, url, doc, str
local response

if strutil.strlen(query_details.question) ==0 or query_details.question == "!top" 
then 
   url="https://gnews.io/api/v4/top-headlines?apikey=" .. self.api_key
   if query_details.category ~= nil then url=url .. "&category=" .. query_details.category end
else url="https://gnews.io/api/v4/search?apikey=" .. self.api_key .. "&q=" .. strutil.httpQuote(query_details.question)
end

if query_details.country ~= nil then url = url ..  "&country=" .. query_details.country end
if query_details.language ~= nil then url = url .. "&lang=" .. query_details.language end
if query_details.max_results ~= nil then url=url .. "&max="..query_details.max_results end

S=stream.STREAM(url, "")

if S ~= nil
then
response={}
response.query=query_details.question
response.source=self.name
response.quota_used=S:getvalue("HTTP:X-Api-Quota-Used")
response.quota_remain=S:getvalue("HTTP:X-Api-Quota-Left")
response.search_results={}

doc=S:readdoc()
S:close()

if settings.debug == true then io.stderr:write(doc.."\n") end

self:parse(response, query_details, doc)
end

return response
end

}

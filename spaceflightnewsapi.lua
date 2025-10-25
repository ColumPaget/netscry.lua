
spaceflightnewsapi={

name="spaceflightnewsapi",
short_name="sfn",
has_top=true,
type="news",
needs_api_key=false,
url="https://spaceflightnewsapi.com/",




parse_item=function(self, response, JSON)
local item

item={}
item.source=self.name
item.id=JSON:value("id")
item.title=JSON:value("title")
item.description=JSON:value("summary")
item.author=JSON:value("news_site")
--item.author=JSON:value("by")
item.url=JSON:value("url")
item.image=JSON:value("image_url")
item.date=time.format("%Y-%m-%d %H:%M:%S", tonumber(JSON:value("published_at")))
table.insert(response.search_results, item)

end,
 

parse=function(self, response, query_details, doc)
local JSON, item, items
local count=0
local max=10


JSON=dataparser.PARSER("json", doc)
if JSON ~= nil
then
    items=JSON:open("results")
    item=items:next()
    while item ~= nil
    do
      self:parse_item(response, item)
      item=items:next()
    end
end

 
end,



query=function(self, query_details)
local S, url, doc, str
local response

if strutil.strlen(query_details.question) ==0 or query_details.question == "!top" then url="https://api.spaceflightnewsapi.net/v4/articles?"
else url="https://api.spaceflightnewsapi.net/v4/articles?search=" .. strutil.httpQuote(query.question)
end

if query_details.max_results ~= nil then url=url .. "&limit="..query_details.max_results end

S=stream.STREAM(url, "")

if S ~= nil
then
response={}
response.query=query_details.question
response.source=self.name
response.search_results={}
doc=S:readdoc()
S:close()

if settings.debug == true then io.stderr:write(doc.."\n") end

self:parse(response, query_details, doc)
end

return response
end

}

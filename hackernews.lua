
hackernews={

name="hackernews",
short_name="hn",
type="news",
has_top=true,
has_new=true,
needs_api_key=false,
url="https://hackernews.com/",




get_article=function(self, response, id)
local S, article, doc, JSON

S=stream.STREAM("https://hacker-news.firebaseio.com/v0/item/"..id..".json?print=pretty", "")
if S ~= nil
then
doc=S:readdoc()
S:close()

if settings.debug == true then io.stderr:write(doc.."\n") end
JSON=dataparser.PARSER("json", doc)
article={}
article.source=self.name
article.id=id
article.title=JSON:value("title")
article.author=JSON:value("by")
article.url=JSON:value("url")
article.date=time.format("%Y-%m-%d %H:%M:%S", tonumber(JSON:value("time")))
table.insert(response.search_results, article)
end

end,
 

parse=function(self, response, query_details, doc)
local JSON, item
local count=0
local max=10

if query_details.max_results ~= nil then max=query_details.max_results end

JSON=dataparser.PARSER("json", doc)
if JSON ~= nil
then
    item=JSON:next()
    while item ~= nil
    do
      self:get_article(response, item:value())
      count=count+1
      if count > max then break end
      item=JSON:next()
    end
end

 
end,



query=function(self, query_details)
local S, url, doc, str
local response


if strutil.strlen(query_details.question) ==0 or query_details.question == "!top" then url="https://hacker-news.firebaseio.com/v0/topstories.json?print=pretty"
elseif query_details.question == "!new" then url="https://hacker-news.firebaseio.com/v0/newstories.json?print=pretty"
else url="https://hacker-news.firebaseio.com/v0/beststories.json?print=pretty"
end

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

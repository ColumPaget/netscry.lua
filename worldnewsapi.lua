
worldnewsapi={

name="worldnewsapi",
short_name="wn",
type="news",
needs_api_key=true,
has_top=true,
url="https://worldnewsapi.com/",

--"url":"https://economictimes.indiatimes.com/news/international/global-trends/musk-took-leased-cars-back-so-tesla-could-use-them-as-robotaxis-instead-tesla-sold-them/articleshow/121187891.cms","image":"https://img.etimg.com/thumb/msid-121187941,resizemode-4,width-1200,height-900,imgsize-22582,overlay-economictimes/articleshow.jpg","video":null,"publish_date":"2025-05-15 11:07:05","author":"Reuters","authors":["Reuters"],"language":"en","source_country":"in","sentiment":-0.557},{"id":322254812,"title":"We put Tesla's FSD and Waymo's robotaxi to the test. One shocking mistake made the winner clear.","text":"


parse_item=function(self, results, item)
local result={}

result.source=self.name
result.content_is_html = true
result.id=item:value("id")
result.title=item:value("title")
result.content=item:value("text")
result.url=item:value("url")
result.image=item:value("image")
result.video=item:value("video")
result.author=item:value("author")
result.date=item:value("publish_date")
result.language=item:value("language")
result.country=item:value("source_country")

table.insert(results, result)

end,


output_articles=function(self, response, items)
local item

item=items:next()
while item ~= nil
do
  self:parse_item(response.search_results, item)
  item=items:next()
end

end,
 
parse=function(self, response, query_details, doc)
local JSON, results, item, items, articles


JSON=dataparser.PARSER("json", doc)
if JSON ~= nil
then
  
items=JSON:open("news")
if items == nil 
then
    
    -- an ugly dance. for 'top news' the news items are in an array called 'news' within the first item of the top-level array 'top_news' 
    items=JSON:open("top_news")
    items=items:next()
    while items ~= nil
    do
      articles=items:open("news")
      self:output_articles(response, articles)
      items=items:next()
    end
    
else 
  self:output_articles(response, items)
end

 
end

end,


query=function(self, query_details)
local S, url, doc, str
local country, language
local response

if strutil.strlen(query_details.question) ==0 then url="https://api.worldnewsapi.com/top-news?api-key=" .. self.api_key .. "&source-country="..query_details.country.."&language="..query_details.language
elseif query_details.question == "!top" then url="https://api.worldnewsapi.com/top-news?api-key=" .. self.api_key .. "&source-country="..query_details.country.."&language="..query_details.language

else url="https://api.worldnewsapi.com/search-news?api-key=" .. self.api_key .. "&text=" .. strutil.httpQuote(query_details.question)
end

if query_details.max_results ~= nil then url=url .. "&number="..query_details.max_results end

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

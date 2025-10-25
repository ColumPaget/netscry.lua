
gutenberg={

name="gutenberg",
short_name="gb",
type="book",
needs_api_key=false,
has_downloads=true,
url="https://gutenberg.org/",


parse_item=function(self, results, json) 
local result={}
local items, item

result.source=self.name
result.content_is_html = true
result.id=json:value("id")
result.title=json:value("title")
if strutil.strlen(json:value("subtitle")) > 0 then result.title=result.title .. " - " .. json:value("subtitle") end

result.author=""
items=json:open("authors")
if items ~= nil
then
  item=items:next()
  while item ~= nil
  do
    result.author=result.author .. item:value("name") .." (" ..item:value("birth_year") .. "-".. item:value("death_year") .."), "
    item=items:next()
  end
end


result.content=""
items=json:open("summaries")
if items ~= nil
then
  item=items:next()
  while item ~= nil
  do
    result.content=result.content .. item:value() .."   "
    item=items:next()
  end
end


-- formats":{"text/html":"https://www.gutenberg.org/ebooks/31214.html.images","text/html; charset=iso-8859-1":"https://www.gutenberg.org/files/31214/31214-h/31214-h.htm","application/epub+zip":"https://www.gutenberg.org/ebooks/31214.epub3.images","application/x-mobipocket-ebook":"https://www.gutenberg.org/ebooks/31214.kf8.images","text/plain; charset=us-ascii":"https://www.gutenberg.org/ebooks/31214.txt.utf-8","text/plain; charset=iso-8859-1":"https://www.gutenberg.org/files/31214/31214-8.txt","application/rdf+xml":"https://www.gutenberg.org/ebooks/31214.rdf","image/jpeg":"https://www.gutenberg.org/cache/epub/31214/pg31214.cover.medium.jpg","application/octet-stream":"https://www.gutenberg.org/cache/epub/31214/pg31214-h.zip"}

items=json:open("formats")
if items ~= nil
then
  item=items:next()
  while item ~= nil
  do
    if item:name()=="image/jpeg" then result.image=item:value()
    elseif item:name()=="text/html" then result.url=item:value()
    elseif item:name()=="application/epub+zip" then result.download=item:value()
    end
    item=items:next()
  end
end


table.insert(results, result)

end,


parse_search_response=function(self, search_results, query_details, JSON)
local results, item, items, subitems

if JSON ~= nil
then
  items=JSON:open("results")
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

doc=S:readdoc()
S:close()

if settings.debug == true then io.stderr:write(doc.."\n") end

JSON=dataparser.PARSER("json", doc)
end


return response,JSON
end,


query=function(self, query_details)
local url, response, JSON


   url="https://gutendex.com/books?search=" .. strutil.httpQuote(query_details.question)
   response, JSON = self:query_api(query_details, url)
   self:parse_search_response(response.search_results, query_details, JSON)


return response
end

}

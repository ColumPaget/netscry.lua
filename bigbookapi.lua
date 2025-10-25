
--example JSON response to the query 'simd'
-- {"available":37,"number":10,"offset":0,"books":[[{"id":24612860,"title":"SIMD Programming Manual for Linux and Windows","image":"https://covers.openlibrary.org/b/id/8719695-M.jpg"}],[{"id":23046058,"title":"SIMD Programming Manual for Linux and Windows (Springer Professional Computing)","image":"https://covers.openlibrary.org/b/id/2045444-M.jpg"}],[{"id":13942316,"title":"32/64-bit 80x86 Assembly Language Architecture","image":"https://covers.openlibrary.org/b/id/10919142-M.jpg"}],[{"id":14454624,"title":"Software Vectorization Handbook, The","subtitle":"Applying Intel Multimedia Extensions for Maximum Performance","image":"https://covers.openlibrary.org/b/id/2720641-M.jpg"}],[{"id":19421384,"title":"Vector Games Math Processors (Wordware Game Math Library)","image":"https://covers.openlibrary.org/b/id/776992-M.jpg"}],[{"id":20460576,"title":"Data-parallel programming on MIMD computers","image":"https://covers.openlibrary.org/b/id/2341656-M.jpg"}],[{"id":19288396,"title":"The SIMD Model of Parallel Computation","image":"https://covers.openlibrary.org/b/id/4613294-M.jpg"}],[{"id":16777368,"title":"Processor microarchitecture","subtitle":"an implementation perspective","image":"https://covers.openlibrary.org/b/id/8710255-M.jpg"}],[{"id":18366832,"title":"Learn Vertex & Pixel Shader Programming with DirectX 9","image":"https://covers.openlibrary.org/b/id/1874077-M.jpg"}],[{"id":16917598,"title":"Software Optimization Cookbook","subtitle":"High-Performance Recipes for the Intel Architecture","image":"https://covers.openlibrary.org/b/id/2713965-M.jpg"}]]}




bigbookapi={

name="bigbookapi",
short_name="bb",
type="book",
needs_api_key=true,
url="https://bigbookapi.com/",
has_details=true,

categories={"action", "adventure", "anthropology", "astronomy", "archaeology", "architecture", "art", "aviation", "biography", "biology", "business", "chemistry", "children", "classics", "contemporary", "cookbook", "crafts", "crime", "dystopia", "economics", "education", "engineering", "environment", "erotica", "essay", "fairy_tales", "fantasy", "fashion", "feminism", "fiction", "finance", "folklore", "food", "gaming", "gardening", "geography", "geology", "graphic_novel", "health", "historical", "historical_fiction", "history", "horror", "how_to", "humor", "inspirational", "journalism", "law", "literary_fiction", "literature", "magical_realism", "manga", "martial_arts", "mathematics", "medicine", "medieval", "memoir", "mystery", "mythology", "nature", "nonfiction", "novel", "occult", "paranormal", "parenting", "philosophy", "physics", "picture_book", "poetry", "politics", "programming", "psychology", "reference", "relationships", "religion", "romance", "science_and_technology", "science_fiction", "self_help", "short_stories", "society", "sociology", "space", "spirituality", "sports", "text_book", "thriller", "travel", "true_crime", "war", "writing", "young_adult"},



-- this parses info on an individual book if we look that up with an item-id
parse_book_details=function(self, query_details, JSON)
local items, item, str

str="~ybook~0: ~c~" .. JSON:value("id") .. "~0 ~e" .. JSON:value("title")
if JSON:value("publish_date") ~= nil then str = str .. "~0 ~ypublished~0: " .. JSON:value("publish_date") end


if tonumber(JSON:value("number_of_pages")) ~= nil then str = str .. " ~ypages~0: ".. string.format("%d", tonumber(JSON:value("number_of_pages"))) end
str=str .. "\n"

str=str .. "~yauthors~0: "
items=JSON:open("authors")
item=items:next()
while item ~= nil
do
str=str .. "~c" .. item:value("id") .. "~0 - " .. item:value("name") .. ", "
item=items:next()
end
str=str .. "\n"

str=str .. "~yidentifiers~0: "
items=JSON:open("identifiers")
item=items:next()
while item ~= nil
do
str=str .. "~c" .. item:name() .. "~0 - " .. item:value() .. ", "
item=items:next()
end
str=str .. "\n"


str=str .. "~yimage url~0: ~e~b" .. JSON:value("image") .. "~0\n"
str=str .. JSON:value("description") .. "\n"

return str
end,




-- this parses a search result, these usually contain less info than a detailed item lookup
parse_search_item=function(self, results, json)
local subitems, item
local result={}

result.source=self.name
result.content_is_html = true
result.author=""
result.identifiers=""

result.id=json:value("id")
result.title=json:value("title")
if strutil.strlen(json:value("subtitle")) > 0 then result.title=result.title .. " - " .. json:value("subtitle") end
result.content=json:value("description")
result.image=json:value("image")
result.date=json:value("publish_date")
result.language=json:value("language")
result.country=json:value("source_country")

--authors and identifiers probably won't be returned in a search result
subitems=json:open("authors")
if subitems ~= nil
then
item=subitems:next()
while item ~= nil
do
result.author=result.author .. item:value("name")..", "
item=subitems:next()
end
end

subitems=json:open("identifiers")
if subitems ~= nil
then
item=subitems:next()
while item ~= nil
do
result.identifiers = result.identifiers .. json:name() .. ":" .. json:value() .. ", "
item=subitems:next()
end
end

table.insert(results, result)

end,


parse_search_response=function(self, search_results, query_details, JSON)
local results, item, items, subitems


if JSON ~= nil
then
  if JSON:value("status") == "failure"
  then
      Out:puts("~rERROR~0:" .. JSON:value("message") .. "\n")
  else
  items=JSON:open("books")
  if items ~= nil 
  then
     item=items:next()
     while item ~= nil
     do
   
       if item:type() == "array"
       then
       subitems=item:subitems()
       item=subitems:next()
       self:parse_search_item(search_results, item)
       else
       self:parse_search_item(search_results, item)
       end
   
       item=items:next()
     end
  end
  end
  
end

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


if  query_details.item_id ~= nil
then
   url="https://api.bigbookapi.com/" .. query_details.item_id .. "?api-key=" .. self.api_key 
   response, JSON = self:query_api(query_details, url)
   response.answer=self:parse_book_details(query_details, JSON)
else
   url="https://api.bigbookapi.com/search-books?api-key=" .. self.api_key .. "&query=" .. strutil.httpQuote(query_details.question)
   if query_details.max_results ~= nil then url=url .. "&number="..query_details.max_results end
   if query_details.category ~= nil then url=url .. "&genres="..query_details.category end
   response, JSON = self:query_api(query_details, url)
   self:parse_search_response(response.search_results, query_details, JSON)
end


return response
end

}

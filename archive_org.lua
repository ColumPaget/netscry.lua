
archive_org={

name="archive.org",
short_name="ar",
type="search",
needs_api_key=false,
has_downloads=true,
url="https://archive.org/",
categories={"texts", "audio", "video", "movies", "software", "image", "data"},


url_append_fields=function(self, fields)
local params=""
local toks, tok

toks=strutil.TOKENIZER(fields, ",")
tok=toks:next()
while tok ~= nil
do
params=params .. "&fl[]=" ..tok
tok=toks:next()
end

return params
end,


send_query=function(self, query)
local S, doc, JSON, url, querystr 


querystr=query.question
if strutil.strlen(query.category) > 0 then querystr=querystr .." AND mediatype:(" .. query.category .. ")" end

url="https://archive.org/advancedsearch.php?q=" .. strutil.httpQuote(querystr) 
url=url .. self:url_append_fields("identifier,mediatype,title,description,subject,members,language,date,format,audio_codec,video_codec")
url=url .. "&rows=50&page=1&output=json&save=no"

if settings.debug == true then io.stderr:write("URL:" .. url.."\n") end

S=stream.STREAM(url, "");
if S ~= nil
then
doc=S:readdoc()
S:close()

if settings.debug == true then io.stderr:write(doc.."\n") end
JSON=dataparser.PARSER("json", doc)
end

return JSON
end,


is_codec=function(self, mediatype, item)

if item == "Metadata" then return false end
if item == "Archive BitTorrent" then return false end
if item == "Item Tile" then return false end
if item == "Columbia Peaks" then return false end

if mediatype ~= "image"
then
if item == "PNG" then return false end
if item == "Spectrogram" then return false end
end

return true
end,


parse_codecs=function(self, json)
local items, item
local codecs=""

items=json:open("format")
if items ~= nil
then
  item=items:next()
  while item ~= nil
  do
  if self:is_codec(json:value("mediatype"), item:value()) == true then codecs=codecs..item:value() .. "," end
  item=items:next()
  end
end

return codecs
end,


parse_item=function(self, results, json) 
local result={}
local items, item

result.source=self.name
result.content_is_html = true
result.id=json:value("identifier")
result.title=json:value("title")
result.content=json:value("description")
result.date=json:value("date")
result.mediatype=json:value("mediatype")
result.codecs=self:parse_codecs(json)
result.language=json:value("language")
result.image=json:value("image")

table.insert(results, result)

end,

consider_download=function(self, selected, item)
local preference={"PNG", "ZIP", "VBR MP3", "Ogg Vorbis"}
local exist_pref=-1
local new_pref=-1
local codec

codec=item:value("format")
if self:is_codec(codec) == false then return selected end

if selected == nil then selected={}
else exist_pref=ArrayFind(preference, selected.codec) 
end

new_pref=ArrayFind(preference, codec)

if new_pref > exist_pref
then
selected.codec=codec
selected.name=item:value("name")
end

return selected
end,


get_download=function(self, requested_item)
local S, url, doc, item_url, str, items, item

url="https://archive.org/metadata/" .. requested_item.id .. "/files"
if settings.debug == true then io.stderr:write("URL:" .. url.."\n") end
S=stream.STREAM(url)
if S ~= nil
then
  doc=S:readdoc()
  S:close()
  
  if settings.debug == true then io.stderr:write(doc.."\n") end
  
  JSON=dataparser.PARSER("json", doc)
  items=JSON:open("result")
  if items ~= nil
  then
    item=items:next()
    while item ~= nil
    do
	selected=self:consider_download(selected, item)
        item=items:next()
    end
  end

  if selected ~= nil then item_url="https://archive.org/download/" .. strutil.httpQuote(requested_item.id) .. "/" .. strutil.httpQuote(selected.name) end
end

return item_url
end,


query=function(self, query)
local JSON, items, item, str

JSON=self:send_query(query)

if JSON ~= nil
then
  response={}
  response.query=query.question
  response.source=self.name
  response.search_results={}
  
  items=JSON:open("/response/docs")
  item=items:next()
  while item ~= nil
  do
    self:parse_item(response.search_results, item)
    item=items:next()
  end
end

return response
end
}

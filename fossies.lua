

fossies={

name="fossies",
short_name="fo",
type="search",
has_top=true,
has_new=true,
needs_api_key=false,
url="https://fossies.org",


tag_contents=function(self, XML, end_tag)
local tag
local text=""

tag=XML:next()
while tag ~= nil
do
  if tag.type == end_tag then break end
  if strutil.strlen(tag.type) == 0 then text=text .. tag.data.. " " end
tag=XML:next()
end


return string.gsub(text, "\n", " ")
end,

parse_search=function(self, XML)
local tag, str
local result={}

result.content_is_html=true
result.content=""

tag=XML:next()
while tag ~= nil
do
  if tag.type=="/article" then break
  elseif tag.type == "h3"  then result.title=self:tag_contents(XML, "/h3")
  elseif tag.type == "small" and tag.data == "class=description style=\"border:0\"" then result.content=self:tag_contents(XML, "/small")
  elseif tag.type == "span" and tag.data == "class=published_date itemprop=datePublished"
  then
  str=XML:next().data .. ":00 2025"
  result.date=time.format("%Y-%m-%d %H:%M:%S", time.tosecs("%d %b %H:%M:%S %Y", str) )
  elseif tag.type == "a"
  then
        str=ExtractNameValue(tag.data, "href")
  if string.sub(str, 1, 6) == "https:" then result.url=str end
  end

tag=XML:next()
end


return result
end,


parse_article=function(self, XML)
local tag, str
local result={}

result.content_is_html=true
result.content=""

tag=XML:next()
while tag ~= nil
do
  if tag.type=="/article" then break
  elseif tag.type == "span" and tag.data == "itemprop=name" then result.title=XML:next().data
  elseif tag.type == "span" and tag.data == "class=published_date itemprop=datePublished"
  then
  str=XML:next().data .. ":00 2025"
  result.date=time.format("%Y-%m-%d %H:%M:%S", time.tosecs("%d %b %H:%M:%S %Y", str) )
  elseif tag.type == "a"
  then
        str=ExtractNameValue(tag.data, "href")
  if string.sub(str, 1, 6) == "https:" then result.url=str end
  if string.sub(str, 1, 5) == "http:" then result.url=str end
  elseif tag.type == "p" and tag.data == "class=\"description trimmed e-description\" itemprop=featureList" then result.content=XML:next().data
  elseif tag.type == "em" and tag.data == "class=version itemprop=softwareVersion" then result.title=result.title .. " - " .. XML:next().data
  end

tag=XML:next()
end


return result
end,


parse_description=function(self, description)
local XML, tag, url, str
local text=""

str=strutil.htmlUnQuote(description)
XML=xml.XML(str)
tag=XML:next()
if tag.type=="a"
then
  url=ExtractNameValue(tag.data, "href")
  tag=XML:next()
  text="~e"
  while tag ~= nil and tag.type ~= "/a"
  do
   if strutil.strlen(tag.type) == 0 then text=text .. tag.data end
   tag=XML:next()
  end
  text=text.."~0 "


  while tag ~= nil 
  do
   if strutil.strlen(tag.type) == 0 then text=text .. tag.data end
   tag=XML:next()
  end

else
text=description
end

return url, text
end,


rss_feed=function(self, response, query)
local S, str, doc, RSS

str="https://fossies.org/fresh.rss"
S=stream.STREAM(str, "r Accept=*/*")
if S ~= nil
then
doc=S:readdoc()
S:close()

if settings.debug == true then io.stderr:write(doc.."\n") end

RSS=dataparser.PARSER("rss", doc)
item=RSS:next()
while item ~= nil
do

--[[

<item>
<title>jest-30.0.3.tar.gz - 2025-06-25 03:21 (22.7 MB)</title>
<link>https://fossies.org/linux/www/jest-30.0.3.tar.gz/</link>
<description>
&lt;a href=&quot;https://jestjs.io/&quot;&gt;Jest&lt;/a&gt; is a JavaScript testing framework with a focus on simplicity.
</description>
<pubDate>Wed, 25 Jun 2025 09:45:05 +0200</pubDate>
<guid>https://fossies.org/linux/www/jest-30.0.3.tar.gz/</guid>
</item>

]]--

  if string.sub(item:name(), 1, 5) == "item:"
  then
  result={}
  result.source=self.name
  result.url=item:value("link")
  result.title=item:value("title")
  result.url, result.content = self:parse_description(item:value("description"))

  result.date=time.tosecs("%a, %d %b %Y %H:%M:%M", item:value("pubDate"))
  table.insert(response.search_results, result)
  end

  item=RSS:next()
end
end
end,


query=function(self, query)
local S, str, doc, XML, item
local response={}

response.source=self.name
response.query=query.question
response.search_results={}

if strutil.strlen(query.question) == 0 or query.question == "!top" or query.question == "!new" then self:rss_feed(response, query) end


return(response)
end,
}



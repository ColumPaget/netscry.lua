require("stream")
require("strutil")
require("process")
require("dataparser")
require("terminal")
require("xml")
require("net")
require("time")
require("filesys")
settings={
debug=false,
nerdfonts=false,
long_results=false,
result_text_len=80 * 4,
browser="",

load_boolean=function(self, input)
local str

if input == nil then return(false) end

str=string.lower(input)

if str == "y" then return(true)
elseif str == "yes" then return(true)
elseif str == "true" then return(true)
elseif str == "1" then return(true)
end

return(false)
end,


addkey=function(self, key, mod)
if strutil.strlen(key) > 0
then
  mod.api_key=key
end

end,


load_api_key=function(self, input)
local pos, name, value, source

pos=string.find(input, '=')
if pos ~= nil
then
  name=string.sub(input, 1, pos -1)
  value=string.sub(input, pos+1)
  value=strutil.stripQuotes(value)
  
  source=sources:get(name)
  if source ~= nil then source.api_key=value end
end

end,


load_config_file=function(self, dir)
local str, S

str=dir .. "netscry.conf"
S=stream.STREAM(str, "r")
if S ~= nil
then
  str=S:readln()
  while str ~= nil
  do
    str=strutil.trim(str)

    if string.sub(str, 1, 4) == "key:" then self:load_api_key(string.sub(str, 5)) 
    elseif string.sub(str, 1, 10) == "nerdfonts=" then self.nerdfonts=self:load_boolean(string.sub(str, 11))
    elseif string.sub(str, 1, 8) == "browser=" then self.browser=string.sub(str, 9)
    end
    str=S:readln()
  end
S:close()
end

end,



init=function(self)
local str

self:addkey(process.getenv("NETSCRY_ASKAI_APIKEY"), ask_ai)
self:addkey(process.getenv("NETSCRY_TAVILY_APIKEY"), tavily_ai)
self:addkey(process.getenv("NETSCRY_GEMINI_APIKEY"), google_ai)
self:addkey(process.getenv("NETSCRY_LANGSEARCH_APIKEY"), langsearch)

self:load_config_file("/etc/")
self:load_config_file(process.getenv("HOME") .. "/.config/netscry/")

end,


}


function ExtractNameValue(data, name)
local toks, item, len


name=name.."="
len=strutil.strlen(name)

toks=strutil.TOKENIZER(data, "\\S", "Q")
item=toks:next()
while item ~= nil
do
if string.sub(item, 1, len) == name then return strutil.stripQuotes(string.sub(item, len+1)) end
item=toks:next()
end

return ""
end



function JSONStringifyArray(JSON)
local item, str
local output=""

if JSON ~= nil
then
item=JSON:next()
while item ~= nil
  do
  str=item:value()
  if strutil.strlen(str) > 0
  then
    if strutil.strlen(output) > 0 then output=output .. "," .. str
    else output=str
    end
  end
  item=JSON:next()
end
end

return output
end


function ArrayFind(items, match)
local i, item

for i,item in ipairs(items)
do
if item == match then return i end
end

return 0
end

function Download(url, fname)
local S, toks, tok, str

S=stream.STREAM(url)
if S ~= nil
then
  str=S:getvalue("HTTP:Content-Disposition")
  if strutil.strlen(str) > 0
  then
  toks=strutil.TOKENIZER(str, ";")
  if toks ~= nil
  then
    tok=toks:next()
    while tok ~= nil
    do
    tok=strutil.trim(tok)
          if string.sub(tok, 1, 9) == "filename=" 
    then 
       fname=string.sub(tok, 10)
       fname=strutil.stripQuotes(fname)
    end
    tok=toks:next()
    end
  end
  end

  Out:puts("\rDownloading: ~e~b"..url.."~0 to "..fname.."\n")
  S:copy(fname)
  S:close()
else
  Out:puts("\r~rERROR~0: Download failed. Can't connect to: ~e~b"..url.."~0".."\n")
end

end

function HtmlConsumeToTag(XML, end_tag)
local item
local output=""

item=XML:next()
while item ~= nil
do
  if item.type == nil then output=output..item.data 
  elseif item.type == end_tag then break
  else output=output.."<"..item.type..">"
  end
  item=XML:next()
end

return output
end



function HtmlFormatForTerminal(input)
local item, XML
local output=""

XML=xml.XML(input)

item=XML:next()
while item ~= nil
do
  if item.type == nil then output=output.. string.gsub(item.data, "\n", " ")
  elseif item.type == end_tag then break
  elseif item.type=="head" then HtmlConsumeToTag(XML, "/head")
  elseif item.type=="script" then HtmlConsumeToTag(XML, "/script")
  elseif item.type=="style" then HtmlConsumeToTag(XML, "/style")
  elseif item.type == "h1" then output=output.."\n~e~y"
  elseif item.type == "h2" then output=output.."\n~y~b"
  elseif item.type == "h3" then output=output.."\n~m"
  elseif item.type == "b" then output=output.."~e"
  elseif item.type == "/b" then output=output.."~0"
  elseif item.type == "i" then output=output.."~c"
  elseif item.type == "/i" then output=output.."~0"
  elseif item.type == "strong" then output=output.."~e"
  elseif item.type == "/strong" then output=output.."~0"
  elseif item.type == "em" then output=output.."~c"
  elseif item.type == "/em" then output=output.."~0"
  elseif item.type == "/p" then output=output.."\n\n"
  elseif item.type == "/div" then output=output.." "
  elseif item.type == "/h1" then output=output.."~0\n\n"
  elseif item.type == "/h2" then output=output.."~0\n\n"
  elseif item.type == "/h3" then output=output.."~0\n\n"
  end
  item=XML:next()
end


return strutil.httpUnQuote(output)
end


markdown={

process_line=function(self, line)
local output=""

output=line
output=string.gsub(output, "`(.-)`", function(match) return("~c`"..match.."`~0") end)
output=string.gsub(output, "%*%*(.-)%*%*", function(match) return("~e**"..match.."**~0") end)

return(output)
end,


process_codeblock=function(self, output, lines)
local line, noindent

output=output.."~+N"
line=lines:next()
while line ~= nil
do
noindent=strutil.trim(line)
if string.sub(noindent, 1, 3) ==  '```'
then
  output=output.."~0"..line.."~>\n"
  break
else 
  output=output.. line .. "~>\n"
end

line=lines:next()
end

return output
end,


convert=function(self, dest_fmt, input)
local lines, line, noindent
local output=""
local state={}

state.bold=false
state.code=false

lines=strutil.TOKENIZER(input, "\n")
line=lines:next()
while line ~= nil
do
noindent=strutil.trim(line)
if string.sub(noindent, 1,1)== '#' then output=output.."~e~y" .. line .. "~0\n"
elseif string.sub(noindent, 1, 3) ==  '```'
then 
  output=output..line.."\n"
  output=self:process_codeblock(output, lines)
else 
  output=output .. self:process_line(line) .. "\n"
end

line=lines:next()
end

return strutil.trim(output)
end,


}


duckduckgo={

name="duckduckgo",
short_name="ddg",
type="search",
needs_api_key=false,
url="https://duckduckgo.com",



parse_result=function(self, XML)
local tag
local result={}

result.source=self.name
result.content_is_html=true
result.content=""

tag=XML:next()
while tag ~= nil
do
if tag.type=="/h2" then break
elseif tag.type=="a" then result.url="https:"..ExtractNameValue(tag.data, "href")
elseif tag.type==nil then result.title=tag.data
end

tag=XML:next()
end

return result
end,


query=function(self, query)
local S, str, doc, XML, item
local response={}

response.source=self.name
response.query=query.question
response.search_results={}

str="https://html.duckduckgo.com/html?q=" .. strutil.httpQuote(query.question) .."&t=h_&ia=web"
S=stream.STREAM(str, "r Accept=*/*")
if S ~= nil
then
doc=S:readdoc()
S:close()

if settings.debug == true then io.stderr:write(doc.."\n") end

XML=xml.XML(doc)
item=XML:next()
while item ~= nil
do
  
  if item.type == "h2" and item.data == "class=\"result__title\""
  then
  result=self:parse_result(XML)
  table.insert(response.search_results, result)
  elseif item.type == "a" 
  then
    str=ExtractNameValue(item.data, "class")
    if str == "result__snippet" then result.content=HtmlConsumeToTag(XML, "/a") end
  end

item=XML:next()
end
end

return(response)
end,
}


langsearch={

name="langsearch",
type="search",
short_name="ls",
needs_api_key=true,
url="https://langsearch.com/",

parse_item=function(self, results, item)
local result={}

result.source=self.name
result.url=item:value("url")
result.title=item:value("name") 
-- .. ":" ..  strutil.unQuote(item:value("snippet"))
result.content=strutil.unQuote(item:value("summary"))

table.insert(results, result)
end,


query=function(self, query)
local str, S, doc, JSON, items, item, qcount
local response

response={}
response.source=self.name
response.answer=""
response.query=query.question
response.search_results={}

if query.max_results == nil then qcount=10
else qcount=query.max_results
end

str="{\"query\": \""..query.question.."\", \"freshness\": \"noLimit\", \"summary\": true,\"count\": "..qcount.."}"
len=strutil.strlen(str)
S=stream.STREAM("https://api.langsearch.com/v1/web-search", "w Authorization='Bearer "..self.api_key.."' Content-Type=application/json Content-Length=" .. tostring(len))
if S ~= nil
then
S:writeln(str)
S:commit()
doc=S:readdoc()
S:close()
end

if settings.debug == true then io.stderr:write(doc.."\n") end

JSON=dataparser.PARSER("json", doc)
if JSON ~= nil
then
  items=JSON:open("data/webPages/value")
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


-- https://en.wikipedia.org/w/api.php?action=help&modules=query


wikipedia={

name="wikipedia",
short_name="wp",
type="search",
needs_api_key=false,
url="https://wikipedia.org/",


add_result=function(self, search_results, title, id, content)
local result={}

result.source=self.name
result.title=title
result.id=id
result.content=content

-- if #search_results == 0 then result.answer=strutil.htmlUnQuote(item:value("export/*")) end

table.insert(search_results, result)
end,

parse_result=function(self, search_results, item)
local extract

extract=item:value("extract")
self:add_result(search_results, item:value("title"), item:value("pageid"), extract)

end,



find_disambiguation_prop=function(self, P)
local props, item

props=P:open("pageprops")
if props ~= nil
then
  item=props:next()
  while item ~= nil
  do
    if item:name() == "disambiguation" then return true end
    item=props:next()
  end
end

return false
end,


is_disambiguation=function(self, P)
local pages, props, item

pages=P:open("query/pages")
if pages ~= nil
then
item=pages:next()
while item ~= nil
do
if self:find_disambiguation_prop(item) == true then return true end
item=pages:next()
end
end

return false
end,


parse_disambiguation=function(self, P, response)
local XML, item

XML=xml.XML(P:value("query/export/*"))
if XML ~= nil
then
  item=XML:next()
  while item ~= nil
  do
    if item.type == "text"
    then
    item=XML:next()
    self:add_result(response.search_results, "~rDisambiguation Page~0", "", strutil.htmlUnQuote(item.data))
    end
    item=XML:next()
  end
end

end,


parse_page=function(self, P, response)
local pages, item

--response.answer=strutil.htmlUnQuote(P:value("query/export/*"))
pages=P:open("query/pages")

item=pages:next()
while item ~= nil
do
self:parse_result(response.search_results, item, answer)
item=pages:next()
end

return(response)
end,


send_query=function(self, props, question)
local str, doc, S, P

str="https://en.wikipedia.org/w/api.php?format=json&action=query&prop="..props.."&exintro=true&explaintext=true&export=false&redirects=1&titles=" .. strutil.httpQuote(question) 
if settings.debug == true then io.stderr:write("SEND: " .. str .."\n") end


S=stream.STREAM(str, "r Accept=*/*")
if S==nil
then
print("ERROR: Query failed to en.wikipedia.org")
else
doc=S:readdoc()
if settings.debug == true then io.stderr:write(doc.."\n") end
P=dataparser.PARSER("json", doc)
S:close()
end

return P
end,


query=function(self, query)
local S, str, doc, P, pages
local response={}

response.source=self.name
response.query=query.question
response.search_results={}


P=self:send_query("pageprops", query.question)
if self:is_disambiguation(P) == true
then
self:parse_disambiguation(P, response)
else
P=self:send_query("extracts", query.question)
self:parse_page(P, response)
end

return response
end,
}






stackexchange={

sites={"Stack Overflow", "Server Fault", "Super User", "Meta Stack Exchange", "Web Applications", "Arqade", "Webmasters", "Seasoned Advice", "Game Development", "Photography", "Cross Validated", "Mathematics", "Home Improvement", "Geographic Information Systems", "TeX - LaTeX", "Ask Ubuntu", "Personal Finance & Money", "English Language & Usage", "Stack Apps", "User Experience", "Unix & Linux", "WordPress Development", "Theoretical Computer Science", "Ask Different", "Role-playing Games", "Bicycles", "Software Engineering", "Electrical Engineering", "Android Enthusiasts", "Board & Card Games", "Physics", "Homebrewing", "Information Security", "Writing", "Video Production", "Graphic Design", "Database Administrators", "Science Fiction & Fantasy", "Code Review", "Code Golf", "Quantitative Finance", "Project Management", "Skeptics", "Physical Fitness", "Drupal Answers", "Motor Vehicle Maintenance & Repair", "Parenting", "SharePoint", "Music: Practice & Theory", "Software Quality Assurance & Testing", "Mi Yodeya", "German Language", "Japanese Language", "Philosophy", "Gardening & Landscaping", "Travel", "Cryptography", "Signal Processing", "French Language", "Christianity", "Bitcoin", "Linguistics", "Biblical Hermeneutics", "History", "Bricks", "Spanish Language", "Computational Science", "Movies & TV", "Chinese Language", "Biology", "Poker", "Mathematica", "Psychology & Neuroscience", "The Great Outdoors", "Martial Arts", "Sports", "Academia", "Computer Science", "The Workplace", "Chemistry", "Chess", "Raspberry Pi", "Russian Language", "Islam", "Salesforce", "Ask Patents", "Genealogy & Family History", "Robotics", "ExpressionEngine® Answers", "Politics", "Anime & Manga", "Magento", "English Language Learners", "Sustainable Living", "Tridion", "Reverse Engineering", "Network Engineering", "Open Data", "Freelancing", "Blender", "MathOverflow", "Space Exploration", "Sound Design", "Astronomy", "Tor", "Pets", "Amateur Radio", "Italian Language", "Stack Overflow em Português", "Aviation", "Ebooks", "Beer, Wine & Spirits", "Software Recommendations", "Arduino", "Expatriates", "Mathematics Educators", "Earth Science", "Joomla", "Data Science", "Puzzling", "Craft CMS", "Buddhism", "Hinduism", "Community Building", "Worldbuilding", "Emacs", "History of Science and Mathematics", "Economics", "Lifehacks", "Engineering", "Coffee", "Vi and Vim", "Music Fans", "Woodworking", "CiviCRM", "Medical Sciences", "Stack Overflow на русском", "Русский язык", "Mythology & Folklore", "Law", "Open Source", "elementary OS", "Portuguese Language", "Computer Graphics", "Hardware Recommendations", "3D Printing", "Ethereum", "Latin Language", "Language Learning", "Retrocomputing", "Arts & Crafts", "Korean Language", "Monero", "Artificial Intelligence", "Esperanto Language", "Sitecore", "Internet of Things", "Literature", "Veganism & Vegetarianism", "Ukrainian Language", "DevOps", "Bioinformatics", "Computer Science Educators", "Interpersonal Skills", "Iota", "Stellar", "Constructed Languages", "Quantum Computing", "EOS.IO", "Tezos", "Operations Research", "Drones and Model Aircraft", "Matter Modeling", "Cardano", "Proof Assistants", "Substrate and Polkadot", "Bioacoustics", "Solana", "Programming Language Design and Implementation", "GenAI"},

name="stackexchange",
short_name="sx",
type="search",
needs_api_key=true,
api_key="",
url="https://stackoverflow.com/",

parse_item=function(self, response, item)
local answer={}
local tags, tag

--{"items":[{"tags":["html","web-scraping","architecture","piracy-prevention"],"question_score":350,"is_accepted":false,"answer_id":34828465,"is_answered":false,"question_id":3161548,"item_type":"answer","score":441,"last_activity_date":1542725271,"creation_date":1452956766,"body":"

answer.source=self.name
answer.id=item:value("question_id")
answer.title=item:value("title")
answer.url="https://stackoverflow.com/questions/" .. answer.id
answer.title=""
answer.score=item:value("score")
answer.content=strutil.unQuote(item:value("body"))

tags=item:open("tags")
tag=tags:next()
while tag ~= nil
do
answer.tags=answer.tags .. tag:value() .. ","
tag=tags:next()
end

table.insert(response.search_results, answer)

end,

query=function(self, query)
local S, doc, JSON, items, item
local response={}

response.query=query.question
response.source=self.name
response.search_results={}


S=stream.STREAM("https://api.stackexchange.com/search/excerpts?site=stackoverflow.com&key="..self.api_key.."&q=" .. strutil.httpQuote(query.question))
if S ~= nil
then
doc=S:readdoc()
S:close()
end

if settings.debug == true then io.stderr:write(doc.."\n") end

JSON=dataparser.PARSER("json", doc)
items=JSON:open("items")

item=items:next()
while item ~= nil
do
self:parse_item(response, item)
item=items:next()
end



return response
end,

}

google_ai={
name="gemini",
short_name="gem",
type="ai",
needs_api_key=true,
url="https://gemini.google.com/",

parse_content=function(self, item)
local content
local output=""

content=item:open("content/parts")
item=content:next()
while item ~= nil
do
output=output .. item:value("text")
item=content:next()
end

return output
end,




parse_response=function(self, json, query)
local P, item, str
local response={}

response.source=self.name
response.query=query.question

P=dataparser.PARSER("json", json)
item=P:open("candidates")
if item ~= nil
then
item=item:next()

str=self:parse_content(item)
response.answer=markdown:convert("ansi", strutil.unQuote(str))
end

return response
end,



query=function(self, query)
local S, query_json, len, responsecode, doc

query_json="{\"contents\": [{\"parts\": [{\"text\": \""..query.question.."\"}]}]}"
len=strutil.strlen(query_json)

S=stream.STREAM("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key="..self.api_key, "w Content-Type=application/json Content-Length="..tostring(len))
if S ~= nil
then
  S:writeln(query_json)
  S:commit()
  responsecode=S:getvalue("HTTP:ResponseCode")
  doc=S:readdoc()
  S:close()

--[[
{
  "error": {
    "code": 503,
    "message": "The model is overloaded. Please try again later.",
    "status": "UNAVAILABLE"
  }
}
]]--

  if responsecode ~= "200"
  then
    Out:puts("~rERROR:~0 Server Responds: "..S:getvalue("HTTP:ResponseReason"))
    Out:puts(doc)
  else
    if settings.debug == true then io.stderr:write(doc.."\n") end
    return self:parse_response(doc, query)
  end
end

return nil
end,

}
--[[ Tavily Example Response
{"query":"how is unison and chorus implmented in sythesizers","follow_up_questions":null,"answer":"Unison in synthesizers duplicates voices at the same pitch. Chorus adds a modulated, slightly detuned copy of the signal for a thicker, shimmering effect. Both can enhance sound thickness.","images":[],"results":[{"title":"What's the difference between chorus and unison, and when ... - Reddit","url":"https://www.reddit.com/r/edmproduction/comments/65lxlm/whats_the_difference_between_chorus_and_unison/","content":"Chorus is a modulated effect. Like unison, there is at least another copy of the original signal, set to a different pitch. This pitch, however, is modulated up and down, usually to an LFO. Most chorus modules also usually delay the signal copy. Some older synths have a chorus module because it was easier and cheaper to implement than another","score":0.76279575,"raw_content":null},{"title":"Syntorial and Unison vs. Chorus : r/synthesizers - Reddit","url":"https://www.reddit.com/r/synthesizers/comments/4vw1il/syntorial_and_unison_vs_chorus/","content":"well chorus is a tiny delay whereas unison is more or less \"in sync\" just naturally imperfect unison is a bit more of \"one sound\" -- maybe the easiest thing to identify is the effect the envelope has, since a chorus generally relies on some kind of feedback, so there is generally more of a fade down, even after the \"note\" has pretty much muted","score":0.73642004,"raw_content":null},{"title":"What is the difference between Chorus and Unison?","url":"https://www.reddit.com/r/edmproduction/comments/1o6jpr/what_is_the_difference_between_chorus_and_unison/","content":"Unison voices are usually panned. (Digital) Chorus works by taking an audio signal, shifting its pitch and panning it, then mixing it with the dry signal. The LFO controls the pitch shift. Analog chorus works a bit differently but unless you're using an analog chorus pedal or rack unit it's not that important. Those are more similar to analog","score":0.58465123,"raw_content":null},{"title":"The Chorus Effect: Everything You Need To Know | Planet Botch - Blogger","url":"https://planetbotch.blogspot.com/2015/11/the-chorus-effect-everything-you-need.html","content":"The effect was meant to simulate the sound of actual double-tracking - i.e. overdubbed unison singing or playing, which would be thickened by small pitch discrepancies between the two unison parts. Meanwhile, a multi-oscillator analogue synth was able to produce similar thickening by detuning one oscillator against another.","score":0.572078,"raw_content":null},{"title":"Chorus Effect 101: Key Uses, Creative Tips & Expert Techniques - Unison","url":"https://unison.audio/chorus-effect/","content":"The depth parameter determines just how far the pitch modulation moves, controlling the intensity of your chorus effect. For example, setting the depth controls to around 30-40% adds a subtle shimmer that's perfect for layering vocals in a pop or EDM track.. If you want a more dramatic, wavy effect (like something you'd hear in 80s synthwave music), simply push the depth to 60-70%.","score":0.466433,"raw_content":null}],"response_time":2.22}
]]--


tavily={

name="tavily",
short_name="tav",
type="ai",
needs_api_key=true,
url="https://www.tavily.com/",

parse_results=function(self, JSON)
local results={}
local item, result

item=JSON:next()
while item ~= nil
do
result={}
result.source=self.name
result.title=item:value("title")
result.url=item:value("url")
result.content=item:value("content")
result.score=tonumber(item:value("score"))
table.insert(results, result)
item=JSON:next()
end

return results
end,


parse=function(self, doc)
local JSON, results, item
local response={}

response.source=self.name

JSON=dataparser.PARSER("json", doc)
if JSON ~= nil
then
response.query=JSON:value("query")
response.answer=JSON:value("answer")

results=JSON:open("results")
response.search_results=self:parse_results(results)
end

return(response)
end,


query=function(self, query_details)
local S, query_json, len, doc

--[[
  extra args are: 
     "topic": "general" or "topic": "news"
     "days": <number>  -- if 'topic' is 'news' then number of days back from today to search
     include_images boolean default:false  Also perform an image search and include the results in the response.
     include_image_descriptions boolean default:false When include_images is true, also add a descriptive text for each image.
     include_domains string[] A list of domains to specifically include in the search results. 
     exclude_domains string[] A list of domains to specifically exclude from the search results.
     search_depth "basic" or "advanced" default:basic The depth of the search. advanced search is tailored to retrieve the most relevant sources and content snippets for your query, while basic search provides generic content snippets from each source. A basic search costs 1 API Credit, while an advanced search costs 2 API Credits.

]]--

query_json="{\"query\": \"" .. query_details.question .. "\","
if query_details.search_level == "deep" then query_json=query_json .. "\"search_depth\": \"advanced\"," end
if query_details.max_results ~= nil then query_json=query_json .. "\"max_results\": " .. string.format("%d", math.floor(query_details.max_results)) .. "," end
query_json=query_json .."\"include_answer\": \"advanced\"}"


len=strutil.strlen(query_json)
S=stream.STREAM("https://api.tavily.com/search", "w Content-Type=application/json Content-Length="..tostring(len).." Authorization=\"Bearer ".. self.api_key .."\"")
if S ~= nil
then
S:writeln(query_json)
S:commit()
doc=S:readdoc()
S:close()

if settings.debug == true then io.stderr:write(doc.."\n") end


return self:parse(doc)
end

return nil
end

}

ask_ai={

name="ask_ai",
short_name="ask",
url="https://iask.ai/",
type="ai",
needs_api_key=true,

mkstate=function(self)
local state={}

state.bold=false
state.inline_code=false

return state
end,


attrib=function(self, output, state, startstr, endstr)

  if state ~= true 
  then 
    output=output..startstr
    return output, true
  end

output=output..endstr
return output,false
end,


build_output=function(self, output, char, next, state, str)

if char == "\"" then char=""
elseif char == "*" and next == "*"
then
  output, state.bold = self:attrib(output, state.bold, "~e", "~0")
elseif char == "`" and next ~= "`" 
then
  output, state.inline_code = self:attrib(output, state.inline_code, "~m", "~0")
else output = output .. char
end

return output
end,


parse_response=function(self, json, query)
local P, item, i, char, next, output
local response={}


response.source=self.name
response.query=query.question

P=dataparser.PARSER("json", json)
item=P:open("response")
if item ~= nil
then
item=item:next()
if item ~= nil
then
str=item:value()

output=markdown:convert("ansi", str)
response.answer=strutil.trim(terminal.format(output))
end
end

return response
end,


query=function(self, query)
local S, query_json, len, doc

query_json="{\"stream\": false, \"prompt\": \""..query.question.."\"}"
len=strutil.strlen(query_json)

S=stream.STREAM("https://api.iask.ai/v1/query", "w Content-Type=application/json Content-Length="..tostring(len).." Authorization=\"Bearer "..self.api_key.."\"")
if S ~= nil
then
S:writeln(query_json)
S:commit()
doc=S:readdoc()
S:close()

if settings.debug == true then io.stderr:write(json.."\n") end

return self:parse_response(doc, query)
end

return nil
end,

}

dictionary_dev={

name="dictionary_dev",
short_name="dict",
type="book",
needs_api_key=false,
donate="https://www.paypal.me/paytosuraj",
url="https://dictionaryapi.dev/",

parse_definitions=function(self, results, word, word_type, defs)
local item

if defs ~= nil
then
  item=defs:next()
  while item ~= nil
  do
    result={}
    result.source=self.name
    result.title=word .. ": " .. word_type
    result.content=item:value("definition").."\n"
    result.content_is_preformatted=true

    str=item:value("example")
    if strutil.strlen(str) > 0 then result.content=result.content .. "~e~cexample~0: ".. str.."\n" end

    str=JSONStringifyArray(item:open("synonyms"))
    if strutil.strlen(str) > 0 then result.content = result.content .. "~e~csynonyms~0: "..str.."\n" end

    str=JSONStringifyArray(item:open("antonyms"))
    if strutil.strlen(str) > 0 then result.content = result.content .. "~e~cantonyms~0: "..str.."\n" end


    table.insert(results, result)
    item=defs:next()
    end
else
print("ERROR: defs==nil")
end

end,


parse_meanings=function(self, results, word, meanings)
local item

item=meanings:next()
while item ~= nil
do
self:parse_definitions(results, word, item:value("partOfSpeech"), item:open("definitions"))
item=meanings:next()
end

end,


parse=function(self, doc)
local JSON, results, item
local response={}

response.source=self.name

JSON=dataparser.PARSER("json", doc)
if JSON ~= nil
then
  response.query=JSON:value("word")
  response.search_results={}
  
item=JSON:next()
while item ~= nil
do
  self:parse_meanings(response.search_results, item:value("word"), item:open("meanings"))
  item=JSON:next()
end
  
end

return(response)
end,


query=function(self, query_details)
local S, query_json, len, doc


S=stream.STREAM("https://api.dictionaryapi.dev/api/v2/entries/en/"..query_details.question, "")
if S ~= nil
then
doc=S:readdoc()
S:close()

if settings.debug == true then io.stderr:write(doc.."\n") end

return self:parse(doc)
end

return nil
end

}

bighugethesaurus={

name="bighugethesaurus",
short_name="bht",
type="book",
needs_api_key=true,
url="https://words.bighugelabs.com/",


-- {"adjective":{"syn":["fatty","juicy","fertile","productive","rich","rounded"],"ant":["nonfat","thin"],"rel":["endomorphic","pyknic","rounded","thick"],"sim":["abdominous","adipose","blubbery","buttery","buxom","chubby","compact","corpulent","double-chinned","dumpy","embonpoint","endomorphic","fattish","fleshy","fruitful","greasy","gross","heavy","heavyset","jowly","loose-jowled","obese","oily","oleaginous","overweight","paunchy","plump","podgy","porcine","portly","potbellied","profitable","pudgy","pyknic","roly-poly","rotund","sebaceous","stocky","stout","suety","superfatted","thick","thickset","tubby","weighty","zaftig","zoftig"]},"noun":{"syn":["adipose tissue","fatty tissue","fatness","blubber","avoirdupois","animal tissue","bodily property","lipid","lipide","lipoid"],"ant":["leanness"]},"verb":{"syn":["fatten","flesh out","fill out","plump","plump out","fatten out","fatten up","alter","change","modify"]}}

parse_word=function(self, results, word, item)
local str, subitem
local result={}

    result.source=self.name
    result.title=word .. ": " .. item:name()
    result.content_is_preformatted=true
    result.content=""

    subitem=item:open("syn")
    if subitem == nil
    then
      --sometimes this api just returns and array of words that are synonyms, rather than the full json
      --object containing synonyms, antonyms etc
      str=JSONStringifyArray(item)
      if strutil.strlen(str) > 0 then result.content = result.content .. "~e~csynonyms~0: "..str.."\n" end
      table.insert(results, result)
      return false
    else
    str=JSONStringifyArray(item:open("syn"))
    if strutil.strlen(str) > 0 then result.content = result.content .. "~e~csynonyms~0: "..str.."\n" end

    str=JSONStringifyArray(item:open("ant"))
    if strutil.strlen(str) > 0 then result.content = result.content .. "~e~cantonyms~0: "..str.."\n" end

    str=JSONStringifyArray(item:open("sim"))
    if strutil.strlen(str) > 0 then result.content = result.content .. "~e~csimilar~0: "..str.."\n" end

    table.insert(results, result)
    return true
    end


end,


parse=function(self, query_word, doc)
local JSON, results, item
local response={}

response.source=self.name

JSON=dataparser.PARSER("json", doc)
if JSON ~= nil
then
  response.query=JSON:value("word")
  response.search_results={}
  
item=JSON:next()
while item ~= nil
do
  if self:parse_word(response.search_results, query_word, item) == false then break end
  item=JSON:next()
end
  
end

return(response)
end,


query=function(self, query_details)
local S, query_json, len, doc


S=stream.STREAM("https://words.bighugelabs.com/api/2/"..self.api_key.."/"..query_details.question.."/json", "")

if S ~= nil
then
doc=S:readdoc()
S:close()

if settings.debug == true then io.stderr:write(doc.."\n") end

return self:parse(query_details.question, doc)
end

return nil
end

}

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


 
function OutputFormatSearchResult(search_result)
local str, toks, item
local output=""

 if search_result.content_is_html == true then str=HtmlFormatForTerminal(search_result.content)
 else str=search_result.content
 end

 if search_result.content_is_preformatted == false then str=string.gsub(str, "\n", " ")  end

 toks=strutil.TOKENIZER(str, "\n")
 item=toks:next()
 while item ~= nil
 do
 output=output .. "  " .. item .. "\n"
 item=toks:next()
 end

  if settings.long_results == true then return output end

 if strutil.strlen(output) > settings.result_text_len then return string.sub(output, 1, settings.result_text_len) .. " ~0~b...~0" end
 return output
end


function OutputSearchResult(i, item)
local str

      if item == nil then return end

      str="~g" .. string.format("%3d", i).."~0  "
      if item.id ~= nil then str=str .. "id:~m"..item.id.."~0 " end
      if item.mediatype ~= nil then str=str .. "~y~e" ..item.mediatype .."~0 " end
      if strutil.strlen(item.codecs) > 0 then str=str .. "~y~e" ..item.codecs .."~0 " end
      if item.date ~= nil then str=str .. "~b~e" ..item.date .."~0 " end
      if item.score ~= nil then str=str .. string.format("%3.3f", item.score) .." " end
      if item.title ~= nil then str=str .. "  ~e".. item.title .."~0" end
      if strutil.strlen(item.author) > 0 then  str=str .. " author: ~e~c" .. item.author.."~0 " end
      str=str.."\n"

      if strutil.strlen(item.url) ~= 0 then str=str .. "  ~e~b" .. item.url.."~0\n" end
      Out:puts(str)

      str=OutputFormatSearchResult(item)
      Out:puts(str .. "\n\n")
end


function OutputQuota(response)
local output=""
local total

if response.quota_used ~= nil
then
if response.quota_remain ~= nil then total=response.quota_used + response.quota_remain 
else total=response.quota_total
end

output="quota: " .. response.quota_used .. "/" .. total

end

return output
end


function OutputResponse(response, source)
local i,item, str

if response ~= nil
then
  Out:puts("~y -------- " .. source.name .. " (~b" .. source.url .."~0)  " .. OutputQuota(response) .. " reply to '" .. response.query .. "' --------~0\n")
  if strutil.strlen(source.donate) > 0 then Out:puts("~yDONATE:~0 consider donating to support this service at ~b"..source.donate.."~0" .. "\n") end
  if strutil.strlen(response.answer) > 0 then Out:puts(strutil.quoteChars(response.answer, "\\") .. "\n") end

  if response.search_results ~= nil
  then
    for i,item in ipairs(response.search_results)
    do
  OutputSearchResult(i, item)
    end
  end
  Out:puts("\n")
end

end




function OutputError(source_name, msg)

Out:puts("~rERROR~0: '~e"..source_name.."~0' "..msg.."\n")

end

sources={
list={},
last_search_results={},

add=function(self, name, item)

if strutil.strlen(name) == 0 then OutputError("????", "attempt to add datasource with no name")
elseif item==nil then OutputError(name, "attempt to add datasource with no implementation object")
else self.list[name]=item
end

end,


get=function(self, name)
item=self.list[name]
if item== nil then item=self:get_short(name) end
return(item)
end,


get_short=function(self, name)
local key, item

for key,item in pairs(self.list)
do
  if item.short_name == name then return item end
end

return nil
end,


iterate=function(self, func)
local key, item

for key,item in pairs(self.list)
do
  func(item)
end

end,


source_check_category=function(self, source, query)

    if strutil.strlen(query.category) == 0 then return true end

    if source.categories == nil then return true end

    for i,item in ipairs(source.categories)
    do
      if item==query.category then return true end
    end

    return false
end,


query_source_api=function(self, source, query)
local response

if source ~= nil
then
  if source.needs_api_key == true and strutil.strlen(source.api_key) == 0
  then
  OutputError(source.name, "no API key")
  else
    if self:source_check_category(source, query) == false then Out:puts("\r~yWARNING~0: '" .. query.category .. "' is not a known category for source '" .. source.name .. "'.\n") end
    Out:puts("\r~gQUERY: " .. source.name .. "~0  '"..query.question.."'\n")
    response=source:query(query)
  end
 else OutputError(source.name, "Unknown source")
end


return response, source
end,


query_source=function(self, source, query)
local response, i, answer

  response=self:query_source_api(source, query)
  if response ~= nil
  then 
      OutputResponse(response, source) 
      if response.search_results ~= nil 
      then
      for i,answer in ipairs(response.search_results) do table.insert(self.last_search_results, answer) end
      end
  else OutputError(source.name, "No response to query")
  end

end,

output_source_topics=function(self, source)
local str, i, item

if source.categories ~= nil
then 
  str="~eknown topics~0: "
  for i,item in ipairs(source.categories) do str=str..item..", " end
  Out:puts(str .. "\n")
else Out:puts("source has no topics\n")
end

end,



output_source_info=function(self, source)
local str

Out:puts("~ename~0: ~e~c"..source.name.."~0  ~eshort name~0: "..source.short_name .. " ~etype~0: " .. source.type .."\n")
if strutil.strlen(source.url) > 0 then Out:puts("~ehome url~0: ~e~b" .. source.url.."~0\n") end

str="~e" .. "api-key needed" .. "~0: "
if source.needs_api_key ==true 
then 
   if strutil.strlen(source.api_key) > 0 then str=str.. "~g yes - present ~0 ".. source.api_key
   else str=str .. "~r yes - missing ~0"
   end
else str=str .. "~g no ~0"
end
Out:puts(str.."\n")

if source.has_top == true then Out:puts("~ehas 'top' items listing~0: ~gyes~0\n")
else Out:puts("~ehas 'top' items listing~0: no\n")
end

if source.has_new == true then Out:puts("~ehas 'new' items listing~0: ~gyes~0\n")
else Out:puts("~ehas 'new' items listing~0: no\n")
end

if source.has_details == true then Out:puts("~ehas item detail view~0: ~gyes~0\n")
else Out:puts("~ehas item detail views~0: no\n")
end

if source.has_downloads == true then Out:puts("~ehas downloads~0: ~gyes~0\n")
else Out:puts("~ehas downloads~0: no\n")
end

self:output_source_topics(source)
end,


query=function(self, query)
local toks, tok, source

toks=strutil.TOKENIZER(query.sources, "\\S")
tok=toks:next()
while tok ~= nil
do
  source=self:get(tok)
  if source ~= nil
  then
    if query.question == "!info" then self:output_source_info(source) 
    elseif query.question == "!topics" then self:output_source_topics(source) 
    else self:query_source(source, query)
    end
  end

  tok=toks:next()
end

return self.last_search_results
end,





init=function(self)
self:add("duckduckgo", duckduckgo)
self:add("wikipedia", wikipedia)
self:add("langsearch", langsearch)
self:add("stackexchange", stackexchange)
self:add("ask_ai", ask_ai)
self:add("gemini", google_ai)
self:add("tavily", tavily)
self:add("dictionary_dev", dictionary_dev)
self:add("bighugethesaurus", bighugethesaurus)
self:add("worldnewsapi", worldnewsapi)
self:add("bigbookapi", bigbookapi)
self:add("gnews", gnews)
self:add("hackernews", hackernews)
self:add("fossies", fossies)
self:add("dbooks", dbooks)
self:add("openlibrary", openlibrary)
self:add("gutenberg", gutenberg)
self:add("spaceflightnewsapi",  spaceflightnewsapi)
self:add("archive.org",  archive_org)
end,

}

icons={

find=function(self, name)

if name == "search" then return "~Ue68f"
elseif name == "book" then return "~Ueaa4"
elseif name == "news" then return "~Ueb34"
elseif name == "ai" then return "~Uee0d"
end

return ""
end,

}


--this function generates a query object and initializes some values in it,
--like 'country' and 'language' from the user's local settings


function new_query()
local query={}
local toks, str

query.sources=""
query.question=""
query.country="us"
query.language="en"

str=process.getenv("LANG")
if str ~= nil
then
toks=strutil.TOKENIZER(str, "_|.", "m")
query.language=toks:next()
query.country=string.lower(toks:next())
end

return(query)
end

function ViewWebpage(url)
local S, html, output

if strutil.strlen(url) > 0
then
S=stream.STREAM(url, "")
if S ~= nil
then
html=S:readdoc()
S:close()

output=HtmlFormatForTerminal(html)
Out:puts(output)
end
end

end


function ViewInBrowser(url, browser)

if strutil.strlen(browser) == 0
then 
  browser=settings.browser
  if strutil.strlen(browser) == 0 then browser="xdg-open" end
end

os.execute(browser.. " "..url)

end

interactive={

results_list=nil,


--name can be either the short or long name of the source
change_source=function(self, name)
if strutil.strlen(name) == 0 then return end

    self.source=sources:get_short(name)
    if self.source == nil then self.source=sources:get(name) end
    if self.source ~= nil then query.sources=self.source.name
    else Out:puts("~runknown source~0: '"..name.."'. Type  '/sources' to see list.\n")
    end

  if self.source ~= nil 
  then 
  Out:puts("Switching to: ~ename~0: ~e~c".. self.source.name .. "~0  type: ~e" .. tostring(self.source.type) .. "~0  ")
  if strutil.strlen(self.source.url) > 0 then Out:puts("~e~b" .. self.source.url.."~0  features: ") end
  if self.source.has_downloads==true then Out:puts("~edownloads~0,") end
  if self.source.has_top==true then Out:puts("~e'top' page~0,") end
  if self.source.has_top==true then Out:puts("~e'new' page~0,") end
  Out:puts("~0\n") 
  end


end,


build_prompt=function(self, active_sources)
local tok, toks
local prompt=""

toks=strutil.TOKENIZER(active_sources, "\\S")
tok=toks:next()
while tok
do
  source=sources:get(tok)
  if source ~= nil 
  then 
  if settings.nerdfonts == true then prompt=prompt .. " " .. icons:find(source.type) .. "  " .. source.short_name .. " " 
  else prompt=prompt .. " " .. source.short_name .. " "
  end
  end

  tok=toks:next()
end

--return "~Y~b" .. prompt.."~0~y~Ueb70~0 "

if settings.nerdfonts == true
then
return "~Y~b" .. prompt.."~0~y~Ue0b0~0 "
else
return prompt .. "> "
end

end,

--this function does not have 'self' object
--because it's used outside of this, or any
--object that could be 'self'
display_source_status=function(source)
local str

str=string.format("%5s %25s:", source.short_name, source.name)
if source.needs_api_key == true
then
  if strutil.strlen(source.api_key) > 0 then str=str.." ~gready~0"
  else str=str.." ~rno api key~0"
  end
else
  str=str.." ~gready~0"
end

Out:puts(str.."\n")
end,


download_item=function(self, item)
local url, parts, fname

      url=item.download

      if strutil.strlen(url) == 0
      then
      source=sources:get(item.source)
      if source ~= nil and source.get_download ~= nil then url=source:get_download(item)  end
      end


      if url ~= nil
      then
        parts=net.parseURL(url)
        fname=filesys.basename(parts.path)
        if strutil.strlen(fname) == 0 then fname=item.title end
        Download(url, fname)
      end

end,


download_items=function(self, toks)
local tok, pos, item

    tok=toks:next()
    while tok ~= nil
    do
       pos=tonumber(tok)
       if pos > 0
       then
         item=self.results_list[pos]
         self:download_item(item)
       end
       tok=toks:next()
    end
end,


view_page=function(self, toks)
local tok, pos, item

    tok=toks:next()
    while tok ~= nil
    do
       pos=tonumber(tok)
       if pos > 0
       then
         item=self.results_list[pos]
         if item ~= nil then ViewWebpage(item.url) end
       end
       tok=toks:next()
    end
end,


launch_program=function(self, toks)
local tok, pos, item, program

    pos=tonumber(toks:next())
    program=toks:remaining()

    if (pos > 0)
    then
         item=self.results_list[pos]
         if item ~= nil then ViewInBrowser(item.url, program) end
    end
end,



display_help=function(self)
print()
print("  type a command starting with '/', or a service shortname starting with '@' to switch service")
print("  otherwise type a line of text to send as a query to the current service")
print()
print("  commands:")
print("    @<short name>                - switch to datasource using it's short name, e.g. '@ddg'")
print("    /goto <short name>           - switch to datasource using it's short name, e.g. '/goto ddg'")
print("    /sources                     - list datasources")
print("    /info                        - display information about current source");
print("    /top                         - list 'top' results (e.g. flagged most popular) for datasources that support this");
print("    /new                         - list 'new' results (e.g. recent/today's news) for datasources that support this");
print("    /get <item id>               - download an item for datasources that support this")
print("    /view <item id>              - view details, or view URL of an item, for datasources that support this")
print("    /launch <item id>            - launch item url in default browser")
print("    /launch <item id> <program>  - launch item url with specified program")
print("    /help                        - list this help")
print("    /quit                        - exit program")
print()

end,



process_command=function(self, str)
local toks, tok, item, pos
local action=""

toks=strutil.TOKENIZER(str, "\\S")
if toks ~= nil
then
   tok=toks:next()
   if tok=="/goto" then self:change_source(toks:next())
   elseif tok=="/get" then self:download_items(toks) 
   elseif tok=="/view" then self:view_page(toks) 
   elseif tok=="/launch" then self:launch_program(toks) 
   elseif tok=="/top" then action="top"
   elseif tok=="/new" then action="new"
   elseif tok=="/info" then action="info"
   elseif tok=="/sources" then sources:iterate(self.display_source_status)
   elseif tok=="/debug" 
   then 
     if settings.debug == true then settings.debug=false
     else settings.debug=true
     Out:puts("debug: " .. tostring(settings.debug) .. "\n")
  end
   elseif tok=="/help" then self:display_help() 
   elseif tok=="/quit" then action="done"
   else Out:puts("~runrecognised command~0: "..tok.."\n")
   end
end

return action
end,


run=function(self, Out, query)
local prompt, str, action


sources:iterate(self.display_source_status)
self:change_source(query.source)


while true
do
  Out:puts("~etype /help for help~0\n")
  prompt=self:build_prompt(query.sources)
  str=Out:prompt(prompt)
  Out:puts("\n")

  if str=="quit" then break
  elseif string.sub(str, 1, 1)=="@" then self:change_source(string.sub(str, 2))
  elseif string.sub(str, 1, 1)=="/"
  then
      action=self:process_command(str)
      if action == "top" 
      then 
        query.question="!top"
        self.results_list=sources:query(query)
      elseif action == "new"
      then
        query.question="!new"
        self.results_list=sources:query(query)
      elseif action == "info"
      then
        query.question="!info"
        self.results_list=sources:query(query)
      elseif action == "done" then break
      end
  else
      query.question=strutil.trim(str)
      self.results_list=sources:query(query)
  end

end

end


}
function PrintHelp()

print("usage:")
print("   netscry.lua                                         - interactive mode")
print("   netscry.lua [options]                               - interactive mode")
print("   netscry.lua <service> <query string>                - send <query string> to service")
print("   netscry.lua [options] <service> <query string>      - send <query string> to service")
print("   netscry.lua -?                                      - this help")
print("   netscry.lua -h                                      - this help")
print("   netscry.lua -help                                   - this help")
print("   netscry.lua --help                                  - this help")
print()
print("services:")
print("   -ddg                                                - use duckduckgo");
print("   -ar                                                 - use archive.org");
print("   -ask                                                - use ask.ai");
print("   -askai                                              - use ask.ai");
print("   -tav                                                - use tavily.ai");
print("   -gem                                                - use google gemini-flash");
print("   -wp                                                 - use wikipedia");
print("   -ls                                                 - use langsearch");
print("   -so                                                 - use stackoverflow");
print("   -sx                                                 - use stackexchange");
print("   -dict                                               - use dictionary.dev");
print("   -bht                                                - use bighugethesaurus");
print("   -sfn                                                - use spaceflightnewsapi");
print("   -wn                                                 - use worldnewsapi");
print("   -gn                                                 - use gnews");
print("   -gnews                                              - use gnews");
print("   -hn                                                 - use hackernews");
print("   -bb                                                 - use bigbookapi");
print("   -db                                                 - use dbooks");
print("   -dbooks                                             - use dbooks");
print("   -ol                                                 - use openlibrary");
print("   -gb                                                 - use project gutenberg");
print("   -fo                                                 - use fossies");
print()
print("service options:")
print("   -n <max>                                            - maximum results to return (tavily.ai, bigbookapi, worldnewsapi, langsearch, gnews, hackernews)")
print("   -top                                                - return 'top' results (usually today's 'top' news) (gnews, worldnewsapi, hackernews)")
print("   -new                                                - return 'new' results (dbooks, hackernews)")
print("   -info                                               - return info about a source")
print("   -topic <topic>                                      - specify topic/category/subject for search (gnews, bigbookapi)")
print("   -t <topic>                                          - specify topic/category/subject for search (gnews, bigbookapi)")
print("   -list-topics                                        - print list of topics for specified source")
print("   -lang <iso code>                                    - specify language iso-code for search (gnews, worldnewsapi)")
print("   -l <iso code>                                       - specify language iso-code for search (gnews, worldnewsapi)")
print("   -country <country code>                             - specify country iso-code for search (gnews, worldnewsapi)")
print("   -c <country code>                                   - specify country iso-code for search (gnews, worknewsapi)")
print("   -item <id>                                          - specify item-id of specific item or article to lookup")
print("   -deep                                               - use deep/advanced search (tavily.ai)")
print()
print("general options:")
print("   -proxy <url>                                        - set proxy for network comms. e.g. '-proxy socks5:127.0.0.1:8080");
print("   -debug                                              - output debugging");
print("   -D                                                  - output debugging");
print("   -?                                                  - print this help");
print("   -help                                               - print this help");
print("   --help                                              - print this help");
end




function ParseCommandLine(cmd)
local arg, i, query
local act="query"

query=new_query()
for i,arg in ipairs(cmd)
do
  if arg=="-ddg" then query.sources=query.sources .. "duckduckgo "
  elseif arg=="-ar" then query.sources=query.sources .. "archive.org "
  elseif arg=="-ask" then query.sources=query.sources .. "ask_ai "
  elseif arg=="-askai" then query.sources=query.sources .. "ask_ai "
  elseif arg=="-tav" then query.sources=query.sources .. "tavily "
  elseif arg=="-gem" then query.sources=query.sources .. "gemini "
  elseif arg=="-wp" then query.sources=query.sources .. "wikipedia "
  elseif arg=="-so" then query.sources=query.sources .. "stackoverflow "
  elseif arg=="-ls" then query.sources=query.sources .. "langsearch "
  elseif arg=="-sx" then query.sources=query.sources .. "stackexchange "
  elseif arg=="-sfn" then query.sources=query.sources .. "spaceflightnewsapi "
  elseif arg=="-dict" then query.sources=query.sources .. "dictionary_dev "
  elseif arg=="-bht" then query.sources=query.sources .. "bighugethesaurus "
  elseif arg=="-wn" then query.sources=query.sources .. "worldnewsapi"
  elseif arg=="-bb" then query.sources=query.sources .. "bigbookapi"
  elseif arg=="-hn" then query.sources=query.sources .. "hackernews"
  elseif arg=="-gn" then query.sources=query.sources .. "gnews"
  elseif arg=="-gnews" then query.sources=query.sources .. "gnews"
  elseif arg=="-db" then query.sources=query.sources .. "dbooks"
  elseif arg=="-ol" then query.sources=query.sources .. "openlibrary"
  elseif arg=="-gb" then query.sources=query.sources .. "gutenberg"
  elseif arg=="-fo" then query.sources=query.sources .. "fossies"
  elseif arg=="-info" then query.question="!info" --anyting to do with sources goes through a query
  elseif arg=="-list-topics" then query.question="!topics" -- anything to do with sources goes through as a query
  elseif arg=="-top" then query.question="!top"
  elseif arg=="-new" then query.question="!new"
  elseif arg=="-l" or arg=="-lang"
  then
  query.language=cmd[i+1]
  cmd[i+1]=""
  elseif arg=="-c" or arg=="-country"
  then
  query.country=cmd[i+1]
  cmd[i+1]=""
  elseif arg=="-t" or arg=="-topic"
  then
  query.category=cmd[i+1]
  cmd[i+1]=""
  elseif arg=="-item"
  then
  query.item_id=cmd[i+1]
  query.question="!item"
  cmd[i+1]=""
  elseif arg=="-n"
  then 
  query.max_results=tonumber(cmd[i+1])
  cmd[i+1]=""
  elseif arg=="-view"
  then 
  act="view_page"
  query.url=cmd[i+1]
  cmd[i+1]=""
  elseif arg=="-proxy" 
  then 
  settings.proxy=cmd[i+1]
  cmd[i+1]=""
  elseif arg=="-deep" then query.search_level="deep"
  elseif arg=="-debug" then settings.debug=true
  elseif arg=="-l" then settings.long_results=true
  elseif arg=="-D" then settings.debug=true
  elseif arg=="-?" then act="help"
  elseif arg=="-h" then act="help"
  elseif arg=="-help" then act="help"
  elseif arg=="--help" then act="help"
  else
  query.question=query.question .. arg .. " "
  end
end

if strutil.strlen(query.sources) == 0 then query.sources="duckduckgo " end
query.question=strutil.trim(query.question)

return act, query
end








terminal.utf8(3)
Out=terminal.TERM(NULL, "rawkeys save")

--use this user agent for all connections
process.lu_set("HTTP:UserAgent", "NetScry (1.0)")

-- sources must be set up before settings
sources:init()
settings:init()

act,query=ParseCommandLine(arg)

--process.lu_set("Debug", "Y")
if settings.debug == true then process.lu_set("HTTP:Debug", "Y") end
if strutil.strlen(settings.proxy) > 0 then net.setProxy(settings.proxy) end

if act == "help" then PrintHelp()
elseif act == "view_page" then ViewWebpage(query.url)
elseif act == "list_topics" then sources:list_topics(query)
else
  if strutil.strlen(query.question) > 0 then sources:query(query) 
  else interactive:run(Out, query)
end
end

Out:reset()
print()

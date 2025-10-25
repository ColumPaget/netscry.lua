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

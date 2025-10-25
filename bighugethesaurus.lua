
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

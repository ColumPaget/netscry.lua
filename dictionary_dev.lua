
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

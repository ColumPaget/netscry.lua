
google_ai={
name="gemini",
short_name="gem",
type="ai",
needs_api_key=true,
url="https://gemini.google.com/",


parse_content=function(self, item)
local content
local output=""

content=item:open("content")
if content ~= nil
then
  item=content:next()
  while item ~= nil
  do
    output=output .. item:value("text")
    item=content:next()
  end
end


return output
end,




parse_response=function(self, json, query)
local P, steps, item
local str=""
local response={}

response.source=self.name
response.query=query.question

P=dataparser.PARSER("json", json)
steps=P:open("steps")
if steps ~= nil
then
   item=steps:next()
   while item ~= nil
   do
     str=str..self:parse_content(item)
     item=steps:next()
   end
   
   response.answer=markdown:convert("ansi", strutil.unQuote(str))
end

return response
end,


--[[ example model listing
    {
      "name": "models/gemini-2.5-flash",
      "version": "001",
      "displayName": "Gemini 2.5 Flash",
      "description": "Stable version of Gemini 2.5 Flash, our mid-size multimodal model that supports up to 1 million tokens, released in June of 2025.",
      "inputTokenLimit": 1048576,
      "outputTokenLimit": 65536,
      "supportedGenerationMethods": [
        "generateContent",
        "countTokens",
        "createCachedContent",
        "batchGenerateContent"
      ],
      "temperature": 1,
      "topP": 0.95,
      "topK": 64,
      "maxTemperature": 2,
      "thinking": true
    },
]]--

list_models=function(self)
local S, str, json, models

S=stream.STREAM("https://generativelanguage.googleapis.com/v1beta/models?key="..self.api_key, "r")
if S ~= nil
then
str=S:readdoc()


json=dataparser.PARSER("json", str)
models=json:open("models")
item=models:next()
while item ~= nil
do
print(item:value("name"))
item=models:next()
end

S:close()
end


end,



build_query_json=function(self, query)
local model, len
local query_json=""

model=query.model
if strutil.strlen(model) == 0 then model="gemini-flash-lite-latest" end

query_json=query_json .. "{\"model\": \"" .. model .."\""
query_json=query_json .. ",\n\"input\": \""..query.question .. "\""

--[[ handling voice is too much work right now
if model == "gemini-3.1-flash-tts-preview"
then
query_json=query_json .. ",\n\"response_format\": {\"type\": \"audio\"},\n"
query_json=query_json .. "\"generation_config\": {\"speech_config\": [{\"voice\": \"Kore\"}]},\n"
query_json=query_json .. "\"stream\": false\n"
end
]]--

query_json=query_json .."}"

len=strutil.strlen(query_json)

return query_json, len
end,


query=function(self, query)
local S, query_json, len, responsecode, doc

--self:list_models()

settings.debug=true

query_json,len=self:build_query_json(query)

S=stream.STREAM("https://generativelanguage.googleapis.com/v1beta/interactions?key="..self.api_key, "w Content-Type=application/json Content-Length="..tostring(len))
if S ~= nil
then
  S:writeln(query_json)
  S:commit()

  if settings.debug == true then io.stderr:write(query_json.."\n") end

  responsecode=S:getvalue("HTTP:ResponseCode")
  doc=S:readdoc()
  S:close()


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

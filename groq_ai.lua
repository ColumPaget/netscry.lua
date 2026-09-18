

groq_ai={
name="groq",
short_name="groq",
type="ai",
needs_api_key=true,
url="https://api.groq.com/openai/v1/responses",


list_models=function(self)
local S, str, json, models, item
local response={}


response.source=self.name
response.query="list-models"
response.answer=""


S=stream.STREAM("https://api.groq.com/openai/v1/models", "r Authorization='BEARER "..self.api_key.."'")
if S ~= nil
then
  str=S:readdoc()
  
  io.stderr:write(str.."\n")
  json=dataparser.PARSER("json", str)
  models=json:open("data")
  item=models:next()
  while item ~= nil
  do
    response.answer=response.answer .. strutil.padto(item:value("id"), " ", 40) .. "  " .. strutil.padto(item:value("owned_by"), " ", 20)  .. "  "

    str=JSONStringifyArray(item:open("input_modalities"))
    if strutil.strlen(str) > 0 then response.answer=response.answer.. "input:"..str.. " " end

    str=JSONStringifyArray(item:open("output_modalities"))
    if strutil.strlen(str) > 0 then response.answer=response.answer.. "output:"..str.. " " end

    response.answer=response.answer.."\n"

    item=models:next()
  end
  
  S:close()
end

return response
end,




parse_content=function(self, item)
local content
local output=""

content=item:open("content")
if content ~= nil
then
  item=content:next()
  while item ~= nil
  do
    if item:value("type") == "output_text"
    then
    output=output .. item:value("text")
    end
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
steps=P:open("output")
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



build_query_json=function(self, query)
local model, len
local query_json=""

model=query.model
if strutil.strlen(model) == 0 then model="openai/gpt-oss-20b" end

query_json=query_json .. "{\"model\": \"" .. model .."\""
query_json=query_json .. ",\n\"input\": \""..query.question .. "\""
query_json=query_json .."}"

len=strutil.strlen(query_json)

return query_json, len
end,



transact=function(self, query)
local S, query_json, len, responsecode, doc

query_json,len=self:build_query_json(query)

process.lu_set("HTTP:Debug", "Y")

S=stream.STREAM(self.url, "w Authorization='Bearer "..self.api_key.. "' Content-Type='application/json' Content-Length="..tostring(len))
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
    Out:puts("~rERROR:~0 Server Responds: ["..responsecode .. "]  " .. S:getvalue("HTTP:ResponseReason"))
    Out:puts(doc)
  else
    if settings.debug == true then io.stderr:write(doc.."\n") end
    return self:parse_response(doc, query)
  end
end

return nil
end,


query=function(self, query)

if query.question == "!models" then return(self:list_models()) end

return(self:transact(query))
end,

}


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

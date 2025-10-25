
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

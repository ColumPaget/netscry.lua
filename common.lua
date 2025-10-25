
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


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

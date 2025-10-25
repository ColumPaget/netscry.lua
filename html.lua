
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


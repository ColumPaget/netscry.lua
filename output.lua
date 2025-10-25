 
function OutputFormatSearchResult(search_result)
local str, toks, item
local output=""

 if search_result.content_is_html == true then str=HtmlFormatForTerminal(search_result.content)
 else str=search_result.content
 end

 if search_result.content_is_preformatted == false then str=string.gsub(str, "\n", " ")  end

 toks=strutil.TOKENIZER(str, "\n")
 item=toks:next()
 while item ~= nil
 do
 output=output .. "  " .. item .. "\n"
 item=toks:next()
 end

  if settings.long_results == true then return output end

 if strutil.strlen(output) > settings.result_text_len then return string.sub(output, 1, settings.result_text_len) .. " ~0~b...~0" end
 return output
end


function OutputSearchResult(i, item)
local str

      if item == nil then return end

      str="~g" .. string.format("%3d", i).."~0  "
      if item.id ~= nil then str=str .. "id:~m"..item.id.."~0 " end
      if item.mediatype ~= nil then str=str .. "~y~e" ..item.mediatype .."~0 " end
      if strutil.strlen(item.codecs) > 0 then str=str .. "~y~e" ..item.codecs .."~0 " end
      if item.date ~= nil then str=str .. "~b~e" ..item.date .."~0 " end
      if item.score ~= nil then str=str .. string.format("%3.3f", item.score) .." " end
      if item.title ~= nil then str=str .. "  ~e".. item.title .."~0" end
      if strutil.strlen(item.author) > 0 then  str=str .. " author: ~e~c" .. item.author.."~0 " end
      str=str.."\n"

      if strutil.strlen(item.url) ~= 0 then str=str .. "  ~e~b" .. item.url.."~0\n" end
      Out:puts(str)

      str=OutputFormatSearchResult(item)
      Out:puts(str .. "\n\n")
end


function OutputQuota(response)
local output=""
local total

if response.quota_used ~= nil
then
if response.quota_remain ~= nil then total=response.quota_used + response.quota_remain 
else total=response.quota_total
end

output="quota: " .. response.quota_used .. "/" .. total

end

return output
end


function OutputResponse(response, source)
local i,item, str

if response ~= nil
then
  Out:puts("~y -------- " .. source.name .. " (~b" .. source.url .."~0)  " .. OutputQuota(response) .. " reply to '" .. response.query .. "' --------~0\n")
  if strutil.strlen(source.donate) > 0 then Out:puts("~yDONATE:~0 consider donating to support this service at ~b"..source.donate.."~0" .. "\n") end
  if strutil.strlen(response.answer) > 0 then Out:puts(strutil.quoteChars(response.answer, "\\") .. "\n") end

  if response.search_results ~= nil
  then
    for i,item in ipairs(response.search_results)
    do
  OutputSearchResult(i, item)
    end
  end
  Out:puts("\n")
end

end




function OutputError(source_name, msg)

Out:puts("~rERROR~0: '~e"..source_name.."~0' "..msg.."\n")

end

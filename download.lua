
function Download(url, fname)
local S, toks, tok, str

S=stream.STREAM(url)
if S ~= nil
then
  str=S:getvalue("HTTP:Content-Disposition")
  if strutil.strlen(str) > 0
  then
  toks=strutil.TOKENIZER(str, ";")
  if toks ~= nil
  then
    tok=toks:next()
    while tok ~= nil
    do
    tok=strutil.trim(tok)
          if string.sub(tok, 1, 9) == "filename=" 
    then 
       fname=string.sub(tok, 10)
       fname=strutil.stripQuotes(fname)
    end
    tok=toks:next()
    end
  end
  end

  Out:puts("\rDownloading: ~e~b"..url.."~0 to "..fname.."\n")
  S:copy(fname)
  S:close()
else
  Out:puts("\r~rERROR~0: Download failed. Can't connect to: ~e~b"..url.."~0".."\n")
end

end

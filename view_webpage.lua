
function ViewWebpage(url)
local S, html, output

if strutil.strlen(url) > 0
then
S=stream.STREAM(url, "")
if S ~= nil
then
html=S:readdoc()
S:close()

output=HtmlFormatForTerminal(html)
Out:puts(output)
end
end

end


function ViewInBrowser(url, browser)

if strutil.strlen(browser) == 0
then 
  browser=settings.browser
  if strutil.strlen(browser) == 0 then browser="xdg-open" end
end

os.execute(browser.. " "..url)

end

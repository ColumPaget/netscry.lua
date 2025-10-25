

--this function generates a query object and initializes some values in it,
--like 'country' and 'language' from the user's local settings


function new_query()
local query={}
local toks, str

query.sources=""
query.question=""
query.country="us"
query.language="en"

str=process.getenv("LANG")
if str ~= nil
then
toks=strutil.TOKENIZER(str, "_|.", "m")
query.language=toks:next()
query.country=string.lower(toks:next())
end

return(query)
end

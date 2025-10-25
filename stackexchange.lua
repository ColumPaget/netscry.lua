



stackexchange={

sites={"Stack Overflow", "Server Fault", "Super User", "Meta Stack Exchange", "Web Applications", "Arqade", "Webmasters", "Seasoned Advice", "Game Development", "Photography", "Cross Validated", "Mathematics", "Home Improvement", "Geographic Information Systems", "TeX - LaTeX", "Ask Ubuntu", "Personal Finance & Money", "English Language & Usage", "Stack Apps", "User Experience", "Unix & Linux", "WordPress Development", "Theoretical Computer Science", "Ask Different", "Role-playing Games", "Bicycles", "Software Engineering", "Electrical Engineering", "Android Enthusiasts", "Board & Card Games", "Physics", "Homebrewing", "Information Security", "Writing", "Video Production", "Graphic Design", "Database Administrators", "Science Fiction & Fantasy", "Code Review", "Code Golf", "Quantitative Finance", "Project Management", "Skeptics", "Physical Fitness", "Drupal Answers", "Motor Vehicle Maintenance & Repair", "Parenting", "SharePoint", "Music: Practice & Theory", "Software Quality Assurance & Testing", "Mi Yodeya", "German Language", "Japanese Language", "Philosophy", "Gardening & Landscaping", "Travel", "Cryptography", "Signal Processing", "French Language", "Christianity", "Bitcoin", "Linguistics", "Biblical Hermeneutics", "History", "Bricks", "Spanish Language", "Computational Science", "Movies & TV", "Chinese Language", "Biology", "Poker", "Mathematica", "Psychology & Neuroscience", "The Great Outdoors", "Martial Arts", "Sports", "Academia", "Computer Science", "The Workplace", "Chemistry", "Chess", "Raspberry Pi", "Russian Language", "Islam", "Salesforce", "Ask Patents", "Genealogy & Family History", "Robotics", "ExpressionEngine® Answers", "Politics", "Anime & Manga", "Magento", "English Language Learners", "Sustainable Living", "Tridion", "Reverse Engineering", "Network Engineering", "Open Data", "Freelancing", "Blender", "MathOverflow", "Space Exploration", "Sound Design", "Astronomy", "Tor", "Pets", "Amateur Radio", "Italian Language", "Stack Overflow em Português", "Aviation", "Ebooks", "Beer, Wine & Spirits", "Software Recommendations", "Arduino", "Expatriates", "Mathematics Educators", "Earth Science", "Joomla", "Data Science", "Puzzling", "Craft CMS", "Buddhism", "Hinduism", "Community Building", "Worldbuilding", "Emacs", "History of Science and Mathematics", "Economics", "Lifehacks", "Engineering", "Coffee", "Vi and Vim", "Music Fans", "Woodworking", "CiviCRM", "Medical Sciences", "Stack Overflow на русском", "Русский язык", "Mythology & Folklore", "Law", "Open Source", "elementary OS", "Portuguese Language", "Computer Graphics", "Hardware Recommendations", "3D Printing", "Ethereum", "Latin Language", "Language Learning", "Retrocomputing", "Arts & Crafts", "Korean Language", "Monero", "Artificial Intelligence", "Esperanto Language", "Sitecore", "Internet of Things", "Literature", "Veganism & Vegetarianism", "Ukrainian Language", "DevOps", "Bioinformatics", "Computer Science Educators", "Interpersonal Skills", "Iota", "Stellar", "Constructed Languages", "Quantum Computing", "EOS.IO", "Tezos", "Operations Research", "Drones and Model Aircraft", "Matter Modeling", "Cardano", "Proof Assistants", "Substrate and Polkadot", "Bioacoustics", "Solana", "Programming Language Design and Implementation", "GenAI"},

name="stackexchange",
short_name="sx",
type="search",
needs_api_key=true,
api_key="",
url="https://stackoverflow.com/",

parse_item=function(self, response, item)
local answer={}
local tags, tag

--{"items":[{"tags":["html","web-scraping","architecture","piracy-prevention"],"question_score":350,"is_accepted":false,"answer_id":34828465,"is_answered":false,"question_id":3161548,"item_type":"answer","score":441,"last_activity_date":1542725271,"creation_date":1452956766,"body":"

answer.source=self.name
answer.id=item:value("question_id")
answer.title=item:value("title")
answer.url="https://stackoverflow.com/questions/" .. answer.id
answer.title=""
answer.score=item:value("score")
answer.content=strutil.unQuote(item:value("body"))

tags=item:open("tags")
tag=tags:next()
while tag ~= nil
do
answer.tags=answer.tags .. tag:value() .. ","
tag=tags:next()
end

table.insert(response.search_results, answer)

end,

query=function(self, query)
local S, doc, JSON, items, item
local response={}

response.query=query.question
response.source=self.name
response.search_results={}


S=stream.STREAM("https://api.stackexchange.com/search/excerpts?site=stackoverflow.com&key="..self.api_key.."&q=" .. strutil.httpQuote(query.question))
if S ~= nil
then
doc=S:readdoc()
S:close()
end

if settings.debug == true then io.stderr:write(doc.."\n") end

JSON=dataparser.PARSER("json", doc)
items=JSON:open("items")

item=items:next()
while item ~= nil
do
self:parse_item(response, item)
item=items:next()
end



return response
end,

}

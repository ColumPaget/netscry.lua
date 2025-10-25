PREFIX=/usr/local
MODS=includes.lua settings.lua common.lua download.lua html.lua markdown.lua duckduckgo.lua langsearch.lua wikipedia.lua stackexchange.lua google_ai.lua tavily_ai.lua ask_ai.lua dictionary_dev.lua bighugethesaurus.lua worldnewsapi.lua gnews.lua hackernews.lua spaceflightnewsapi.lua bigbookapi.lua dbooks.lua openlibrary.lua gutenberg.lua archive_org.lua fossies.lua output.lua sources.lua icons.lua query_object.lua view_webpage.lua interactive.lua command-line.lua main.lua

netscry.lua: $(MODS)
	cat $(MODS) > netscry.lua
	chmod a+x netscry.lua 

clean:
	rm netscry.lua

install:
	mkdir -p ~/bin
	cp netscry.lua ~/bin
	
install_system:
	mkdir -p $(PREFIX)/bin
	cp netscry.lua $(PREFIX)/bin

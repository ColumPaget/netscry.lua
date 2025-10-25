SYNOPSIS
========

netscry.lua is a simple command-line tool for querying several online datasources, including A.I. text-generation services, search-engines, and online dictionaries, thesauruses etc. For most of these services the user must get their own API key and put it in the netscry config file.


REQUIREMENTS
============

netscry.lua requires lua-5 (https://www.lua.org), libUseful-lua (https://github.com/ColumPaget/libUseful-lua) and libUseful (https://github.com/ColumPaget/libUseful) to be installed on your system. libUseful-lua requires swig (https://www.swig.org) to build.


INSTALL
=======

`make` rebuilds netscry.lua.
`make install` will attempt to install it in '~/bin' (bin subdirectory of the user's home dir).
`make install_system` will attempt to install it in '/usr/local/bin' (only root user should be able to do this).
`make install_system PREFIX=/usr` would attempt to install it in '/usr/bin/' (only root user can do this).

alternatively you can just copy netscry.lua to whereever you want.

running netscry.lua requires either invoking the lua interpreter ( `lua netscry.lua` ) or using the linux 'binfmt' system to automatically invoke lua.



SUPPORTED SERVICES
==================

* Duck Duck Go search
* Google Gemini 'Flash' A.I. 
* Ask A.I.
* Tavily A.I.
* LangSearch
* Wikipedia (currently 'summary' only)
* Stack Exchange
* dictionary.dev
* BigHugeThesaurus  
* Archive.org
* Stack Overflow
* Stack Exchange
* Dictionary.dev
* BigHugeThesaurus
* SpaceFlightNews
* WorldNews
* GNews (not google news)
* Hacker News
* Big Book API
* DBooks
* Open Library
* Project Gutenberg
* Fossies.org


CONFIG FILE
===========


The config file lives at `~/.config/netscry/netscry.conf` (where '~' represents the user's home directory). It currently has three types of entry:

* `nerdfonts=<boolean>`
* `key:<service>=<api key>`
* `browser=<string>`

If `nerdfonts=y` is present in the config file, then netscry in interactive mode will try to present a prettier interface using 'nerdfont' icons.

The 'key' entries provide API keys for the various services and look like: 'key:duckduckgo=183a6cc97ff8156'

The 'browser' setting specifies a command to use in 'interactive mode' to launch a browser and view a search result. This defaults to 'xdg-open' which will open the default browser.

You will have to get API keys for most of the services to use them (except duckduckgo, despite the example above). 



USAGE
=====

netscry can either take arguments on the command-line, or has an 'interactive mode' where queries are typed into a prompt. 

If no query is given on the command-line, only a service name and other arguments, then netscry will enter 'interactive mode'.


```
   netscry.lua                                         - interactive mode
   netscry.lua [options]                               - interactive mode
   netscry.lua <service> [options]                     - interactive mode
   netscry.lua <service> <query string>                - send <query string> to service
   netscry.lua <service> [options] <query string>      - send <query string> to service
   netscry.lua -?                                      - this help
   netscry.lua -h                                      - this help
   netscry.lua -help                                   - this help
   netscry.lua --help                                  - this help
```

command line 'service' options are:

```
-ddg 
: query duckduckgo
-ask
: query ask ai
-askai
: query ask ai
-tav
: query tavily.au
-gem
: query google gemini-flash ai
-wp
: query wikipedia (currently just returns a summary of a wikipedia page)
-ls
: query lang search
-sx
: query stack exchange
-so
: query stack overflow
-dict
: query dictionary.dev
-bht
: query bighugethesaurus.com
-sft
: query spaceflightnewsapi
-wn 
: query worldnewsapi
-gn 
: query gnews (not google news)
-gnews 
: query gnews (not google news)
-hn 
: query hacker news
-bb 
: query bigbookapi
-db 
: query dbooks api
-dbooks 
: query dbooks api
-ol
: query openlibrary.com
-gb
: query project gutenberg
-fo
: query 'fossies.org' open-source software directory
```



command line options related to source queries (and requiring one of the above source options) are:

```
-info
:print info about a source
-n <max>
:set maximum number of results to return for sites supporting this feature (currently supported: tavily.ai, bigbookapi, worldnewsapi, langsearch)
-top
:return 'top' results (usually today's 'top' news) (supported: gnews, worldnewsapi, hackernews, spaceflightnewsapi, fossies)
-new
:return 'new' results (dbooks, hackernews, fossies)
-cat <category>
: specify category/subject for search (gnews, bigbookapi)
-C <category>
: specify category/subject for search (gnews, bigbookapi)
-lang <iso code>
: specify language iso-code for search (gnews, worldnewsapi)
-l <iso code>
: specify language iso-code for search (gnews, worldnewsapi)
-country <country code> 
: specify country iso-code for search (gnews, worldnewsapi)
-c <country code> 
: specify country iso-code for search (gnews, worknewsapi)
-deep 
: do 'deep' or 'advanced' search for sites supporting this feature, (currently supported: tavily.ai)
-item <id>
: specify item-id of specific item or article to lookup
```


other 'general' command line options are:


```
-D
: print debug output
-debug
: print debug output
-proxy <url>
: set proxy for network comms. e.g. '-proxy socks5:127.0.0.1:8080'
-?
: print help
-help
: print help
--help
: print help
```


INTERACTIVE MODE
================


Interactive mode presents a prompt where queries can be typed in. The following commands can also be typed, each having a leading '/' or '@' to indicate they are a command. Some featuers (e.g. topics) are not yet supported in interactive mode.


```
    @<short name>                - switch to datasource using it's short name, e.g. '@ddg'
    /goto <short name>           - switch to datasource using it's short name, e.g. '/goto ddg'
    /sources                     - list datasources
    /info                        - display information about current source
    /top                         - list 'top' results (e.g. flagged most popular) for datasources that support this
    /new                         - list 'new' results (e.g. recent/today's news) for datasources that support this
    /get <item id>               - download an item for datasources that support this
    /view <item id>              - view details, or view URL of an item, for datasources that support this
    /launch <item id>            - launch item url in default browser
    /launch <item id> <program>  - launch item url with specified program
    /help                        - list this help
    /quit                        - exit program
```



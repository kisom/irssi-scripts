geojoin: irssi script to get GeoIP data on users joining a channel.
author: kyle isom <coder@kyleisom.net> 
license: isc / public domain - select whichever is less restrictive in your locale
latest version can be pulled from 
[github](https://github.com/kisom/irssi-scripts/tree/master/geojoin)
or you can clone the entire collection of scripts using:    
`git clone git://github.com/kisom/irssi-scripts.git`

dependencies:
* Geo::IP

usage:
`/load /path/to/geojoin.pl`    
`/geojoin add <channel list>`    
wait for people to join the channel...    

command list:
* add \<channels\>: add channels to list to watch
* del \<channels\>: remove channels from the watch list
* status: show geojoin's status, including whether it is using country or city 
lookups, whether it is enabled, and which channels are being watched
* watchlist: show a list of space-delimited channels being watched
* use_country: use country lookups
* use_city: use city record lookups
* set_citydb \<path\>: specify path to city record database    
* disable: disable lookups (preserves watchlist)
* enable: enable lookups
* clear: clear watchlist and disables geojoin

caveats:
* if you want to use city records you need the GeoLiteCity database at
<http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz>


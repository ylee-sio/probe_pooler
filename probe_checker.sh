#!/bin/bash

# db should be where ever all probe directories are located
db="~/probe_pooler/.probes"

# accessions
acc=$(cat ~/probe_pooler/place_request_form_here/*csv | cut -d "," -f 1 | sed 1d)

# hairpin for each probe/accession
hp=$(cat ~/probe_pooler/place_request_form_here/*csv | sed 1d | cut -d "," -f 2 | sed 1d)

# temp_pool unique id
pool=$(cat ~/probe_pooler/place_request_form_here/*csv | sed 1d | cut -d "," -f 3 | sed 1d)

for i in $acc
do
if [ -d "$HOME/probe_pooler/.probes/$i" ]
   then
   echo "$i exists"
else
   echo "$i does not exist"
fi
done

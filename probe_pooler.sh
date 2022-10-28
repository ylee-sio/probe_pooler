#!/bin/bash
session_record_num=$(shuf -i 10000000000-99999999999 -n 1)
cat $session_record_num > ~/test_probe_pool/.tmp/"subpool_000$p"/session_record.txt

# db should be where ever all probe directories are located
db="~/test_probe_pool/.probes"

cat ~/test_probe_pool/place_request_form_here/test_form.csv | cut -d "," -f 3 | sed 1d > ~/test_probe_pool/.tmp/temp_pool.txt
pool_length=$(cat .tmp/temp_pool.txt | sort | uniq | wc -l)

for (( p=1; p<=$pool_length; p++ ))
   do
   mkdir ~/test_probe_pool/.tmp/"subpool_000$p"
   csvgrep -c pool -m "$p" place_request_form_here/test_form.csv > ~/test_probe_pool/.tmp/"subpool_000$p"/tmp.csv
   cat ~/test_probe_pool/.tmp/"subpool_000$p"/tmp.csv | cut -d "," -f 1 | sed 1d > ~/test_probe_pool/.tmp/"subpool_000$p"/temp_acc.txt
   cat ~/test_probe_pool/.tmp/"subpool_000$p"/tmp.csv | cut -d "," -f 2 | sed 1d > ~/test_probe_pool/.tmp/"subpool_000$p"/temp_hp.txt
   cat ~/test_probe_pool/.tmp/"subpool_000$p"/tmp.csv | cut -d "," -f 3 | sed 1d > ~/test_probe_pool/.tmp/"subpool_000$p"/temp_pool.txt
   temp_acc_length=$(cat .tmp/"subpool_000$p"/temp_acc.txt | wc -l)
   paste -d "_" ~/test_probe_pool/.tmp/"subpool_000$p"/temp_acc.txt ~/test_probe_pool/.tmp/"subpool_000$p"/temp_hp.txt > ~/test_probe_pool/.tmp/"subpool_000$p"/temp_combos.txt

   for (( c=1; c<=$temp_acc_length; c++ ))
      do
	temp_acc_search_term=$(sed $c'q;d' .tmp/"subpool_000$p"/temp_acc.txt)
	temp_combo_search_term=$(sed $c'q;d' .tmp/"subpool_000$p"/temp_combos.txt)
	cp ~/test_probe_pool/.probes/$temp_acc_search_term/*/*all*/csv/*$temp_combo_search_term* .tmp/"subpool_000$p"
	sed 1d .tmp/"subpool_000$p"/*$temp_combo_search_term*.csv > .tmp/"subpool_000$p"/$temp_combo_search_term.temp_cleaned.csv
   done
   mkdir ~/test_probe_pool/.tmp/"subpool_000$p"/.tmp
   ls ~/test_probe_pool/.tmp/"subpool_000$p"/*.temp_cleaned.csv | parallel "sed 1d {}" > ~/test_probe_pool/.tmp/"subpool_000$p"/temp_subpool_1.csv
   awk -v pool_name="$new_pool" '$1=pool_name' FS=, OFS=, ~/test_probe_pool/.tmp/"subpool_000$p"/temp_subpool_1.csv > ~/test_probe_pool/.tmp/"subpool_000$p"/final_subpool.csv
   sed -i '1s/^/Pool name,Sequence\n/' ~/test_probe_pool/.tmp/"subpool_000$p"/final_subpool.csv
   mv ~/test_probe_pool/.tmp/"subpool_000$p"/*temp* ~/test_probe_pool/.tmp/"subpool_000$p"/.tmp
   
   # creating redundancies and transferring to permanent sharable location
   cat session_record_num > ~/test_probe_pool/.tmp/"subpool_000$p"/session_record_num.txt
   latest_pool=$(ls ~/OneDrive/LOCKED0001_hcr_probe_pools | sort | tail -1)
   latest_pool=${latest_pool:4:8}
   new_pool_num=$(($latest_pool + 1))
   new_pool=HL_P000$new_pool_num
   mkdir ~/OneDrive/LOCKED0001_hcr_probe_pools/$new_pool
   cp -r ~/test_probe_pool/"subpool_000$p" ~/OneDrive/LOCKED0001_hcr_probe_pools/$new_pool
done

rm ~/test_probe_pool/.tmp/temp_pool.txt

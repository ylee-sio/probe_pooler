#!/bin/bash
form=$1
session_record_num=$(shuf -i 100000000-999999999 -n 1)
receipt_record_num=$(shuf -i 100000000-999999999 -n 1)
timestamp=$(date +%c)
read -p 'Username: ' username
read -p 'Supervisor/PI: ' super
first_run_pass=$(ls ~/probe_pooler/.all_probe_pools/ | wc -l)
if [ $first_run_pass -gt 1 ]
then
ls ~/probe_pooler/.all_probe_pools/*/.tmp/*temp_XM* | sort | uniq > .current_total_probe_paths_list.txt
ls ~/probe_pooler/.all_probe_pools/*/.tmp/*temp_XM* | cut -d "/" -f 6 | sort | uniq > .current_total_probe_pools_list.txt
rm ~/*duplicates*

fi
# db should be where ever all probe directories are located
db="~/probe_pooler/.probes"

cat $form | cut -d "," -f 3 | sed 1d > ~/probe_pooler/.tmp/temp_pool.txt
pool_length=$(cat ~/probe_pooler/.tmp/temp_pool.txt | sort | uniq | wc -l)

for (( p=1; p<=$pool_length; p++ ))
   
   do
   last_probe_num=$(ls $HOME/probe_pooler/.all_probe_pools | wc -w) 
   new_probe_num=$(expr $last_probe_num + 1)
   pool_id=HL_HCR_PSET_"$new_probe_num"
   
   mkdir ~/probe_pooler/.tmp/"subpool_000$p"
   subsession_record_num=$(shuf -i 100000000-999999999 -n 1)
   csvgrep -c pool -m "$p" $form > ~/probe_pooler/.tmp/"subpool_000$p"/"$subsession_record_num"_pool_map.csv
   cat ~/probe_pooler/.tmp/"subpool_000$p"/"$subsession_record_num"_pool_map.csv | cut -d "," -f 1 | sed 1d > ~/probe_pooler/.tmp/"subpool_000$p"/temp_acc.txt
   cat ~/probe_pooler/.tmp/"subpool_000$p"/"$subsession_record_num"_pool_map.csv | cut -d "," -f 2 | sed 1d > ~/probe_pooler/.tmp/"subpool_000$p"/temp_hp.txt
   cat ~/probe_pooler/.tmp/"subpool_000$p"/"$subsession_record_num"_pool_map.csv | cut -d "," -f 3 | sed 1d > ~/probe_pooler/.tmp/"subpool_000$p"/temp_pool.txt
   cat ~/probe_pooler/.tmp/"subpool_000$p"/"$subsession_record_num"_pool_map.csv | cut -d "," -f 4 | sed 1d > ~/probe_pooler/.tmp/"subpool_000$p"/temp_genenames.txt
   
   temp_acc_length=$(cat ~/probe_pooler/.tmp/"subpool_000$p"/temp_acc.txt | wc -l)
   paste -d "_" ~/probe_pooler/.tmp/"subpool_000$p"/temp_acc.txt ~/probe_pooler/.tmp/"subpool_000$p"/temp_hp.txt > ~/probe_pooler/.tmp/"subpool_000$p"/temp_combos.txt

   for (( c=1; c<=$temp_acc_length; c++ ))
      do
	     temp_acc_search_term=$(sed $c'q;d' ~/probe_pooler/.tmp/"subpool_000$p"/temp_acc.txt)
        temp_genename=$(sed $c'q;d' ~/probe_pooler/.tmp/"subpool_000$p"/temp_genenames.txt)
	     temp_combo_search_term=$(sed $c'q;d' ~/probe_pooler/.tmp/"subpool_000$p"/temp_combos.txt)

        if [ $first_run_pass -gt 1 ]
            then
            if grep -q "$temp_acc_search_term" .current_total_probe_paths_list.txt
            then
            grep "$temp_acc_search_term" .current_total_probe_paths_list.txt | cut -d "/" -f 6 > ~/probe_pooler/"$session_record_num"_duplicates.txt
            echo "It looks like we've ordered $temp_acc_search_term in the past."
            echo "The user inputted gene name for $temp_acc_search_term is $temp_genename."
            printf "$temp_acc_search_term is currently present in the following pools: "
            cat "$session_record_num"_duplicates.txt
            read -p "Continue with pooling? (Enter y/n): " duplicate_check_answer
            echo ""
               if [ "$duplicate_check_answer" = 'y' ]
               then
               echo "Creating pool..."
                  elif [ "$duplicate_check_answer" = 'n' ]
                  then
                  echo "Stopped."
                  echo "Your session ID is $session_record_num."
                  cp ~/probe_pooler/"$session_record_num"_duplicates.txt ~/"$session_record_num"_duplicates.txt 
                  echo "$session_record_num"_duplicates.txt has been placed in your home folder.
                  echo "Please use the info in the file to remove duplicates from your current probe request. Update your probe request sheet and try again."
                  rm -rf ~/probe_pooler/.tmp/*
                  rm -rf ~/probe_pooler/.all_probe_pools/"$session_record_num"*
                  ls ~/probe_pooler/.all_probe_pools/*/.tmp/*temp_XM* | sort | uniq > .current_total_probe_paths_list.txt
                  ls ~/probe_pooler/.all_probe_pools/*/.tmp/*temp_XM* | cut -d "/" -f 6 | sort | uniq > .current_total_probe_pools_list.txt
                  exit 0
               fi       
            fi
         else
            echo "Processed $temp_combo_search_term."
         fi
   cp ~/probe_pooler/.probes/$temp_acc_search_term/*/*all*/csv/*"$temp_combo_search_term"* ~/probe_pooler/.tmp/"subpool_000$p"/temp_$temp_combo_search_term.csv
	sed 1d ~/probe_pooler/.tmp/"subpool_000$p"/*temp_$temp_combo_search_term*.csv > ~/probe_pooler/.tmp/"subpool_000$p"/$temp_combo_search_term.temp_cleaned.csv
   done
   
   mkdir ~/probe_pooler/.tmp/"subpool_000$p"/.tmp
   ls ~/probe_pooler/.tmp/"subpool_000$p"/*.temp_cleaned.csv | parallel "sed 1d {}" > ~/probe_pooler/.tmp/"subpool_000$p"/temp_subpool_1.csv
   awk -v pool_name="$pool_id" '$1=pool_name' FS=, OFS=, ~/probe_pooler/.tmp/"subpool_000$p"/temp_subpool_1.csv > ~/probe_pooler/.tmp/"subpool_000$p"/"$subsession_record_num"_final_subpool.csv
   sed -i '1s/^/Pool name,Sequence\n/' ~/probe_pooler/.tmp/"subpool_000$p"/"$subsession_record_num"_final_subpool.csv
   mv ~/probe_pooler/.tmp/"subpool_000$p"/*temp* ~/probe_pooler/.tmp/"subpool_000$p"/.tmp
   # creating summary report of each pool
   
   num_line_final_pool=$(cat ~/probe_pooler/.tmp/"subpool_000$p"/"$subsession_record_num"_final_subpool.csv | wc -l)
   price=$(echo "((($num_line_final_pool * 45)-3300)*0.02)+66" | bc -l)
   printf "session_record_num: $session_record_num" > ~/probe_pooler/.tmp/"subpool_000$p"/session_record.txt
   sed -i -e '$a\subsession_record_num: '$subsession_record_num ~/probe_pooler/.tmp/subpool_000$p/session_record.txt
   sed -i -e '$a\estimated_price: '$price ~/probe_pooler/.tmp/subpool_000$p/session_record.txt
   sed -i -e '$a\timestamp: '"$timestamp" ~/probe_pooler/.tmp/subpool_000$p/session_record.txt
   sed -i -e '$a\user: '$username ~/probe_pooler/.tmp/subpool_000$p/session_record.txt
   #sed -i -e '$a\This message has been auto generated with probe_pooler_v1 on pictus-2l' ~/probe_pooler/.tmp/subpool_000$p/session_record.txt
   #sed -i -e '$a\' ~/probe_pooler/.tmp/subpool_000$p/session_record.txt
   
   echo "$price" > ~/probe_pooler/.tmp/subpool_000$p/temp_pool_price.txt 
   mv ~/probe_pooler/.tmp/"subpool_000$p" ~/probe_pooler/.all_probe_pools/"$session_record_num"_"$pool_id"
   cp $form ~/probe_pooler/.all_probe_pools/"$session_record_num"_"$pool_id"/"$session_record_num"_pool_content_mapping.csv

done

cat ~/probe_pooler/.all_probe_pools/$session_record_num*/temp_pool_price.txt > total_session_price.txt
rm ~/probe_pooler/.all_probe_pools/$session_record_num*/temp_pool_price.txt
total_session_price=$(paste -sd+ total_session_price.txt | bc)

read -p "Notes of these/this pool: " message
echo "$message" > message.txt
sed -i -e '$a\ ' message.txt
sed -i '1s/^/Notes:\n/' message.txt
sed -i -e '$a\ ' message.txt
sed -i -e '$a\receipt_id: '$receipt_record_num message.txt
sed -i -e '$a\session_record_num: '$session_record_num message.txt
sed -i -e '$a\timestamp: '"$timestamp" message.txt
sed -i -e '$a\user: '$username message.txt
sed -i -e '$a\supervisor/PI: '$super message.txt
sed -i -e '$a\*****************************************************************************************************' message.txt
sed -i -e '$a\estimated_price: '$total_session_price message.txt
num_pools=$(ls ~/probe_pooler/.all_probe_pools | grep "$session_record_num" | wc -l)
sed -i -e '$a\number of pools generated: '$num_pools message.txt
num_genes=$(ls ~/probe_pooler/.all_probe_pools/$session_record_num*/"$session_record_num"_pool_content_mapping.csv | parallel "sed 1d {}" | sort | uniq | wc -l)
sed -i -e '$a\total number of genes across pools: '$num_genes message.txt
sed -i -e '$a\ ' message.txt
sed -i -e '$a\You can check the attached probe_inventory_update.txt to see which probes we currently have in stock.' message.txt
sed -i -e '$a\probe_inventory_update.txt includes the probes submitted in this run.' message.txt
sed -i -e '$a\' message.txt
sed -i -e '$a\*****************************************************************************************************' message.txt
sed -i -e '$a\ ' message.txt
sed -i -e '$a\Correctly formatted oPools files are attached in the zipped folder. Probe mappings to each order are included as well.' message.txt
sed -i -e '$a\Unique numbers and IDs generated at this point in the pipeline will be linked to all metadata related the experiments using these oligos. ' message.txt
sed -i -e '$a\DO NOT attempt to rename or reorganize files in this directory.' message.txt
sed -i -e '$a\This message has been auto generated with probe_pooler_v1 on pictus-2l.' message.txt

unique_probes_update=$(ls ~/probe_pooler/.all_probe_pools/*/*content* | parallel "sed 1d {}" | sort | uniq)
printf "$unique_probes_update" > probe_inventory_update.txt
sed -i '1s/^/accession,hairpin,pool,common_gene_name,ref_species\n/' probe_inventory_update.txt
sed -i '1s/^/\n/' probe_inventory_update.txt
sed -i '1s/^/These are the current probes we have in stock (including the pools generated with this run):\n/' probe_inventory_update.txt
sed -i -e '$a\ ' probe_inventory_update.txt

mv probe_inventory_update.txt ~/probe_pooler/.all_probe_pools/"$session_record_num"_"$pool_id"/probe_inventory_update.txt

read -p "(MANDATORY) Enter your email address: " user_email_address
read -p "(MANDATORY) Enter your PI's email address: " pi_email_address

mkdir $session_record_num
cp -r ~/probe_pooler/.all_probe_pools/$session_record_num* $session_record_num
zip -rq $session_record_num.zip $session_record_num

cat message.txt | mail -s "probe pooling receipt: $receipt_record_num" -A "$session_record_num.zip" -A probe_inventory_update.txt "$user_email_address"
cat message.txt | mail -s "probe pooling receipt: $receipt_record_num" -A "$session_record_num.zip" -A probe_inventory_update.txt "$pi_email_address"

rm ~/probe_pooler/.tmp/temp_pool.txt
rm -r probe_pooler/message*
rm total_session_price.txt

echo "******************** SUMMARY ********************"
ls $session_record_num/*/session_record.txt | parallel "cat {}"

for i in $session_record_num/*
do
echo ""
show_pool=$(echo $i)
basename $show_pool 
cat $i/session_record.txt
echo ""
cat $i/*pool_map*
echo "*************************************************"
done
echo ""
echo "YOUR POOL RECEIPT NUMBER: $receipt_record_num"
echo "Your formatted IDT oPools probe pool files have been sent to $user_email_address and $pi_email_address."
echo ""
rm message.txt
#rm $form
rm -rf $session_record_num*

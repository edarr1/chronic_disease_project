#!/bin/bash
# Authors: Emma Darr, Ellie Farrell
# Purpose: Generate Summary of Ind. Level and County Data
# Date: 3/3/2026


DIAB="data/clean/diabetes_individual_clean.csv"
COUNTY="data/raw/chronic_county.csv"
OUTPUT="output/tables/shell_summary.txt"

#diabetes prevalence from cleaned individual data
count=$(cut -d',' -f7 "$DIAB" | tail -n +2 | grep -c '1')
n=$(tail -n +2 "$DIAB" | wc -l)
ind_prev=$(awk -v c="$count" -v n="$n" 'BEGIN{print c/n}')


#compute mean BMI by htn status
bmi_0=$(tail -n +2 "$DIAB" | awk -F',' -v b=2 -v h=6 '
{
sum[$h]+=$b
count[$h]++
}
END {print sum[0]/count[0]}')

bmi_1=$(tail -n +2 "$DIAB" | awk -F',' -v b=2 -v h=6 '
{
sum[$h]+=$b
count[$h]++
}
END {print sum[1]/count[1]}')

#top 5 county by diab prev
top5=$(tail -n +2 "$COUNTY" | sort -t',' -k3,3nr | head -n 5)


#high burden counties
hb=$(tail -n +2 "$COUNTY" | awk -F',' -v dt=0.15 -v ht=0.30 '
{
d=$3; h=$4

if (d>=dt && h>=ht) {
	flag="high"
	print $0
	found=1}
}
END{if (!found) print "None"
}')


#output
echo -e "Prevalence: $ind_prev \n\
\n\
Mean BMI (HTN=0): $bmi_0 \n\
Mean BMI (HTN=1): $bmi_1 \n\
\n\
Top 5 Counties by Diabetes Prev.: \n\
$top5 \n\
\n\
High Burden Counties: \n\
$hb \n" >> $OUTPUT

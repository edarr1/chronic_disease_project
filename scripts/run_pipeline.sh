#!/bin/bash
# Authors: Emma Darr, Ellie Farrell
# Purpose: Excute chronic disease project pipeline

set -e

#Create directory (assumes chronic_disease_project already created and cd)

mkdir -p data/raw \
         data/clean \
         scripts \
         sql \
         output/tables \
         output/reports \
         logs

touch logs/pipeline_log.txt

LOG="logs/pipeline_log.txt"
echo "$(date) | Starting pipeline" >> $LOG

# Function to log steps with timestamp
log_step() {
    echo "$(date) | $1" >> "$LOG"
}

#Clean individual data
log_step "Clean individual data"
bash scripts/clean_individuals_data.sh

#Generate shell summary
log_step "Generate shell summary"
bash scripts/generate_summary.sh

#Setup database
log_step "Setup DB"
Rscript sql/setup_database.R

#Run all queries & export CSV
log_step "Run & export all queries"
Rscript sql/run_all_queries.R

#Generate summary
log_step "Summarize key findings"
Rscript sql/summarize_findings.R 

echo "$(date) | Pipeline finished successfully" >> $LOG

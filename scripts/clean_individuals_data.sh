  #!/bin/bash
  # Authors: Emma Darr, Ellie Farrell
  # Purpose: Clean individual-level diabetes data
  # Date:    03/03/36
  INPUT="data/raw/diabetes_individual_with_race.csv"
  OUTPUT="data/clean/diabetes_individual_clean.csv"
  LOG="logs/cleaning_log.txt"

  if [ ! -f "$INPUT" ]; then
      echo "ERROR: $INPUT not found" | tee -a "$LOG"
      exit 1
  fi

  BEFORE=$(wc -l < "$INPUT")
  head -n 1 "$INPUT" > "$OUTPUT"
  tail -n +2 "$INPUT" | awk -F, '$2!=0 && $3!=0 && $4!=0 {print}' >> "$OUTPUT"
  AFTER=$(wc -l < "$OUTPUT")

  echo "$(date): Cleaned $INPUT — Before: $BEFORE, After: $AFTER" >> "$LOG"

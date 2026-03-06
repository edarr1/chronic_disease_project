# Task 3.1: Summary of Key Findings
# Authors: Emma Darr, Ellie Farrell

library(tidyverse)
library(DBI)
library(RSQLite)

setwd("C:/Users/emmad/chronic_disease_project")

# Create/Connect to SQLite Database
con <- dbConnect(
  drv = RSQLite::SQLite(),             
  dbname = "chronic_disease_surveillance.sqlite"
)


diab_race <- read.csv("output/tables/queryC.csv")
burden <- read.csv("output/tables/queryJ.csv")
#Extra: dist of race for each clinic
qX <- "
SELECT
  ic.Race1 AS Race,
  ic.clinic_id AS ClinicID,
  COUNT(*) AS NumIndividuals
FROM individuals_clinic ic
GROUP BY ic.Race1, ic.clinic_id
ORDER BY ic.clinic_id, ic.Race1;
"
clinic <- dbGetQuery(con,qX)


#Ordered race by diabetes prev
ordered_diab_race <- diab_race[order(diab_race$diabetes_proportion,decreasing = T),]

#Ordered race by triple burden
ordered_burden <- burden[order(burden$triple_prop, decreasing = T),]

#Distribution of race by clinic
clinic2 <- clinic[order(clinic$Race),]

summary <- c(
  "Summary of Key Findings",
  "",
  "Race by Diabetes Prevalence:",
  capture.output(ordered_diab_race),
  "",
  "Race by Triple Burden Prevalence:",
  capture.output(ordered_burden),
  "",
  "Distribution of Randomized Subjects' Race by Clinic",
  capture.output(clinic2)
)


#cat(paste(summary,collapse = "\n"))

write.table(summary, file = "output/tables/key_findings.txt", sep = "\t", row.names = FALSE, quote = F)


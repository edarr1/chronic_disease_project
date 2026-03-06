# Task 2.1: Database Setup
# Authors: Emma Darr, Ellie Farrell

#options(repos = c(CRAN = "https://cloud.r-project.org"))
#packages <- c("tidyverse","DBI","RSQLite")
#install.packages(packages, dependencies = T)

#.libPaths("C:/Users/emmad/AppData/Local/R/win-library/4.4")
library(tidyverse)
library(DBI)
library(RSQLite)

setwd("C:/Users/emmad/chronic_disease_project")


# Create/Connect to SQLite Database
con <- dbConnect(
  drv = RSQLite::SQLite(),             
  dbname = "chronic_disease_surveillance.sqlite"
)


# Individuals Table
ind_df <- read.csv("data/clean/diabetes_individual_clean.csv")
ind_df$ID <- 1:1000
ind_df <- ind_df %>% relocate(ID)

dbWriteTable(
  conn = con,                          
  name = "individuals",                
  value = ind_df,                   
  overwrite = TRUE                     
)


# County Table

county_df <- read.csv("data/raw/chronic_county.csv")

dbWriteTable(
  conn = con,                          
  name = "county_prevalence",                
  value = county_df,                   
  overwrite = TRUE                     
)


# Race Lookup Table

race_df <- tibble(
  Race1 = c("White", "Black", "Hispanic", "Asian", "Other"),  # original categories
  RaceGroup = c(                                              # broader groupings
    "Non-Hispanic White",
    "Non-Hispanic Black",
    "Hispanic",
    "Non-Hispanic Asian",
    "Other / Multi-racial"
  )
)


dbWriteTable(
  conn = con,                          
  name = "race_lookup",                
  value = race_df,                   
  overwrite = TRUE                     
)


# Clinic Summary Table
q_clinic_create <- "
CREATE TABLE IF NOT EXISTS clinic_summary (
  clinic_id INTEGER PRIMARY KEY,     -- unique clinic ID
  clinic_name TEXT,                  -- clinic name
  county TEXT,                       -- county for the clinic
  total_patients INTEGER,            -- total patients seen (admin value)
  diabetes_patients INTEGER,         -- recorded diabetes patients (admin value)
  hypertension_patients INTEGER      -- recorded hypertension patients (admin value)
);
"
dbExecute(con, q_clinic_create)

q_clinic_insert <- "
INSERT INTO clinic_summary (
  clinic_id, clinic_name, county, total_patients, diabetes_patients, hypertension_patients
)
VALUES
  (1, 'Downtown Health Center', 'Orleans',   1000, 150, 300),
  (2, 'River Parish Clinic',   'Jefferson',   800, 120, 250)
ON CONFLICT(clinic_id) DO NOTHING;  -- avoid duplicate inserts
"
dbExecute(con, q_clinic_insert)


# Individuals-Clinic Table

set.seed(123)

ind_clinic_df <- ind_df %>%
  mutate(
    clinic_id = sample(
      x = c(1,2),
      size = n(),
      replace = TRUE
    )
  )

dbWriteTable(
  conn = con,                          
  name = "individuals_clinic",                
  value = ind_clinic_df,                   
  overwrite = TRUE                     
)


# Verify Tables

dbListTables(con)
dbListFields(con, "individuals")
dbListFields(con, "county_prevalence")
dbListFields(con, "race_lookup")
dbListFields(con, "clinic_summary")
dbListFields(con, "individuals_clinic")

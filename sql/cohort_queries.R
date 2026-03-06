# Task 2.2: Cohort Queries
# Authors: Emma Darr, Ellie Farrell

setwd("C:/Users/emmad/chronic_disease_project")

library(tidyverse)
library(DBI)
library(RSQLite)



#A: Comorbid cohort
qA <- "
SELECT
    COUNT(*) AS n_comorbid,
    AVG(Age) AS mean_age,
    AVG(BMI) AS mean_bmi
FROM individuals
WHERE Age >= 18
  AND Diabetes = 1
  AND Hypertension = 1
"

resA <- dbGetQuery(con, qA)
print(resA)



#B: High risk cohort
qB <- "
CREATE VIEW high_risk_adults AS
SELECT *
FROM individuals
WHERE Age >= 45 AND Age <= 64
  AND BMI >= 30
  AND Hypertension = 1;
"
dbExecute(con, "DROP VIEW IF EXISTS high_risk_adults;")
dbExecute(con, qB)
resB <- dbGetQuery(con, "SELECT * FROM high_risk_adults;")
print(resB)



#C: Diabetes by race group
qC <- "
SELECT 
  r.RaceGroup,
  COUNT(*) AS total_n,
  SUM(i.Diabetes) AS diabetes_n,
  AVG(i.Diabetes) AS diabetes_proportion
FROM individuals i
LEFT JOIN race_lookup r
  ON i.Race1 = r.RaceGroup
GROUP BY r.RaceGroup
ORDER BY r.RaceGroup;
"
resC <- dbGetQuery(con, qC)
print(resC)



#D: Age-band cross-tabulations
qD <-"
SELECT
  CASE
    WHEN Age < 30 THEN '<30'
    WHEN Age BETWEEN 30 AND 44 THEN '30-44'
    WHEN Age BETWEEN 45 AND 59 THEN '45-59'
    ELSE '60+'
  END AS AgeBand,
  Hypertension,
  COUNT(*) AS n
FROM individuals
GROUP BY AgeBand, Hypertension
ORDER BY AgeBand, Hypertension;
"

resD <- dbGetQuery(con, qD)
print(resD)



#E: Missing value audit
qE <- "
SELECT
  SUM(CASE WHEN BMI IS NULL THEN 1 ELSE 0 END) AS BMI_missing,
  SUM(CASE WHEN BloodPressure IS NULL THEN 1 ELSE 0 END) AS BP_missing,
  SUM(CASE WHEN Glucose IS NULL THEN 1 ELSE 0 END) AS Glucose_missing,
  SUM(CASE WHEN Smoking IS NULL THEN 1 ELSE 0 END) AS Smoking_missing
FROM individuals;
"

resE <- dbGetQuery(con, qE)
print(resE)



#Write out .csv
write.csv(resA, "output/tables/queryA.csv", row.names = FALSE)
write.csv(resB, "output/tables/queryB.csv", row.names = FALSE)
write.csv(resC, "output/tables/queryC.csv", row.names = FALSE)
write.csv(resD, "output/tables/queryD.csv", row.names = FALSE)
write.csv(resE, "output/tables/queryE.csv", row.names = FALSE)


# All SQL Queries
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

#F: Clinic Metrics (calculated from the individuals_clinic table)
qF <- "
SELECT
  ic.clinic_id,
  cs.clinic_name,
  COUNT(*) AS total_patients,

  SUM(CASE WHEN ic.Diabetes = 1 THEN 1 ELSE 0 END) AS diabetes_n,
  SUM(CASE WHEN ic.Diabetes = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS diabetes_prop,

  SUM(CASE WHEN ic.Hypertension = 1 THEN 1 ELSE 0 END) AS hypertension_n,
  SUM(CASE WHEN ic.Hypertension = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS hypertension_prop,

  SUM(CASE
        WHEN ic.Diabetes = 1 AND ic.Hypertension = 1
        THEN 1 ELSE 0
      END) AS both_conditions_n

FROM individuals_clinic ic
LEFT JOIN clinic_summary cs
  ON ic.clinic_id = cs.clinic_id
GROUP BY ic.clinic_id, cs.clinic_name
ORDER BY ic.clinic_id;
"
resF <- dbGetQuery(con,qF)

#G: High prevalence clinics (calculated from individuals_clinic table)
qG <- "
SELECT *
FROM (
  SELECT
    ic.clinic_id,
    cs.clinic_name,
    SUM(CASE WHEN ic.Diabetes = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS diabetes_prop
  FROM individuals_clinic ic
  LEFT JOIN clinic_summary cs
    ON ic.clinic_id = cs.clinic_id
  GROUP BY ic.clinic_id, cs.clinic_name
) clinic_stats
WHERE diabetes_prop > 0.20;
"
resG <- dbGetQuery(con,qG)

#H: BMI class by clinic
qH <- "
SELECT
  ic.clinic_id,
  cs.clinic_name,

  CASE
    WHEN ic.BMI < 18.5 THEN 'Underweight'
    WHEN ic.BMI >= 18.5 AND ic.BMI < 25 THEN 'Normal'
    WHEN ic.BMI >= 25 AND ic.BMI < 30 THEN 'Overweight'
    ELSE 'Obese'
  END AS bmi_category,

  COUNT(*) AS n

FROM individuals_clinic ic
LEFT JOIN clinic_summary cs
  ON ic.clinic_id = cs.clinic_id

GROUP BY ic.clinic_id, cs.clinic_name, bmi_category
ORDER BY ic.clinic_id, bmi_category;
"
resH <- dbGetQuery(con,qH)

#I: Window function
qI <- "
SELECT *
FROM (
  SELECT
    ID,
    Age,
    BloodPressure,

    CASE
      WHEN Age < 30 THEN '<30'
      WHEN Age BETWEEN 30 AND 44 THEN '30-44'
      WHEN Age BETWEEN 45 AND 59 THEN '45-59'
      ELSE '60+'
    END AS AgeGroup,

    ROW_NUMBER() OVER (
      PARTITION BY
        CASE
          WHEN Age < 30 THEN '<30'
          WHEN Age BETWEEN 30 AND 44 THEN '30-44'
          WHEN Age BETWEEN 45 AND 59 THEN '45-59'
          ELSE '60+'
        END
      ORDER BY BloodPressure DESC
    ) AS bp_rank

  FROM individuals
) ranked_bp
WHERE bp_rank <= 3
ORDER BY AgeGroup, bp_rank;
"
resI <- dbGetQuery(con,qI)

#J: Triple burder
qJ <- "
SELECT *
FROM (
  SELECT
    r.RaceGroup,
    COUNT(*) AS total_n,

    SUM(
      CASE 
        WHEN i.BMI >= 30 AND i.Hypertension = 1 AND i.Diabetes = 1
        THEN 1 ELSE 0
      END
    ) AS triple_n,

    SUM(
      CASE 
        WHEN i.BMI >= 30 AND i.Hypertension = 1 AND i.Diabetes = 1
        THEN 1 ELSE 0
      END
    ) * 1.0 / COUNT(*) AS triple_prop

  FROM individuals i
  LEFT JOIN race_lookup r
    ON i.Race1 = r.RaceGroup

  GROUP BY r.RaceGroup
) race_stats
WHERE triple_prop > 0.10
ORDER BY triple_prop DESC;
"
resJ <- dbGetQuery(con,qJ)

#Write out .csv
write.csv(resA, "output/tables/queryA.csv", row.names = FALSE)
write.csv(resB, "output/tables/queryB.csv", row.names = FALSE)
write.csv(resC, "output/tables/queryC.csv", row.names = FALSE)
write.csv(resD, "output/tables/queryD.csv", row.names = FALSE)
write.csv(resE, "output/tables/queryE.csv", row.names = FALSE)
write.csv(resF, "output/tables/queryF.csv", row.names = FALSE)
write.csv(resG, "output/tables/queryG.csv", row.names = FALSE)
write.csv(resH, "output/tables/queryH.csv", row.names = FALSE)
write.csv(resI, "output/tables/queryI.csv", row.names = FALSE)
write.csv(resJ, "output/tables/queryJ.csv", row.names = FALSE)


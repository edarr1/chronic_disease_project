# Task 2.3: Clinic Level Surveillance Queries
# Authors: Emma Darr, Ellie Farrell

setwd("C:/Users/emmad/chronic_disease_project")

library(tidyverse)
library(DBI)
library(RSQLite)


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
print(resF)



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
print(resG)



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
print(resH)


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

resX <- dbGetQuery(con,qX)


#Write out .csv
write.csv(resF, "output/tables/queryF.csv", row.names = FALSE)
write.csv(resG, "output/tables/queryG.csv", row.names = FALSE)
write.csv(resH, "output/tables/queryH.csv", row.names = FALSE)

# Task 2.4: Advanced Analytics
# Authors: Emma Darr, Ellie Farrell

setwd("C:/Users/emmad/chronic_disease_project")

library(tidyverse)
library(DBI)
library(RSQLite)


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
print(resI)



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
print(resJ)



#K: Low income diabetes
# no income data


#Write out .csv
write.csv(resI, "output/tables/queryI.csv", row.names = FALSE)
write.csv(resJ, "output/tables/queryJ.csv", row.names = FALSE)
#write.csv(resK, "output/tables/queryK.csv", row.names = FALSE)

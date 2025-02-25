-- Section 1: Change in Forest Area
WITH WLD1 AS (
    SELECT country_name, forest_area_sqkm
    FROM forest_area
    WHERE country_name = 'World' AND year = 2016
),
WLD2 AS (
    SELECT country_name, forest_area_sqkm
    FROM forest_area
    WHERE country_name = 'World' AND year = 1990
)

-- Calculate difference in forest area
SELECT (WLD1.forest_area_sqkm - WLD2.forest_area_sqkm) AS difference
FROM WLD1
JOIN WLD2
ON WLD1.country_name = WLD2.country_name;

-- Self-join alternative
SELECT 
    fa1.forest_area_sqkm - fa2.forest_area_sqkm AS difference
FROM forest_area fa1
JOIN forest_area fa2
ON fa1.country_name = fa2.country_name
WHERE fa1.country_name = 'World' 
AND fa1.year = 2016 
AND fa2.year = 1990;

-- Calculate percentage change
SELECT (WLD1.forest_area_sqkm - WLD2.forest_area_sqkm)/WLD2.forest_area_sqkm*100 AS difference
FROM WLD1
JOIN WLD2
ON WLD1.country_name = WLD2.country_name;

-- Find region matching forest loss area
SELECT *
FROM land_area
WHERE year = 2016 AND total_area_sq_mi <= 1324449/2.59
ORDER BY total_area_sq_mi DESC;

-- Section 2: Percentage of Forest Area vs Land Area
SELECT 
    r.region, 
    la.year,
    (SUM(fa.forest_area_sqkm) / 2.59) / SUM(la.total_area_sq_mi) * 100 AS percent_forest
FROM forest_area fa
JOIN land_area la
    ON fa.country_name = la.country_name 
    AND fa.year = la.year 
JOIN regions r 
    ON r.country_name = la.country_name
GROUP BY 1, 2
HAVING la.year = 2016 OR la.year = 1990
ORDER BY la.year, percent_forest DESC;

-- Section 3: Forest Area Changes by Country
WITH f1 AS (
    SELECT country_name, year, forest_area_sqkm
    FROM forest_area
    WHERE year = 1990
),
f2 AS (
    SELECT country_name, year, forest_area_sqkm
    FROM forest_area
    WHERE year = 2016
)

-- Forest area difference per country
SELECT f1.country_name, f1.forest_area_sqkm prev_area, f2.forest_area_sqkm new_area, 
       f2.forest_area_sqkm-f1.forest_area_sqkm difference
FROM f1 
JOIN f2
ON f1.country_name = f2.country_name
WHERE f2.forest_area_sqkm-f1.forest_area_sqkm < 0
ORDER BY f2.forest_area_sqkm-f1.forest_area_sqkm ASC
LIMIT 6;

-- Top 5 countries by percentage forest loss
SELECT f1.country_name, f1.forest_area_sqkm prev_area, f2.forest_area_sqkm new_area, 
       f2.forest_area_sqkm-f1.forest_area_sqkm difference, 
       (f2.forest_area_sqkm-f1.forest_area_sqkm)/f1.forest_area_sqkm*100 percent_loss
FROM f1 
JOIN f2
ON f1.country_name = f2.country_name
WHERE f2.forest_area_sqkm-f1.forest_area_sqkm < 0
ORDER BY (f2.forest_area_sqkm-f1.forest_area_sqkm)/f1.forest_area_sqkm*100 ASC
LIMIT 5;

-- Count of countries in each forestation quartile
WITH forestation_data AS (
    SELECT 
        fa.country_name, 
        (fa.forest_area_sqkm / 2.59) / NULLIF(la.total_area_sq_mi, 0) * 100 AS percent_forest
    FROM forest_area fa
    JOIN land_area la
        ON fa.country_name = la.country_name 
        AND fa.year = la.year
    WHERE fa.year = 2016
),
quartiles_data AS (
    SELECT 
        country_name,
        CASE
            WHEN percent_forest IS NULL THEN 0
            WHEN percent_forest <= 25 THEN 1
            WHEN percent_forest <= 50 THEN 2
            WHEN percent_forest <= 75 THEN 3
            ELSE 4
        END AS quartiles
    FROM forestation_data
)

SELECT quartiles, COUNT(*)
FROM quartiles_data
GROUP BY quartiles
ORDER BY quartiles;

-- Countries in the fourth quartile
SELECT *
FROM quartiles_data
WHERE quartiles = 4;

-- Countries with more forestation than the U.S.
SELECT COUNT(*)
FROM forestation_data
WHERE percent_forest >
(SELECT percent_forest
 FROM forestation_data
 WHERE country_name = 'United States');

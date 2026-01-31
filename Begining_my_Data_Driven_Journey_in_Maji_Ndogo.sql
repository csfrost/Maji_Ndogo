-- Query that identifies the unique type of water source
WITH Unique_water_source AS(
SELECT
	DISTINCT type_of_water_source
FROM
	md_water_services.water_source),

-- Query that retrieves data from employee table
Employee AS (
SELECT 
	* 
FROM 
	md_water_services.employee),

-- Query that retrieves data from location table
Location AS (
SELECT 
	* 
FROM 
	md_water_services.location),

-- Query that retrieves data from visits table
Visits AS (
SELECT
	*
FROM
	md_water_services.visits),
    
-- Query that retrieves data from water_quality table
Water_quality AS (
SELECT
	*
FROM
	md_water_services.water_quality),

-- Query that retrieves data from water_source table
Water_source AS (
SELECT
	*
FROM
	md_water_services.water_source),

-- Query that retrieves data from well_pollution table
Well_pollution AS (
SELECT
	*
FROM
	md_water_services.well_pollution),

/* Query that retrieves records from the visists table
where time in queue is greater than 500 minutes*/
Greater_than_500_mins_queue_time AS(
SELECT
	record_id,
    location_id,
    source_id,
    time_in_queue,
    assigned_employee_id
FROM
	md_water_services.visits
WHERE
	visit_count > 1
    AND
		time_in_queue > 500),

/* Query that checks the following source_id's ('AkKi00881224', 'SoRu37635224', 
'SoRu36096224', 'AkRu05234224', 'HaZa21742224') from visits table
in the water_source table to determine their type of water source*/
Selected_sourceId_sources AS(
SELECT
	source_id,
    type_of_water_source,
    number_of_people_served
FROM
	md_water_services.water_source
WHERE
	source_id IN ('AkKi00881224', 'SoRu37635224', 
'SoRu36096224', 'AkRu05234224', 'HaZa21742224')
),
-- Shared_tap have the highest number of people queuing for water

/*Query to find records where subjective water quality score for home taps is 10,
and where the source was visited a second time*/
Tap_in_home_water_quality AS(
SELECT
	wq.record_id,
    ws.type_of_water_source,
    wq.subjective_quality_score,
    wq.visit_count
FROM
	md_water_services.water_source AS ws
LEFT JOIN 
	visits AS v
    ON
		ws.source_id = v.source_id
LEFT JOIN
	water_quality AS wq
    ON
		wq.record_id = v.record_id
WHERE
	wq.subjective_quality_score = 10
		AND 
			wq.visit_count > 1
		AND
			ws.type_of_water_source LIKE ('tap_in%')
),

/* Query to check well_pollution table if the result is
but biological column is > 0.01*/
Well_pollution_result_issue AS(
SELECT
	source_id,
    description,
    pollutant_ppm,
    biological,
    results
FROM
	well_pollution
WHERE
	results = 'Clean'
    AND
		biological > 0.01
),
/*In some cases, if the description begins with the word 'clean', 
the results have been classified as clean, even if biological is > 0.01*/

-- Query that checks the description column in well pollution table if it has been labelled as clean
Well_pollution_issue_check AS(
SELECT
	*
FROM
	Well_pollution_result_issue
WHERE
	description LIKE '%Clean%'
)
-- 38 wrong description was returned.

-- Query to correct the well pollution description & result column
UPDATE well_pollution
SET description =
	CASE
		WHEN description = 'Clean Bacteria: Giardia Lamblia'
        THEN 'Bacteria: Giardia Lamblia'
        WHEN description = 'Clean Bacteria: E. coli'
        THEN 'Bacteria: E. coli'
        ELSE description
	END,
    results =
	CASE
		WHEN biological > 0.01
        THEN 'Contaminated: Biological'
        ELSE results
        END
-- Query to confirm that the data has been properly updated
SELECT
	source_id,
    description,
    pollutant_ppm,
    biological,
    results
FROM
	well_pollution
WHERE
	description LIKE 'Clean_%'
	OR (results = 'Clean' AND biological > 0.01);

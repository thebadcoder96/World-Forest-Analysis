--Method 1: Using pg_read_file()
DO $$
DECLARE 
	column_definitions TEXT;
BEGIN
WITH header_line as 
    (SELECT pg_read_file('/csv_data/forest_area_km.csv', 0, 185))
SELECT string_agg(
        '"'||column_name||'"' || ' ' || CASE
                WHEN column_name LIKE '%Country%' THEN 'VARCHAR(255)'
                ELSE 'INT'
             END, ', ' 
    ) INTO column_definitions
    FROM unnest(string_to_array(trim(both E'\n' from (SELECT * FROM header_line)), ',')) AS column_name;

EXECUTE 'CREATE TABLE world_forest(' || column_definitions || ');';
END $$;

--Method 2: Using Temp Table 
CREATE TEMP TABLE tmp_table (line TEXT);
COPY tmp_table FROM '/csv_data/forest_area_km.csv' DELIMITER '*' CSV;

DELETE FROM tmp_table
WHERE ctid != (SELECT ctid FROM tmp_table LIMIT 1);

DO $$
DECLARE 
	column_definitions TEXT;
BEGIN
WITH colnames AS (
	SELECT unnest(string_to_array(line, ',')) column_name 
	FROM tmp_table)
SELECT string_agg(
               '"'||column_name||'"' || ' ' || CASE
                   WHEN column_name LIKE '%Country%' THEN 'VARCHAR(255)'
                   ELSE 'FLOAT'
               END, ', ' 
           ) INTO column_definitions
		   FROM colnames;
		   
EXECUTE 'CREATE TABLE world_forest(' || column_definitions || ');';
END $$;


--Load Data
COPY world_forest FROM '/csv_data/forest_area_km.csv' WITH (FORMAT csv, HEADER);

SELECT * FROM world_forest;
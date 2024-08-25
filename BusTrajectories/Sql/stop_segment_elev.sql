-- DROP TABLE IF EXISTS stopsegments;
-- DROP TABLE IF EXISTS vehicletraj;

-- CREATE TABLE stopsegments (
-- 	segment_id VARCHAR(50),
-- 	idx integer,
-- 	latitude FLOAT,
-- 	longitude FLOAT,
-- 	elevation FLOAT,
-- 	point GEOMETRY(Point, 32632)
-- );

-- COPY stopsegments(idx, segment_id, latitude, longitude)
-- FROM '/home/satria/Documents/GenoaData/segments_exploded.csv' DELIMITER  ',' CSV HEADER;

-- UPDATE stopsegments
-- set point =  ST_Transform(ST_SetSRID(ST_Point(longitude, latitude), 4326), 32632);

-- DROP INDEX IF EXISTS idx_stopsegents_composite;
-- DROP INDEX IF EXISTS ix_segment_point;

-- CREATE INDEX idx_stopsegents_composite ON stopsegments(segment_id, idx);
-- CREATE INDEX ix_segment_point
--   ON stopsegments USING gist(point);


-- CREATE TEMP TABLE temp_elevations AS
-- SELECT 
--     s.segment_id,
-- 	s.idx,
--     ST_NearestValue(demelevation.rast, 1, s.point) AS elevation
-- FROM 
--     stopsegments s
-- JOIN 
--     demelevation
-- ON 
--     ST_Intersects(demelevation.rast, s.point);

-- UPDATE stopsegments s
-- SET elevation = te.elevation
-- FROM temp_elevations te
-- WHERE 
--     s.segment_id = te.segment_id
-- 	AND
-- 	s.idx = te.idx;

-- DROP TABLE IF EXISTS temp_elevations;

COPY stopsegments TO '//home/satria/Documents/GenoaData/segments_exploded.csv' WITH (FORMAT CSV, HEADER);
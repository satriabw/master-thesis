-- DROP TABLE IF EXISTS roadsegments;

-- CREATE TABLE roadsegments (
-- 	idx integer,
-- 	segment_id VARCHAR(50),
-- 	longitude FLOAT,
-- 	latitude FLOAT,
-- 	elevation FLOAT,
-- 	point GEOMETRY(Point, 32632)
-- );

-- COPY roadsegments(idx, segment_id, longitude, latitude)
-- FROM '/home/satria/Documents/GenoaData/processed_data/road_segments.csv' DELIMITER  ',' CSV HEADER;

-- UPDATE roadsegments
-- set point =  ST_Transform(ST_SetSRID(ST_Point(longitude, latitude), 4326), 32632);

-- DROP INDEX IF EXISTS idx_roadsegments_composite;
-- DROP INDEX IF EXISTS idx_roadsegments_point;

-- CREATE INDEX idx_roadsegments_composite ON roadsegments(idx, segment_id);
-- CREATE INDEX idx_roadsegments_point
--   ON roadsegments USING gist(point);


-- CREATE TEMP TABLE temp_elevations AS
-- SELECT 
--     rs.segment_id,
-- 	rs.idx,
--     ST_NearestValue(demelevation.rast, 1, rs.point) AS elevation
-- FROM 
--     roadsegments rs
-- JOIN 
--     demelevation
-- ON 
--     ST_Intersects(demelevation.rast, rs.point);

-- UPDATE roadsegments rs
-- SET elevation = te.elevation
-- FROM temp_elevations te
-- WHERE 
--     rs.segment_id = te.segment_id
-- 	AND
-- 	rs.idx = te.idx;

-- DROP TABLE IF EXISTS temp_elevations;

-- COPY roadsegments TO '//home/satria/Documents/GenoaData/processed_data/road_segment_elevation.csv' WITH (FORMAT CSV, HEADER);
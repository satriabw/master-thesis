-- DROP TABLE IF EXISTS vehicletraj;
-- CREATE TABLE vehicletraj(
-- 	Vehicle varchar(50),
-- 	T timestamp,
-- 	Signal varchar(100),
-- 	Value float, 
-- 	lat float,
-- 	lon float,
-- 	Elevation float,
-- 	way_ids Text,
-- 	new_lat float,
-- 	new_lon float,
-- 	matched Boolean,
-- 	segment_id VARCHAR(50),
-- 	trajpoint GEOMETRY(Point, 6875),
-- 	bus_stop_id VARCHAR(50)
-- );

-- SET datestyle = 'ISO, DMY';
-- COPY vehicletraj(Vehicle, T, Signal, Value, lat, lon, way_ids, new_lat, new_lon, matched)
-- FROM '/home/satria/Documents/GenoaData/processed_data/all_points.csv' DELIMITER  ',' CSV HEADER;

-- UPDATE vehicletraj
-- SET trajpoint = ST_Transform(ST_SetSRID(ST_MakePoint(new_lon, new_lat), 4326), 6875);

-- CREATE INDEX idx_vehicletraj_composite ON vehicletraj(vehicle, signal, t);
-- -- Index on vehicletraj coordinates transformed to SRID 6875
-- CREATE INDEX idx_vehicletraj_coords_6875 ON vehicletraj USING GIST (ST_Transform(ST_SetSRID(ST_MakePoint(new_lon, new_lat), 4326), 6875));

-- DROP TABLE IF EXISTS stopsegments;
-- CREATE TABLE stopsegments (
--     segment_id VARCHAR PRIMARY KEY,
-- 	distance_m FLOAT,
-- 	geometry TEXT,
-- 	geom GEOMETRY(LineString, 6875)
-- );

-- -- Step 2: Copy data from the CSV file into the stopsegments table
-- COPY stopsegments (segment_id, distance_m, geometry)
-- FROM '/home/satria/Documents/GenoaData/processed_data/stop_segments.csv'
-- DELIMITER ','
-- CSV HEADER;

-- UPDATE stopsegments
-- SET geom = ST_GeomFromText(geometry, 6875);

-- ALTER TABLE stopsegments
-- DROP COLUMN geometry;

-- SELECT ST_Transform(geom, 4326)
-- from stopsegments

-- -- Ensure spatial index on stopsegments.geom
-- CREATE INDEX idx_stopsegments_geom ON stopsegments USING GIST (geom);

-- Main query
-- WITH limited_vehicletraj AS (
--     SELECT 
--         vehicle,
--         t,
--         trajpoint
--     FROM 
--         vehicletraj
-- 	ORDER BY vehicle, t
-- 	LIMIT 40
-- ),
-- DROP TABLE IF EXISTS ranked_segments_final;
-- WITH closest_segments AS (
--     SELECT 
--         vehicletraj.vehicle, 
--         vehicletraj.t, 
--         stopsegments.segment_id, 
--         stopsegments.geom, 
--         ST_Distance(
--             stopsegments.geom, 
--             vehicletraj.trajpoint
--         ) AS distance
--     FROM 
--         stopsegments,
--         vehicletraj
--     WHERE 
--         ST_DWithin(
--             stopsegments.geom, 
--             vehicletraj.trajpoint, 
--             25
--         )
-- ),
-- ranked_segments AS (
--     SELECT
--         vehicle,
--         t,
--         segment_id,
-- 		distance,
--         ROW_NUMBER() OVER (PARTITION BY vehicle, t ORDER BY distance) AS rank
--     FROM 
--         closest_segments
-- )
-- SELECT 
--     vehicle,
--     t,
--     segment_id
-- INTO TEMP ranked_segments_final
-- FROM 
--     ranked_segments
-- WHERE 
--     rank = 1;

-- UPDATE vehicletraj
-- SET segment_id = rs.segment_id
-- FROM ranked_segments_final rs
-- WHERE vehicletraj.vehicle = rs.vehicle
-- AND vehicletraj.t = rs.t;


-- DROP TABLE IF EXISTS stops;
-- CREATE TABLE stops (
--     stop_id VARCHAR PRIMARY KEY,
-- 	stop_code VARCHAR,
-- 	stop_name TEXT,
-- 	stop_lat FLOAT,
-- 	stop_lon FLOAT,
-- 	geometry TEXT,
-- 	geom GEOMETRY(Point, 6875)
-- );

-- -- Step 2: Copy data from the CSV file into the stopsegments table
-- COPY stops (stop_id, stop_code, stop_name, stop_lat, stop_lon, geometry)
-- FROM '/home/satria/Documents/GenoaData/processed_data/stops.csv'
-- DELIMITER ','
-- CSV HEADER;

-- UPDATE stops
-- SET geom = ST_GeomFromText(geometry, 6875);

-- ALTER TABLE stops
-- DROP COLUMN geometry;

-- SELECT ST_Transform(geom, 4326)
-- from stops

-- Ensure spatial index on stopsegments.geom
-- CREATE INDEX idx_stops_geom ON stops USING GIST (geom);

-- WITH closest_stops AS (
--     SELECT 
--         vt.Vehicle,
--         vt.T,
--         s.stop_id,
--         ST_Distance(vt.trajpoint::geography, s.geom::geography) AS distance
--     FROM 
--         vehicletraj vt
--     JOIN LATERAL (
--         SELECT stop_id, geom 
--         FROM stops 
--         ORDER BY vt.trajpoint <-> stops.geom 
--         LIMIT 1
--     ) s ON TRUE
-- )
-- UPDATE vehicletraj vt
-- SET bus_stop_id = cs.stop_id
-- FROM closest_stops cs
-- WHERE vt.Vehicle = cs.Vehicle AND vt.T = cs.T;

-- COPY vehicletraj TO '//home/satria/Documents/GenoaData/vehicle_with_stop_segment.csv' WITH (FORMAT CSV, HEADER);
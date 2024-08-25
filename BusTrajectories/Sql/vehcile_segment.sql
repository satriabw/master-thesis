WITH closest_segments AS (
    SELECT 
        vehicletraj.vehicle, 
        vehicletraj.t, 
        stopsegments.segment_id, 
        stopsegments.geom, 
        ST_Distance(
            stopsegments.geomgeog::geography, 
            vehicletraj.trajpointgeog::geography
        ) AS distance
    FROM 
        stopsegments,
        vehicletraj
    WHERE 
        ST_DWithin(
            stopsegments.geomgeog::geography, 
            vehicletraj.trajpointgeog::geography, 
            250
        )
),
ranked_segments AS (
    SELECT
        vehicle,
        t,
        segment_id,
		distance,
        ROW_NUMBER() OVER (PARTITION BY vehicle, t ORDER BY distance) AS rank
    FROM 
        closest_segments
)
SELECT 
    vehicle,
    t,
    segment_id
INTO TEMP ranked_segments_final
FROM 
    ranked_segments
WHERE 
    rank = 1;

UPDATE vehicletraj
SET segment_id = rs.segment_id
FROM ranked_segments_final rs
WHERE vehicletraj.vehicle = rs.vehicle
AND vehicletraj.t = rs.t;

COPY vehicletraj TO '//home/satria/Documents/GenoaData/vehicle_with_stop_segment.csv' WITH (FORMAT CSV, HEADER);
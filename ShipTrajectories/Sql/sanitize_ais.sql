DROP TABLE IF EXISTS AISINPUT;
CREATE TABLE AISInput(
  T timestamp,
  TypeOfMobile varchar(100),
  MMSI integer,
  Latitude float,
  Longitude float,
  navigationalStatus varchar(100),
  ROT float,
  SOG float,
  COG float,
  Heading float,
  IMO varchar(100),
  Callsign varchar(100),
  Name varchar(100),
  ShipType varchar(100),
  CargoType varchar(100),
  Width float,
  Length float,
  TypeOfPositionFixingDevice varchar(100),
  Draught float,
  Destination varchar(100),
  ETA varchar(100),
  DataSourceType varchar(100),
  SizeA float,
  SizeB float,
  SizeC float,
  SizeD float,
  Geom geometry(Point, 4326)
);

SET datestyle = 'ISO, DMY';
COPY AISInput(T, TypeOfMobile, MMSI, Latitude, Longitude, NavigationalStatus,
  ROT, SOG, COG, Heading, IMO, CallSign, Name, ShipType, CargoType, Width, Length,
  TypeOfPositionFixingDevice, Draught, Destination, ETA, DataSourceType,
  SizeA, SizeB, SizeC, SizeD, geom)
FROM '/home/satria/Downloads/ship_filtered.csv' DELIMITER  ',' CSV HEADER;


SELECT * FROM AISINPUT;
UPDATE AISInput SET
  NavigationalStatus = CASE NavigationalStatus WHEN 'Unknown value' THEN NULL END,
  IMO = CASE IMO WHEN 'Unknown' THEN NULL END,
  ShipType = CASE ShipType WHEN 'Undefined' THEN NULL END,
  TypeOfPositionFixingDevice = CASE TypeOfPositionFixingDevice
  WHEN 'Undefined' THEN NULL END,
  Geom = ST_SetSRID(ST_MakePoint(Longitude, Latitude), 4326);

DROP TABLE IF EXISTS AISINPUTFILTERED;

CREATE TABLE AISInputFiltered AS
SELECT DISTINCT ON(MMSI, T) *
FROM AISInput
WHERE Longitude BETWEEN -16.1 AND 32.88 AND Latitude BETWEEN 40.18 AND 84.17;

DROP TABLE IF EXISTS AISINPUT;

COPY AISINPUTFILTERED TO '/home/satria/Documents/ais_combined.csv' WITH (FORMAT CSV, HEADER);

DROP TABLE IF EXISTS ships;
CREATE TABLE Ships(MMSI, Trip, SOG, COG, ROT, Heading) AS
SELECT MMSI,
unnest(sequences(tgeompointSeqSetGaps(
     array_agg(tgeompoint(st_transform(geom, 25832), T) ORDER BY T),
     interval '10 mins', 10000))),
tfloatSeq(array_agg(tfloat(SOG, T) ORDER BY T) FILTER (WHERE SOG IS NOT NULL)),
tfloatSeq(array_agg(tfloat(COG, T) ORDER BY T) FILTER (WHERE COG IS NOT NULL)),
tfloatSeq(array_agg(tfloat(ROT, T) ORDER BY T) FILTER (WHERE ROT IS NOT NULL)),
tfloatSeq(array_agg(tfloat(Heading, T) ORDER BY T) FILTER (WHERE Heading IS NOT NULL)),
FROM AISInput
GROUP BY MMSI;

DROP TABLE IF EXISTS AISINPUT;
WITH buckets (bucketNo, RangeKM) AS (
  SELECT 1, floatspan '[0, 0]' UNION
  SELECT 2, floatspan '(0, 50)' UNION
  SELECT 3, floatspan '[50, 100)' UNION
  SELECT 4, floatspan '[100, 200)' UNION
  SELECT 5, floatspan '[200, 500)' UNION
  SELECT 6, floatspan '[500, 1500)' UNION
  SELECT 7, floatspan '[1500, 10000)' ),
histogram AS (
  SELECT bucketNo, RangeKM, count(MMSI) as freq
  FROM buckets left outer join Ships on (length(Trip)/1000) <@ RangeKM
  GROUP BY bucketNo, RangeKM
  ORDER BY bucketNo, RangeKM
)
SELECT bucketNo, RangeKM, freq,
  repeat('▪', ( freq::float / max(freq) OVER () * 30 )::int ) AS bar 
FROM histogram;

DELETE FROM Ships
WHERE length(Trip) = 0 OR length(Trip) >= 1500000;

WITH SpeedDiffs AS (
    SELECT MMSI, ABS(twavg(SOG) * 1.852 - twavg(speed(Trip)) * 3.6) AS SpeedDifference
    FROM Ships
    GROUP BY MMSI, SOG, TRIP
)
DELETE FROM Ships
WHERE MMSI IN (
    SELECT MMSI FROM SpeedDiffs
    WHERE SpeedDifference > 10 OR SpeedDifference IS NULL
);

DROP TABLE IF EXISTS out_ships;
CREATE TABLE out_ships as SELECT mmsi, asewkt(trip), sog, cog, rot, heading from ships; 

COPY out_ships TO '/home/satria/Documents/ships_cleaned.csv' WITH (FORMAT CSV, HEADER);
DROP TABLE IF EXISTS SHIPS;
DROP TABLE IF EXISTS OUT_SHIPS;
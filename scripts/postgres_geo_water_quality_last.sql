CREATE TABLE geo_water_quality_last AS
SELECT wq.mukey, leach_undrain, leach_drain, runoff_undrain, runoff_drain,  mufragvolwt, mup.mupolygonkey ,
slopegraddcp, wtdepannmin, wt_24in_flag, hydgrpdcd, frag_class, geom
FROM projects.saga.water_quality AS wq
INNER JOIN projects.saga.mupolygon AS mup ON mup.mukey = wq.mukey 
INNER JOIN  saga.wq_frags_wt_map_unit2 AS f ON f.mukey=wq.mukey;

ALTER TABLE geo_water_quality_last
ALTER COLUMN geom TYPE geometry(polygon, 4326) USING ST_SetSRID(geom, 4326);

CREATE INDEX geo_water_quality_last_spidx ON  geo_water_quality_last   USING SPGIST (geom);
CREATE INDEX geo_water_quality_last_idx ON  geo_water_quality_last   (leach_undrain, leach_drain, runoff_undrain, runoff_drain);
CREATE  INDEX sda_points_all_logid_idx ON  geo_water_quality_last  (mukey);
CREATE UNIQUE INDEX sda_points_all_logid_idx ON  geo_water_quality_last  (mupolygonkey);
VACUUM ANALYZE geo_water_quality_last  ;

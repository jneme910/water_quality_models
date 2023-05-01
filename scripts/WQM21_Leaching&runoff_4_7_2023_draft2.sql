-- Author: Andrew Paolucci and Jason Nemecek 
--Purpose: Calculate Nutrient Runoff and Leaching Risk for soil map units

-- Leaching Parameters

--hsg = character hydrologic soil group 
--taxorder = character taxonomic order 
--kfact = numeric k factor
--slope = integer percent slope
--coarse_frag = numeric weighted average coarse fragment % through the whole profile
--drained = boolean is there drainage
--wtbl = character kind of water table 
--hwt_lt_24 = boolean high water table less than 24 inch from soil surface

-- Runoff Parameters

--hsg = character hydrologic soil group 
--kfact = numeric k factor
--slope = integer percent slope
--coarse_frag = numeric weighted average coarse fragment % through the whole profile
--drained = boolean is there drainage
--wtbl = character kind of water table 
--hwt_lt_24 = boolean high water table less than 24 inch from soil surface


-- CREATE TEST DATASET 

-- create table with hsg data 
CREATE TABLE hsg_table (
	mukey int,
	hsg varchar(5)
);

INSERT INTO hsg_table (mukey, hsg)
VALUES
(50284, 'B'),
(50285, 'A'),
(50286, 'A/D'),
(50287, 'C'),
(50288, 'D'),
(50289, 'B/D'),
(50290, 'D'),
(50291, 'B');

-- create table with taxorder data
CREATE TABLE taxorder_table (
	mukey int,
	taxorder varchar(25)
);

INSERT INTO taxorder_table (mukey, taxorder)
VALUES
(50284, 'Aridisols'),
(50285, 'Mollisols'),
(50286, 'Spodosols'),
(50287, 'Inceptisols'),
(50288, 'Histosols'),
(50289, 'Entisols'),
(50290, 'Mollisols'),
(50291, 'Mollisols');

-- create table with kfactor data
CREATE TABLE kfactor_table (
	mukey int,
	kfact numeric(3,2)
);

INSERT INTO kfactor_table (mukey, kfact)
VALUES
(50284, 0.24),
(50285, 0.37),
(50286, 0.21),
(50287, 0.42),
(50288, 0.02),
(50289, 0.28),
(50290, 0.32),
(50291, 0.48);

-- create table with slope data
CREATE TABLE slope_table (
	mukey int,
	slope int
);

INSERT INTO slope_table (mukey, slope)
VALUES
(50284, 8),
(50285, 12),
(50286, 15),
(50287, 16),
(50288, 3),
(50289, 1),
(50290, 14),
(50291, 5);

-- create table with coarse frag data
CREATE TABLE coarse_frag_table (
	mukey int,
	coarse_frag numeric(3,1)
);

INSERT INTO coarse_frag_table (mukey, coarse_frag)
VALUES
(50284, 3.7),
(50285, 0),
(50286, 12),
(50287, 6),
(50288, 2),
(50289, 3),
(50290, 7),
(50291, 5);

-- create table with water table type data
CREATE TABLE wtbl_table (
	mukey int,
	wtbl varchar(25)
);

INSERT INTO wtbl_table (mukey, wtbl)
VALUES
(50284, 'None'),
(50285, 'Apparent'),
(50286, 'None'),
(50287, 'None'),
(50288, 'Apparent'),
(50289, 'Perched'),
(50290, 'None'),
(50291, 'Perched');

-- create table with if water table is <24inches data
CREATE TABLE hwt_lt_24 (
	mukey int,
	hwt_lt_24 boolean
);

INSERT INTO hwt_lt_24 (mukey, hwt_lt_24)
VALUES
(50284, FALSE),
(50285, FALSE),
(50286, FALSE),
(50287, FALSE),
(50288, TRUE),
(50289, TRUE),
(50290, TRUE),
(50291, TRUE);


-- JOIN TEST DATASET TABLES INTO NEW TABLE CALLED NUTRIENTMODELS

SELECT t1.mukey, t1.hsg, t2.taxorder, t3.kfact, t4.slope, t5.coarse_frag, t6.wtbl, t7.hwt_lt_24
INTO nutrientmodels
FROM hsg_table t1
		INNER JOIN taxorder_table t2 on (t1.mukey = t2.mukey)
		INNER JOIN kfactor_table t3 on (t1.mukey = t3.mukey)
		INNER JOIN slope_table t4 ON (t1.mukey = t4.mukey)
		INNER JOIN coarse_frag_table t5 ON (t1.mukey = t5.mukey)
		INNER JOIN wtbl_table t6 ON (t1.mukey = t6.mukey)
		INNER JOIN hwt_lt_24 t7 ON (t1.mukey = t7.mukey);

-- CREATE NEW COLUMNS FOR STORING NUTRIENT RISK OUTPUTS
	
ALTER TABLE nutrientmodels
ADD leach_undrain int NULL,
ADD leach_drain int NULL,
ADD runoff_undrain int NULL,
ADD runoff_drain int null;

 -- CALCULATE NUTRIENT LEACHING RISK UNDRAINED
 -- 0 = low 
 -- 1 = moderate
 -- 2 = moderately high
 -- 3 = high 
 
UPDATE nutrientmodels
SET leach_undrain =
CASE
    WHEN taxorder = 'Histosols' THEN 3
    WHEN wtbl = 'Apparent' AND hwt_lt_24 = TRUE THEN 3
    WHEN hsg = 'A' THEN (
	  CASE
		  WHEN slope > 12 THEN (
			CASE
				WHEN coarse_frag > 10 THEN 3
				WHEN coarse_frag <= 10 THEN 2
				ELSE NULL
			END
		  )
		  WHEN slope <= 12 THEN 3
		  ELSE NULL
	  END
	)
	WHEN hsg = 'B' THEN (
	  CASE 
		  WHEN (slope <= 12 AND kfact >= 0.24) OR slope > 12 THEN (
			CASE
				WHEN coarse_frag > 10 AND coarse_frag <= 30 THEN 2
				WHEN coarse_frag > 30 THEN 3
				WHEN coarse_frag <= 10 THEN 1
				ELSE NULL
			END
		  )
		  WHEN slope >= 3 AND slope <= 12 AND kfact < 0.24 THEN (
			CASE 
				WHEN coarse_frag > 10 THEN 3
				WHEN coarse_frag <= 10 THEN 2
				ELSE NULL
				
			END
		  )
		  WHEN slope < 3 AND kfact < 0.24 THEN 3
		  ELSE NULL
	  END
	)
	WHEN hsg = 'C' THEN (
	  CASE
		  WHEN coarse_frag > 30 THEN 3
		  WHEN coarse_frag > 10 AND coarse_frag <= 30 THEN 2
		  WHEN coarse_frag <= 10 THEN 1
		  ELSE NULL
	  END
	)
	WHEN hsg = 'D' OR hsg = 'A/D' OR hsg = 'B/D' OR hsg = 'C/D' THEN (
	  CASE
		  WHEN coarse_frag > 30 THEN 2
		  WHEN coarse_frag > 10 AND coarse_frag <= 30 THEN 1
		  WHEN coarse_frag <= 10 THEN 0
		  ELSE NULL
	  END
	)
	ELSE NULL
END;

 -- CALCULATE NUTRINET LEACHING RISK DRAINED
 -- 0 = low
 -- 1 = moderate
 -- 2 = moderately high
 -- 3 = high
 
UPDATE nutrientmodels 
SET leach_drain =
CASE
    WHEN taxorder = 'Histosols' THEN 3
    WHEN wtbl = 'Apparent' AND hwt_lt_24 = TRUE THEN 3
    WHEN hsg = 'A' OR hsg = 'A/D' THEN (
	  CASE
		  WHEN slope > 12 THEN (
			CASE
				WHEN coarse_frag > 10 THEN 3
				WHEN coarse_frag <= 10 THEN 2
				ELSE NULL
			END
		  )
		  WHEN slope <= 12 THEN 3
		  ELSE NULL
	  END
	)
	WHEN hsg = 'B' OR hsg = 'B/D' THEN (
	  CASE 
		  WHEN (slope <= 12 AND kfact >= 0.24) OR slope > 12 THEN (
			CASE
				WHEN coarse_frag > 10 AND coarse_frag <= 30 THEN 2
				WHEN coarse_frag > 30 THEN 3
				WHEN coarse_frag <= 10 THEN 1
				ELSE NULL
			END
		  )
		  WHEN slope >=3 AND slope <= 12 AND kfact < 0.24 THEN (
			CASE 
				WHEN coarse_frag > 10 THEN 3
				WHEN coarse_frag <= 10 THEN 2
				ELSE NULL	
			END
		  )
		  WHEN slope < 3 AND kfact < 0.24 THEN 3
		  ELSE NULL
	  END
	)
	WHEN hsg = 'C' OR hsg = 'C/D' THEN (
	  CASE
		  WHEN coarse_frag > 30 THEN 3
		  WHEN coarse_frag > 10 AND coarse_frag <= 30 THEN 2
		  WHEN coarse_frag <= 10 THEN 1
		  ELSE NULL
	  END
	)
	WHEN hsg = 'D' THEN (
	  CASE
		  WHEN coarse_frag > 30 THEN 2
		  WHEN coarse_frag > 10 AND coarse_frag <= 30 THEN 1
		  WHEN coarse_frag <= 10 THEN 0
		  ELSE NULL
	  END
	)
	ELSE NULL
END;

-- CALCULATE NUTRIENT RUNOFF RISK UNDRAINED
-- 0 = low
-- 1 = moderate
-- 2 = moderately high
-- 3 = high

UPDATE nutrientmodels 
SET runoff_undrain =
CASE
	WHEN hsg = 'A' THEN 0
	WHEN hsg = 'B' THEN (
		CASE 
			WHEN slope < 4 THEN 0 
			WHEN slope >= 4 AND slope <= 6 THEN (
				CASE
					WHEN kfact < 0.32 THEN 1
					WHEN kfact >= 0.32 THEN 2
					ELSE NULL
				END
			)
			WHEN slope > 6 THEN 3
			ELSE NULL
		END
	)
	WHEN hsg = 'C' THEN (
		CASE
			WHEN slope < 2 THEN 0
			WHEN slope >= 2 AND slope <= 6 THEN (
				CASE
					WHEN kfact < 0.28 THEN 1
					WHEN kfact >= 0.28 THEN 2
					ELSE NULL
				END
			)
			WHEN slope > 6 THEN 3
			ELSE NULL
		END
	)
	WHEN hsg = 'D' OR hsg = 'A/D' OR hsg = 'B/D' OR hsg = 'C/D' THEN (
		CASE
			WHEN hwt_lt_24 = TRUE THEN 3 
			WHEN hwt_lt_24 = FALSE THEN (
				CASE 
					WHEN slope < 2 THEN (
						CASE 
							WHEN kfact < 0.28 THEN 0
							WHEN kfact >= 0.28 THEN 1
							ELSE NULL	
						END
					)
					WHEN slope >= 2 AND slope <= 4 THEN 2
					WHEN slope > 4 THEN 3
					ELSE NULL
				END
			)
			ELSE NULL
		END
	)
	ELSE NULL
END;

-- CALCULATE NUTRIENT RUNOFF RISK DRAINED 
-- 0 = low
-- 1 = moderate
-- 2 = moderately high
-- 3 = high

UPDATE nutrientmodels 
SET runoff_drain =
CASE
	WHEN hsg = 'A' OR hsg = 'A/D' THEN 0
	WHEN hsg = 'B' OR hsg = 'B/D' THEN (
		CASE 
			WHEN slope < 4 THEN 0 
			WHEN slope >= 4 AND slope <= 6 THEN (
				CASE
					WHEN kfact < 0.32 THEN 1
					WHEN kfact >= 0.32 THEN 2
					ELSE NULL
				END
			)
			WHEN slope > 6 THEN 3
			ELSE NULL
		END
	)
	WHEN hsg = 'C' OR hsg = 'C/D' THEN (
		CASE
			WHEN slope < 2 THEN 0
			WHEN slope >= 2 AND slope <= 6 THEN (
				CASE
					WHEN kfact < 0.28 THEN 1
					WHEN kfact >= 0.28 THEN 2
					ELSE NULL
				END
			)
			WHEN slope > 6 THEN 3
			ELSE NULL
		END
	)
	WHEN hsg = 'D' THEN (
		CASE
			WHEN hwt_lt_24 = TRUE THEN 3 
			WHEN hwt_lt_24 = FALSE THEN (
				CASE 
					WHEN slope < 2 THEN (
						CASE 
							WHEN kfact < 0.28 THEN 0
							WHEN kfact >= 0.28 THEN 1
							ELSE NULL	
						END
					)
					WHEN slope > 2 AND slope <= 4 THEN 2
					WHEN slope > 4 THEN 3
					ELSE NULL
				END
			)
			ELSE NULL
		END
	)
	ELSE NULL
END;
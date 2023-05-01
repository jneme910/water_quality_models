--Define the area
DROP TABLE IF EXISTS #main;
DROP TABLE IF EXISTS #main2;
DROP TABLE IF EXISTS #main3;
DROP TABLE IF EXISTS #hz;
DROP TABLE IF EXISTS #hz1;
DROP TABLE IF EXISTS #hz2;

DECLARE @area VARCHAR(20);
DECLARE @area_type INT ;
DECLARE @domc INT ;

DECLARE @major INT ;
DECLARE @operator VARCHAR(5);
-- Soil Data Access

/*
~DeclareChar(@area,20)~  -- Used for Soil Data Access
-~DeclareINT(@area_type)~ 
~DeclareINT(@domc)~ 
~DeclareINT(@major)~ 
~DeclareChar(@operator,20)~ 
*/

-- End soil data access
SELECT @area= 'WI025'; --Enter State Abbreviation or Soil Survey Area i.e. WI or  WI025,  US 
SELECT @domc = 1; -- Enter 0 for dominant component, enter 1 for all components
SELECT @major = 1; -- Enter 0 for major component, enter 1 for all components

SELECT areasymbol, areaname, mapunit.mukey, mapunit.musym, nationalmusym, mapunit.muname, mukind, slopegraddcp, wtdepannmin,
CASE WHEN wtdepannmin <61 THEN 'True'
WHEN wtdepannmin>=61 THEN 'False' END AS wt_24in_flag,
hydgrpdcd
INTO #main
FROM legend
INNER JOIN mapunit on legend.lkey=mapunit.lkey
INNER JOIN muaggatt AS mt1 on mapunit.mukey=mt1.mukey
AND  (CASE WHEN @area_type = 2 THEN LEFT (areasymbol, 2)  ELSE areasymbol END = @area)

SELECT areasymbol, areaname, m2.mukey, m2.musym, nationalmusym, m2.muname, mukind, slopegraddcp, wtdepannmin,wt_24in_flag,hydgrpdcd,comppct_r,
 (SELECT SUM (CCO.comppct_r)
 FROM #main AS mm2
INNER JOIN component AS CCO ON CCO.mukey = mm2.mukey AND M2.mukey = mm2.mukey AND majcompflag = 'Yes' ) AS  major_mu_pct_sum, component.cokey
INTO #main2
FROM #main AS m2
INNER JOIN component ON component.mukey = m2.mukey AND majcompflag = 'Yes'

-- Adjusted compoent percent 
SELECT areasymbol, areaname, mukey, musym, nationalmusym, muname, mukind, slopegraddcp, wtdepannmin,wt_24in_flag,hydgrpdcd,major_mu_pct_sum, comppct_r,
CAST (ROUND ((1.0 * comppct_r / NULLIF(major_mu_pct_sum, 0)),2)AS REAL) AS adj_comp_pct, cokey
INTO #main3
FROM #main2

--Horizon
SELECT areasymbol, areaname, mukey, musym, nationalmusym, muname, mukind, slopegraddcp, wtdepannmin,wt_24in_flag,hydgrpdcd,major_mu_pct_sum, comppct_r,hzdept_r, hzdepb_r , 
CASE WHEN (hzdepb_r-hzdept_r) IS NULL THEN 0 ELSE CAST((hzdepb_r - hzdept_r) AS INT) END AS thickness, hzname, 
(SELECT SUM (fragvol_r) FROM chorizon AS ch1 INNER JOIN chfrags AS chf1 ON ch1.chkey = chf1.chkey AND chorizon.chkey=ch1.chkey AND fragvol_r IS NOT NULL) AS total_frag_r, #main3.cokey
INTO #hz
FROM #main3
INNER JOIN chorizon ON chorizon.cokey = #main3.cokey AND hzname NOT LIKE '%r%'

SELECT areasymbol,
       areaname,
       mukey,
       musym,
       nationalmusym,
       muname,
       mukind,
       slopegraddcp,
       wtdepannmin,
       wt_24in_flag,
       hydgrpdcd,
       major_mu_pct_sum,
       comppct_r,
       hzdept_r,
       hzdepb_r,
       thickness,
       hzname,
       total_frag_r,
	   SUM(thickness) OVER(PARTITION BY cokey) total_thickness,
       cokey
INTO #hz1
FROM #hz
ORDER BY areasymbol ASC, mukey ASC, comppct_r DESC, cokey, hzdept_r ASC


SELECT	areasymbol,
        areaname,
        mukey,
        musym,
        nationalmusym,
        muname,
        mukind,
        slopegraddcp,
        wtdepannmin,
        wt_24in_flag,
        hydgrpdcd,
        major_mu_pct_sum,
        comppct_r,
        hzdept_r,
        hzdepb_r,
        thickness,
        hzname,
        total_frag_r,
        total_thickness,
		CASE WHEN total_frag_r IS NULL THEN 0 
		WHEN  total_thickness IS NULL THEN 0 ELSE   CAST(CAST (total_frag_r AS REAL)/total_thickness AS REAL) END compfragvolwt ,
        cokey
INTO #hz2
FROM #hz1

SELECT areasymbol,
       areaname,
       mukey,
       musym,
       nationalmusym,
       muname,
       mukind,
       slopegraddcp,
       wtdepannmin,
       wt_24in_flag,
       hydgrpdcd,
       major_mu_pct_sum,
       comppct_r,
       hzdept_r,
       hzdepb_r,
       thickness,
       hzname,
       total_frag_r,
       total_thickness,
       compfragvolwt,
       cokey
FROM #hz2




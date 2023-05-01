		DROP TABLE IF EXISTS #main;
        DROP TABLE IF EXISTS #kitchensink;
        DROP TABLE IF EXISTS #comp_temp;
        DROP TABLE IF EXISTS #comp_temp2;
        DROP TABLE IF EXISTS #comp_temp3;
        DROP TABLE IF EXISTS #last_step;
        DROP TABLE IF EXISTS #last_step2;
        DROP TABLE IF EXISTS #temp_main;
		DROP TABLE IF EXISTS #SSURGOOnDemand_wtd_avg_sum_hz_fragvol_r_0_200
        DROP TABLE IF EXISTS #temp_main;

DECLARE @area VARCHAR(20);
DECLARE @area_type INT ;
DECLARE @domc INT ;

DECLARE @major INT ;
DECLARE @operator VARCHAR(5);

SELECT @area= 'WI025'; --Enter State Abbreviation or Soil Survey Area i.e. WI or  WI025,  US 
SELECT @domc = 1; -- Enter 0 for dominant component, enter 1 for all components
SELECT @major = 1; -- Enter 0 for major component, enter 1 for all components

SELECT areasymbol, musym, muname, mukey
INTO #kitchensink
FROM legend  AS lks
INNER JOIN  mapunit AS muks ON muks.lkey = lks.lkey --AND  (CASE WHEN @area_type = 2 THEN LEFT (lks.areasymbol, 2)  ELSE lks.areasymbol END = @area)

SELECT mu1.mukey, cokey, comppct_r, 
SUM (comppct_r) over(partition by mu1.mukey ) AS SUM_COMP_PCT

 
INTO #comp_temp
FROM #kitchensink  AS l1
INNER JOIN  mapunit AS mu1 ON mu1.mukey = l1.mukey
INNER JOIN  component AS c1 ON c1.mukey = mu1.mukey AND majcompflag = 'Yes'


SELECT cokey, SUM_COMP_PCT, CASE WHEN comppct_r = SUM_COMP_PCT THEN 1 
ELSE CAST (CAST (comppct_r AS  decimal (5,2)) / CAST (SUM_COMP_PCT AS decimal (5,2)) AS decimal (5,2)) END AS WEIGHTED_COMP_PCT 
INTO #comp_temp3
FROM #comp_temp



SELECT 
 areasymbol, l.musym, l.muname, mu.mukey/1  AS MUKEY, c.cokey AS COKEY, ch.chkey/1 AS CHKEY, compname, hzname, hzdept_r, hzdepb_r, CASE WHEN hzdept_r <0 THEN 0 ELSE hzdept_r END AS hzdept_r_ADJ, 
CASE WHEN hzdepb_r > 200  THEN 200 ELSE hzdepb_r END AS hzdepb_r_ADJ,
CAST (CASE WHEN hzdepb_r > 200  THEN 200 ELSE hzdepb_r END - CASE WHEN hzdept_r <0 THEN 0 ELSE hzdept_r END AS DECIMAL (5,2)) AS thickness,
comppct_r, 

CAST (SUM (CASE WHEN hzdepb_r > 200  THEN 200 ELSE hzdepb_r END - CASE WHEN hzdept_r <0 THEN 0 ELSE hzdept_r END) OVER(PARTITION BY c.cokey) AS DECIMAL (5,2)) AS sum_thickness, 
(SELECT SUM (fragvol_r) FROM chorizon AS ch1 INNER JOIN chfrags AS chf1 ON ch1.chkey = chf1.chkey AND ch.chkey=ch1.chkey AND fragvol_r IS NOT NULL) AS sum_hz_fragvol_r

--CAST (ISNULL (sum_hz_fragvol_r, 0) AS DECIMAL (5,2))AS sum_hz_fragvol_r
INTO #main
FROM #kitchensink AS l
INNER JOIN  mapunit AS mu ON mu.mukey = l.mukey
INNER JOIN  component AS c ON c.mukey = mu.mukey  
INNER JOIN chorizon AS ch ON ch.cokey=c.cokey AND hzname NOT LIKE '%O%'AND hzname NOT LIKE '%r%'
AND hzdepb_r >0 AND hzdept_r <200
INNER JOIN chtexturegrp AS cht ON ch.chkey=cht.chkey  WHERE cht.rvindicator = 'yes' AND  ch.hzdept_r IS NOT NULL 
AND
texture NOT LIKE '%PM%' AND texture NOT LIKE '%DOM' AND texture NOT LIKE '%MPT%' AND texture NOT LIKE '%MUCK' AND texture NOT LIKE '%PEAT%' AND texture NOT LIKE '%br%' AND texture NOT LIKE '%wb%'
ORDER BY areasymbol, musym, muname, mu.mukey, comppct_r DESC, cokey,  hzdept_r, hzdepb_r



SELECT #main.areasymbol, #main.musym, #main.muname, #main.MUKEY, 
#main.COKEY, #main.CHKEY, #main.compname, hzname, hzdept_r, hzdepb_r, hzdept_r_ADJ, hzdepb_r_ADJ, thickness, sum_thickness, sum_hz_fragvol_r, comppct_r, SUM_COMP_PCT, WEIGHTED_COMP_PCT ,

SUM((thickness/sum_thickness ) * sum_hz_fragvol_r )over(partition by #main.COKEY)AS COMP_WEIGHTED_AVERAGE

INTO #comp_temp2
FROM #main
INNER JOIN #comp_temp3 ON #comp_temp3.cokey=#main.cokey
ORDER BY #main.areasymbol, #main.musym, #main.muname, #main.MUKEY, comppct_r DESC,  #main.COKEY,  hzdept_r, hzdepb_r

SELECT #comp_temp2.MUKEY,#comp_temp2.COKEY, WEIGHTED_COMP_PCT * COMP_WEIGHTED_AVERAGE AS COMP_WEIGHTED_AVERAGE1
INTO #last_step
FROM #comp_temp2 
GROUP BY  #comp_temp2.MUKEY,#comp_temp2.COKEY, WEIGHTED_COMP_PCT, COMP_WEIGHTED_AVERAGE

SELECT areasymbol, musym, muname, 
#kitchensink.mukey, #last_step.COKEY, 
CAST (SUM (COMP_WEIGHTED_AVERAGE1) over(partition by #kitchensink.mukey) as decimal(5,2))AS WEIGHTED_AVERAGE
INTO #last_step2
FROM #last_step
RIGHT OUTER JOIN #kitchensink ON #kitchensink.mukey=#last_step.mukey 
GROUP BY #kitchensink.areasymbol, #kitchensink.musym, #kitchensink.muname, #kitchensink.mukey, COMP_WEIGHTED_AVERAGE1, #last_step.COKEY
ORDER BY #kitchensink.areasymbol, #kitchensink.musym, #kitchensink.muname, #kitchensink.mukey


SELECT --#last_step2.areasymbol, #last_step2.musym, #last_step2.muname, 
#last_step2.mukey, #last_step2.weighted_average AS mufragvolwt, slopegraddcp, wtdepannmin,
CASE WHEN wtdepannmin <61 THEN 'true'
--WHEN wtdepannmin>=61 THEN 'false'
ELSE 'false'
END AS wt_24in_flag,
hydgrpdcd,
CASE WHEN #last_step2.weighted_average > 30  THEN 3
WHEN (#last_step2.weighted_average <= 30 AND WEIGHTED_AVERAGE > 10) THEN 2
WHEN #last_step2.weighted_average <=10 THEN 1 ELSE 1 END AS frag_class


FROM #last_step2
LEFT OUTER JOIN #last_step ON #last_step.mukey=#last_step2.mukey 
INNER JOIN muaggatt ON muaggatt.mukey = #last_step2.mukey 
GROUP BY #last_step2.areasymbol, #last_step2.musym, #last_step2.muname, #last_step2.mukey, #last_step2.WEIGHTED_AVERAGE, slopegraddcp, wtdepannmin,hydgrpdcd
ORDER BY #last_step2.areasymbol, #last_step2.musym, #last_step2.muname, #last_step2.mukey, #last_step2.WEIGHTED_AVERAGE









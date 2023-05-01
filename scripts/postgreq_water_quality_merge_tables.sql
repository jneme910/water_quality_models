DROP TABLE IF EXISTS wq;
DROP TABLE IF EXISTS water_quality;

CREATE TEMP TABLE wq AS 
SELECT   k.mukey , 
k.kwfact AS  kfact  , 
k.taxorder , 
paw.dom_cond_pearched_apparent AS wtbl  , 
COALESCE (wfwmu.mufragvolwt,0) AS coarse_frag, 
wfwmu.slopegraddcp AS slope, 
wfwmu.wt_24in_flag AS hwt_lt_24 , 
wfwmu.hydgrpdcd AS hsg , 
wfwmu.frag_class  
FROM kfactor AS k 
INNER JOIN perched_apparent_wt AS paw ON paw.mukey=k.mukey 
INNER JOIN wq_frags_wt_map_unit2 AS wfwmu ON wfwmu.mukey=k.mukey  ;

CREATE  TABLE water_quality AS 
SELECT mukey,
CASE
    WHEN taxorder = 'Histosols' THEN 3
    WHEN wtbl = 'Apparent' AND hwt_lt_24 = 'TRUE' THEN 3
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
END AS leach_undrain ,
CASE
    WHEN taxorder = 'Histosols' THEN 3
    WHEN wtbl = 'Apparent' AND hwt_lt_24 = 'TRUE' THEN 3
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
END AS leach_drain , 
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
            WHEN hwt_lt_24 = 'TRUE' THEN 3 
            WHEN hwt_lt_24 = 'FALSE' THEN (
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
END AS runoff_undrain, 
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
            WHEN hwt_lt_24 = 'TRUE' THEN 3 
            WHEN hwt_lt_24 =  'FALSE' THEN (
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
END AS runoff_drain
FROM wq


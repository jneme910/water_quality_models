
"nutrient soil leaching potential rating 0-3"

"0=low
1=moderate
2=moderately high
3=high"

"hsg = character hydrologic soil group 
taxorder = character taxonomic order 
kfact = numeric k factor
slope = integer percent slope
coarse_frag = numeric weighted average coarse fragment % through the whole profile
drained = boolean is there drainage
wtbl = character kind of water table 
hwt_It_24 = boolean high water table less than 24 inch from soil surface"

CASE
    WHEN taxorder = "Histosols" THEN 3
    WHEN wtbl = "Apparent" AND hwt_lt_24 = TRUE THEN 3
    WHEN hsg = "A" THEN (
	  CASE
		  WHEN slope > 12 THEN (
			CASE
				WHEN coarse_frag > 10 THEN 3
				ELSE 2
			END
		  )
		  WHEN slope <= 12 THEN 3
		  ELSE NULL
	  END
	)
	WHEN hsg = "B" THEN (
	  CASE 
		  WHEN (slope <= 12 AND kfact >= 0.24) OR slope > 12 THEN (
			CASE
				WHEN coarse_frag > 10 AND coarse_frag <= 30 THEN 2
				WHEN coarse_frag > 30 THEN 3
				ELSE 1
			END
		  )
		  WHEN slope >=3 AND slope <= 12 AND kfact < 0.24 THEN (
			CASE 
				WHEN coarse_frag > 10 THEN 3
				ELSE 2
			END
		  )
		  WHEN slope < 3 AND kfact < 0.24 THEN 3
		  ELSE NULL
	  END
	)
	WHEN hsg = "C" THEN (
	  CASE
		  WHEN coarse_frag > 30 THEN 3
		  WHEN coarse_frag > 10 AND coarse_frag <= 30 THEN 2
		  ELSE 1
	  END
	)
	WHEN hsg = "D" THEN (
	  CASE
		  WHEN coarse_frag > 30 THEN 2
		  WHEN coarse_frag > 10 AND coarse_frag <= 30 THEN 1
		  ELSE 0
	  END
	)
	WHEN hsg = "A/D" THEN (
	  CASE
		  WHEN drained = TRUE THEN (
			CASE
				WHEN coarse_frag > 10 THEN 3
				ELSE 2
			END
		  )
		  ELSE (
			CASE 
				WHEN coarse_frag > 30 THEN 2
				WHEN coarse_frag > 10 AND coarse_frag <= 30 THEN 1
				ELSE 0
			END
		  )
	  END
	)
	WHEN hsg = "B/D" THEN (
	  CASE
		  WHEN drained = TRUE THEN (
			CASE
			WHEN (slope <= 12 AND kfact >= 0.24) OR slope > 12 THEN (
			  CASE
				  WHEN coarse_frag > 10 AND coarse_frag <= 30 THEN 2
				  WHEN coarse_frag > 30 THEN 3
				  ELSE 1
			  END
			)
			WHEN slope >= 3 AND slope <= 12 AND kfact < 0.24 THEN (
			  CASE
				  WHEN coarse_frag > 10 THEN 3
				  ELSE 2
			  END
			)
			WHEN slope <= 3 AND kfact < 0.24 THEN 3
			ELSE NULL
		END
	  )
	  ELSE (
	    CASE
			WHEN coarse_frag > 30 THEN 2
			WHEN coarse_frag > 10 AND coarse_frag <= 30 THEN 1
			ELSE 0
		END
	  )
	  END
	)
	WHEN hsg = "C/D" THEN (
	  CASE
		  WHEN drained = TRUE THEN (
			CASE
				WHEN coarse_frag > 30 THEN 3
				WHEN coarse_frag > 10 AND coarse_frag <= 30 THEN 2
				ELSE 1
			END
		  )
		  ELSE (
			CASE
				WHEN coarse_frag > 30 THEN 2
				WHEN coarse_frag > 10 AND coarse_frag <= 30 THEN 1
				ELSE 0
			END
		  )
	  END
	)
    ELSE NULL
END;
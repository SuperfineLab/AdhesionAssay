# Calculating Plate detachment forces

## Precondition data

- Put forces into the correct units (log10 of force in nN)
- Delete forces that extend below a lower threshold force (gravity force - buoyancy force?, i.e., ~14 pN = 0.014 nN)
- Starting point optimization will depend on the number of modes
    - One mode
        - a = 1
        - am = Force(pct_left = 0.5)
        - as = Force(pct_left = 0.63) - Force(pct_left = 0.37)
    - Two modes
        - a = 0.75
        - am,as,bm,bs
- Fit one mode
- Fit two modes
    - Sort modes, with lower force mode being mode one (regardless of amplitude).
- Choose best fit (one or two)
- Output data should be a one-row table that reports the following:
    - Both fits (fit, gof, opts)
    - Best fit (fit, gof, opts)
    - RawData


# Adhesion Assay TODO (and in-line Notes)

- [x] Re-fit bad curves, based on sum-square error as feedback
  - [x] once the median/mean SSE is discovered through the first set of fits.
  - [x] test criteria for selecting re-fit curves.
    - [x] First, median of SSE + the MAD.

      > - This may be too prone to trigger re-fits.
      > - Results show fairly consistent SSE for at least half of the fits, BUT a significant portion do turn out with lower median SSE when re-fit up to three times.

    - [x] Then, try the median plus 1.5*IQR (probably works better -- fewer outliers)
      > - This seems to be way too INSENSITIVE. Hardly any re-fits are done at all.
      > - Perhaps a middle of the road? IQR/2? MAD*1.5? How do we motivate either of these?
      > - Should rmse be the metric for re-fitting and not sse? **Yes.**

  - [x] Should we normalize SSE by degrees of freedom?

    > - No. Just use RMSE for reporting results rather than SSE.
  
  - [x] Switch the re-fit condition to work based on RMSE instead of SSE.
    - [x] Test this against 400-generation GA fits.
    - [x] Test this against 700-generation GA fits.
    - [x] Test this against 7000-generation GA fits.
  - [x] Decide where/when this re-fit check takes place.

    > - Should it occur at both stages, i.e. both within and between plates of a study? YES.
    > - [x] Make it work on the plate level.
    > - [x] Make it work for the whole study level.
  
  - [x] Do we expect the systematic error of the assay to be constant across plates?

    > - yes, probably, insofar as the error itself changes as a function of the force at which the bead detaches, i.e., plates with higher average detachment forces will have higher error because higher detachment forces harbor higher error inherently. The profile of the error as a function of force should be the same across plates.
  
- [x] Separate functions for force-curve fitting from detachment force computation
  - [ ] Function calls in ba_process_expt should now follow...
    - [x] ba_plate_detachmentforces -> ba_force_curve_fits,
    - [x] THEN ba_improve_bad_fits,
    - [ ] THEN ba_detachmentforces (filter results etc)
  
- [x] Degrade fits to single-mode only for fits with fewer than 7 datapoints (out of necessity) (low dfe)
  - [ ] Degrade fits to single-mode based on obvious error in fit parameters, e.g., astonomically high forces, astronomically large confidence intervals
  - [x] promote parameter sets in tables from a row vector of double values to a cell array containing the row vector of double values (to handle possible fits with differing number of modes).
- [x] Use tiered weighting in lieu of single-valued weights (unweighted)
  - [x] use histcounts to establish which bin weight(i) is in.
  - [x] The resulting set of weights would be either valued based on
    - [x] number of bins, e.g. three bins, 1/3 .* [1 2 3], OR
    - [x] inverted bin number, e.g. three bins, 1./[1 2 3], OR
    - [x] based on quantile bin, such that each bin is quasi-equally sampled across the dataset
- [x] Update code documentation
- [x] Update the ForceBrowser UI to use the new data structures.

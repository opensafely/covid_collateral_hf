*set filepaths
global projectdir `c(pwd)'
di "$projectdir"
global outdir $projectdir/output
di "$outdir"
global tabfigdir $projectdir/output/tabfig
di "$tabfigdir"
global logdir $projectdir/logs
di "$logdir"

* Create directories required 
capture mkdir "$tabfigdir"

*global dataEndDate td(01may2024)

adopath + "$projectdir/analysis/ado"
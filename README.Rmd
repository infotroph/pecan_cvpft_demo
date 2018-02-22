# PEcAn workflow: Test-run BioCro with cultivar-specific PFTs

## Setup

```{r, echo=FALSE,warning=FALSE}
library(PEcAn.all)
library(PEcAn.workflow) # This should be added to PEcAn.all!
```

### Pull branch, build

Get the `cultivars-in-pfts` branch from my PEcAn fork (I probably should have pushed this to a branch in PecanProject before opening the PR...)

```{sh getbranch}
cd $YOUR_PECAN_DIR
git remote add infotroph https://github.com/infotoph/pecan.git
git checkout -b cultivars-in-pfts infotroph/cultivars-in-pfts
make
cd -
```

### Populate PFT table

BETY-0 does already contain cultivar-specific PFTs for switchgrass, but I don't have a BioCro switchgrass configuration handy.
Instead I'll add two new PFTs for the unnamed Miscanthus cultivars '54' and '79'.

*Note:* On my VM at least, very few of the existing Bety observations have a cultivar associated with them, so choosing a cultivar for the demo is harder than it sounds.
Here I've chosen cultivar 54 because it has enough data for a useful meta-analysis, and cultivar 79 as one of several that have *no* data.
This means model runs with PFT `mxg_79` are effectively priors-only, which limits the ecological interest of the output but does demonstrate that the trait lookup correctly ignores data from non-member cultivars.

```{sh pfts}
psql -U bety < cultivar_pft_mxg.sql
```


## Load PEcAn settings file

Rather than store multiple copies of settings.xml, for this demo I'm using a single settings list that I'll edit as I go.

But before editing for PFTs, we need to set a bunch of paths -- The absolute paths in settings.xml probably don't exist on your machine.
BTW, Do I really need to use absolute paths for all of these? I haven't found a way to avoid it, but maybe I missed a memo.

```{r read.settings}
settings <- PEcAn.settings::read.settings("settings.xml")

settings$database$dbfiles <- file.path(normalizePath("."), "dbfiles")
# TODO can I delete model$binary outright and count on bety to fill it in?
settings$model$binary <- system.file("biocro.Rscript", package="PEcAn.BIOCRO")
settings$run$inputs$met$path <- file.path(system.file("tests/testthat/data", package="PEcAn.BIOCRO"), "US-Bo1")
```

OK, NOW I'll edit for each cultivar as I go. Let's run once with the whole-species `Miscanthus_x_giganetus` PFT, and once each with cultivars 54 and 79.

```{r setcultivar}
settings$outdir <- file.path(normalizePath("."), "mxg_species")
settings_mxg <- PEcAn.settings::prepare.settings(settings, force=FALSE)

settings$pfts$pft$name <- "mxg_54"
settings$outdir <- file.path(normalizePath("."), "mxg_54")
settings_54 <- PEcAn.settings::prepare.settings(settings, force=FALSE)

settings$pfts$pft$name <- "mxg_79"
settings$outdir <- file.path(normalizePath("."), "mxg_79")
settings_79 <- PEcAn.settings::prepare.settings(settings, force=FALSE)
```

## Run meta-analysis

```{r meta-analysis}
settings_mxg <- runModule.get.trait.data(settings_mxg)
settings_54 <- runModule.get.trait.data(settings_54)
settings_79 <- runModule.get.trait.data(settings_79)

runModule.run.meta.analysis(settings_mxg)
runModule.run.meta.analysis(settings_54)
runModule.run.meta.analysis(settings_79)
```

Notice that the meta-analysis for `mxg_79` is skipped, as expected for a cultivar with no observations from any of the traits we're analyzing.

If you made it this far without trouble and the reported meta-analyis numbers look sensible, the core cultivar-PFT functionality is working.
Now let's run a model! The rest of this workflow assumes you already have BioCro 0.95 installed and configured.

```{r run.write.configs}
settings_mxg <- runModule.run.write.configs(settings_mxg)
settings_54 <- runModule.run.write.configs(settings_54)
settings_79 <- runModule.run.write.configs(settings_79)
```

```{r run-model}
runModule.start.model.runs(settings_mxg)
runModule.start.model.runs(settings_54)
runModule.start.model.runs(settings_79)
runModule.get.results(settings_mxg)
runModule.get.results(settings_54)
runModule.get.results(settings_79)
```

If this all works, we're ready for ensembles, sensivity analysis and variance decomposition:

```{r model-analysis}
run.sensitivity.analysis(settings_mxg)
run.sensitivity.analysis(settings_54)
run.sensitivity.analysis(settings_79)
run.ensemble.analysis(settings_mxg, plot.timeseries=TRUE)
run.ensemble.analysis(settings_54, plot.timeseries=TRUE)
run.ensemble.analysis(settings_79, plot.timeseries=TRUE)
```

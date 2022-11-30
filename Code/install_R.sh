#!/bin/bash                                                                                                                                                                                                                             

# First run interactive job via "condor_submit -i interactive.sub" to get a command line on a suitable computer.                                                                                                

tar xzf R402.tar.gz
export PATH=$PWD/R/bin:$PATH
export RHOME=$PWD/R
mkdir packages
export R_LIBS=$PWD/packages
packages="c('FITSio', 'dplyr', 'readr', 'stringr', 'tidyverse', 'zoo', 'tseries')"

repository="'https://cran.microsoft.com/'" # cannot use "https" mirror                                                                  
Rscript -e "install.packages(pkgs=$packages, repos=$repository)"
tar -czf packages.tar.gz packages/

exit 0

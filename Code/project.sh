#!/bin/bash                                                                                                                             

tar -xzf R402.tar.gz
tar -xzf packages.tar.gz


export PATH=$PWD/R/bin:$PATH
export RHOME=$PWD/R
export R_LIBS=$PWD/packages

unzip nifty.zip 
# not sure where to unzip -(RLS)

# run your script                                                                                                                       
Rscript project.R $1

#!/bin/bash                                                                                                                             

tar -xzf R402.tar.gz
tar -xzf packages.tar.gz


export PATH=$PWD/R/bin:$PATH
export RHOME=$PWD/R
export R_LIBS=$PWD/packages

unzip nifty.zip

# run your script                                                                                                                       
Rscript Example_RProcess.R $1

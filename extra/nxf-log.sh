#!/bin/bash

module load nextflow
nextflow log -f workdir,exit,duration,name "$@"

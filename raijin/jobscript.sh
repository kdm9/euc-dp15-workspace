#!/bin/bash
# properties = {properties}

source /g/data1/xe2/.profile

set -ueo pipefail

module load snakemake adapterremoval nextgenmap

{exec_job}

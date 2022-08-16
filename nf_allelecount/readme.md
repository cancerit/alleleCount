# Generic NextFlow wrapper for alleleCount

A very simple nextflow wrapper for alleleCount. Runs alleleCount v4.3.0 in a singularity container located at `docker://quay.io/wtsicgp/allelecount:v4.3.0`.

### Requirements

- nextflow (tested with v21.10.6-5660)

- sylabs singularity (tested with v3.5.3)


### Usage

`nextflow run allelecount.nf`

Pass inputs and options to alleleCount via `user_args.config`. Also includes relevant runtime options for singularity.

See alleleCount documentation for further information


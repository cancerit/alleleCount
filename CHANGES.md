# CHANGES

## v4.2.0

* Updated to hstlib 1.11

## v4.1.0

* Created Docker file and build scripts to generate a containeraized code

## v4.0.2

* Added checking of iterator error codes when calling sam_itr_next

## v4.0.1

### Behaviour change

**When the proper pair filter flag is used, this code now checks that the paired-end orientation is also used.**
**This will mean that mate-pair orientation (F/F or R/R) will be rejected**

* Where a proper pair filter is used, now check for the correct paired-end orientation of F/R.
* If this is not met the read is ignored.

## v4.0.0

* alleleCounter now counts **_per-fragment_** rather than per-read when overlaps occur.
* Reworked perl to wrap C alleleCounter and just handle the extra format changes.
* No dep on Bio::DB::HTS now.
* Update to HTSlib 1.7
* Merged #43, providing 10X processing mode.

## v3.3.1

* Fix setup.sh bug skipping samtools install

## v3.3.0

* Added -d commandline option. It triggers 'dense' mode. Best used where there
* are many SNPs for example AscatNGS and Battenberg allelecount steps
* Added -f commandline option. Flag value of reads to retain in allele counting
* Added -F commandline option. Flag value of reads to exclude in allele counting

## v3.1.0

* Adds filter and keep flags commandline options for read filtering
* Adds dense SNP option
* Change install of Bio::DB::HTS to use fixed version of htslib and Bio::DB::HTS

## v3.0.0

* Removes dependancy on legacy versions of samtools in perl code.
* Upgrades to more recent version of htslib not requiring patch.

## v2.2.0

* Added contig filter commandline option

## v2.1.0

* Added version info to makefile and option to display to alleleCount C code.
* Fixed bug in c code where region wasn't malloc-ing enough for the contig name.

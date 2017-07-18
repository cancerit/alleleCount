### v3.1.0
* Adds filter and keep flags commandline options for read filtering
* Adds dense SNP option
* Change install of Bio::DB::HTS to use fixed version of htslib and Bio::DB::HTS

### v3.0.0
* Removes dependancy on legacy versions of samtools in perl code.
* Upgrades to more recent version of htslib not requiring patch.

### v2.2.0
* Added contig filter commandline option

### v2.1.0
* Added version info to makefile and option to display to alleleCount C code.
* Fixed bug in c code where region wasn't malloc-ing enough for the contig name.

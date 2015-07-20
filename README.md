alleleCount
===========

The alleleCount package primarily exists to prevent code duplication between some other projects,
specifically AscatNGS and Battenburg.

All that this contains is a perl program to calculate the allele fraction for locations provided in
an input file.

The C version of bam_stats supports both BAM and CRAM input.

---

###Dependencies/Install
Some of the code included in this package has dependencies on several C packages:

* [samtools v0.1.20](https://github.com/samtools), via [Bio::DB::Sam](http://search.cpan.org/~lds/Bio-SamTools/)
* [htslib](https://github.com/samtools/htslib)

And various utility perl modules.

(samtools is only required for legacy perl version of bam_stats.pl and will be removed at a later date).

Once complete please run:

    ./setup.sh /some/install/location

Please be aware that this expects basic C compilation libraries and tools to be available,
most are listed in `INSTALL`.

---

##Creating a release
####Preparation
* Commit/push all relevant changes.
* Pull a clean version of the repo and use this for the following steps.

####Cutting the release
1. Update `lib/Sanger/CGP/AlleleCount.pm` to the correct version (adding rc/beta to end if applicable).
2. Update `c/Makefile` to contain the correct version.
3. Update `Changes` to show major items.
4. Run `./prerelease.sh`
5. Check all tests and coverage reports are acceptable.
6. Commit the updated docs tree and updated module/version.
7. Push commits.
8. Use the GitHub tools to draft a release.

LICENCE
=======

Copyright (c) 2014,2015 Genome Research Ltd.

Author: CancerIT <cgpit@sanger.ac.uk>

This file is part of alleleCount.

alleleCount is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation; either version 3 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

1. The usage of a range of years within a copyright statement contained within
this distribution should be interpreted as being equivalent to a list of years
including the first and last year specified and all consecutive years between
them. For example, a copyright statement that reads ‘Copyright (c) 2005, 2007-
2009, 2011-2012’ should be interpreted as being identical to a statement that
reads ‘Copyright (c) 2005, 2007, 2008, 2009, 2011, 2012’ and a copyright
statement that reads ‘Copyright (c) 2005-2012’ should be interpreted as being
identical to a statement that reads ‘Copyright (c) 2005, 2006, 2007, 2008,
2009, 2010, 2011, 2012’."

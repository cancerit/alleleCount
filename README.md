LICENCE
=======

Copyright (c) 2014 Genome Research Ltd.

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


alleleCount
===========

The alleleCount package primarily exists to prevent code duplication between some other projects,
specifically AscatNGS and Battenburg.

All that this contains is a perl program to calculate the allele fraction for locations provided in
an input file.

---

###Dependencies/Install
Some of the code included in this package has dependencies on several C packages:

* [samtools](https://github.com/samtools), via [Bio::DB::Sam](http://search.cpan.org/~lds/Bio-SamTools/)

And various utility perl modules.

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
2. Update `Changes` to show major items.
3. Run `./prerelease.sh`
4. Check all tests and coverage reports are acceptable.
5. Commit the updated docs tree and updated module/version.
6. Push commits.
7. Use the GitHub tools to draft a release.

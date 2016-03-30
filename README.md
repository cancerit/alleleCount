alleleCount
===========

The alleleCount package primarily exists to prevent code duplication between some other projects,
specifically AscatNGS and Battenburg.

The project contains 2 equivalent implementations of allele counting code in perl and C for BAM/CRAM processing.

## Loci File

The input for both tools is a simple tab formatted file of chromosome and 1-based positions, e.g.

```
<CHR><TAB><POS1>
<CHR><TAB><POS2>
<CHR><TAB><POS3>
...
```

The file doesn't need to be in any particular order (although disk reads are likely to be more efficient when sorted).

---

###Dependencies/Install

Some of the code included in this package has dependencies:

* [samtools v1.2+](https://github.com/samtools/samtools)
* [htslib](https://github.com/samtools/htslib)
* [Bio::DB::HTS](http://search.cpan.org/~rishidev/Bio-DB-HTS/)

And various utility perl modules.

These are all installed for you by running:

    ./setup.sh /some/install/location

Please be aware that this expects basic C compilation libraries and tools to be available.

---

##Creating a release
####Preparation
* Commit/push all relevant changes.
* Pull a clean version of the repo and use this for the following steps.

####Cutting the release
1. Update `lib/Sanger/CGP/AlleleCount.pm` to the correct version.
2. Update `CHANGES.md` to show major items.
3. Run `./prerelease.sh`
4. Check all tests and coverage reports are acceptable.
5. Commit the updated docs tree and updated module/version.
6. Push commits.
7. Use the GitHub tools to draft a release.

LICENCE
=======

Copyright (c) 2014-2016 Genome Research Ltd.

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

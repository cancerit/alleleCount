# alleleCount

The alleleCount package primarily exists to prevent code duplication between some other projects,
specifically AscatNGS and Battenberg.

| Master | Dev |
|---|---|
| [![Build Status](https://travis-ci.org/cancerit/alleleCount.svg?branch=master)](https://travis-ci.org/cancerit/alleleCount) | [![Build Status](https://travis-ci.org/cancerit/alleleCount.svg?branch=dev)](https://travis-ci.org/cancerit/alleleCount) |

The project previously contained 2 equivalent implementations of allele counting code in perl and C
for BAM/CRAM processing.  As of v4 the perl code wraps the C implementation in order to preserve the
ability to use alleleCounter for those still using the perl implementation whilst using the speed of
the C implementation without loosing the additional features it provides.

## Usage

Assuming you have added the installation location to your path:

### C version

Accepts locai file as described below only and generates a tsv output of allele counts.

For parameters please see the command line help:

```
alleleCounter --help
```

Please note use of the long form parameter names with values requires '=', e.g. `--min-base-qual=10`.

### Perl version

The perl version has additional options for alternative typs of input/output.

```
alleleCounter.pl --help
```

## Loci files

### Generic loci File

The base input for both tools is a simple tab formatted file of chromosome and 1-based positions, e.g.

```
<CHR><tab><POS1>
...
```

If using the `--dense-snps` mode (C only) please ensure the file is sorted via:

```
sort -k1,1 -n 2,2n loci_unsrt.tsv > losi_sorted.tsv
```

### SNP6 loci file (perl only)

```
<CHR><tab><POS1><tab><REF_ALL><tab><ID><tab><ALLELE_A><tab><ALLELE_B>
...
```

Output file is different.

---

### Dependencies/Install

Some of the code included in this package has dependencies:

* [htslib](https://github.com/samtools/htslib)

And various utility perl modules.

These are all installed for you by running:

    ./setup.sh /some/install/location

Please be aware that this expects basic C compilation libraries and tools to be available.

---

## Creating a release

### Preparation

* Commit/push all relevant changes.
* Pull a clean version of the repo and use this for the following steps.

### Cutting the release

1. Update `lib/Sanger/CGP/AlleleCount.pm` to the correct version.
2. Update `CHANGES.md` to show major items.
3. Run `./prerelease.sh`
4. Check all tests and coverage reports are acceptable.
5. Commit the updated docs tree and updated module/version.
6. Push commits.
7. Use the GitHub tools to draft a release.

## LICENCE

```
Copyright (c) 2014-2018 Genome Research Ltd.

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
```

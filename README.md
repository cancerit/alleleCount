# alleleCount

The alleleCount package primarily exists to prevent code duplication between some other projects,
specifically AscatNGS and Battenberg.

[![Quay Badge][quay-status]][quay-repo]

| Master                                        | Develop                                         |
| --------------------------------------------- | ----------------------------------------------- |
| [![Master Badge][travis-master]][travis-base] | [![Develop Badge][travis-develop]][travis-base] |

The project previously contained 2 equivalent implementations of allele counting code in perl and C
for BAM/CRAM processing.  As of v4 the perl code wraps the C implementation in order to preserve the
ability to use alleleCounter for those still using the perl implementation whilst using the speed of
the C implementation without loosing the additional features it provides.

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Usage](#usage)
	- [C version](#c-version)
	- [Perl version](#perl-version)
- [Loci files](#loci-files)
	- [Generic loci File](#generic-loci-file)
	- [SNP6 loci file (perl only)](#snp6-loci-file-perl-only)
	- [Dependencies/Install](#dependenciesinstall)
- [Docker, Singularity and Dockstore](#docker-singularity-and-dockstore)
- [Creating a release](#creating-a-release)
	- [Preparation](#preparation)
	- [Cutting the release](#cutting-the-release)
- [LICENCE](#licence)

<!-- /TOC -->

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

The perl version has additional options for alternative types of input/output.

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

### Dependencies/Install

Some of the code included in this package has dependencies:

* [htslib](https://github.com/samtools/htslib)

And various utility perl modules.

These are all installed for you by running:

    ./setup.sh /some/install/location

Please be aware that this expects basic C compilation libraries and tools to be available.

## Docker, Singularity and Dockstore

There is a pre-built image containing this codebase on quay.io.

* [dockstore-cgpwgs][ds-cgpwgs-git]: Contains additional tools for WGS analysis.

This was primarily designed for use with dockstore.org but can be used as normal containers.

The docker images are know to work correctly after import into a singularity image.

## Creating a release

### Preparation

* Commit/push all relevant changes.
* Pull a clean version of the repo and use this for the following steps.

### Cutting the release

1. Update `lib/Sanger/CGP/AlleleCount.pm` to the correct version.
1. Update `CHANGES.md` to show major items.
1. Run `./prerelease.sh`
1. Check all tests and coverage reports are acceptable.
1. Commit the updated docs tree and updated module/version.
1. Push commits.
1. Use the GitHub tools to draft a release.

## LICENCE

```
Copyright (c) 2014-2018 Genome Research Ltd.

Author: CASM/Cancer IT <cgphelp@sanger.ac.uk>

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

<!-- Travis -->
[travis-base]: https://travis-ci.org/cancerit/alleleCount
[travis-master]: https://travis-ci.org/cancerit/alleleCount.svg?branch=master
[travis-develop]: https://travis-ci.org/cancerit/alleleCount.svg?branch=dev

<!-- refs -->
[ds-cgpwgs-git]: https://github.com/cancerit/dockstore-cgpwgs

<!-- Quay.io -->
[quay-status]: https://quay.io/repository/wtsicgp/allelecount/status
[quay-repo]: https://quay.io/repository/wtsicgp/allelecount
[quay-builds]: https://quay.io/repository/wtsicgp/allelecount?tab=builds

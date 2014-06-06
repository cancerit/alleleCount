#!/bin/bash

##########LICENCE##########
# Copyright (c) 2014 Genome Research Ltd.
#
# Author: CancerIT <cgpit@sanger.ac.uk>
#
# This file is part of alleleCount.
#
# alleleCount is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
##########LICENCE##########

set -eu # exit on first error or undefined value in subtitution

# get current directory
INIT_DIR=`pwd`

rm -rf blib

# get location of this file
MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized
if [ -z "$MY_PATH" ] ; then
  # error; for some reason, the path is not accessible
  # to the script (e.g. permissions re-evaled after suid)
  echo Failed to determine location of script >2
  exit 1  # fail
fi
# change into the location of the script
cd $MY_PATH

echo '### Running perl tests ###'

export HARNESS_PERL_SWITCHES=-MDevel::Cover=-db,perl/reports,-ignore,'t/.*\.t'
rm -rf perl/docs
mkdir -p perl/docs/reports_text
prove --nocolor -I perl/lib perl/t| sed 's/^/  /' # indent output of prove
if [[ $? -ne 0 ]] ; then
  echo "\n\tERROR: TESTS FAILED\n"
  exit 1
fi

echo '### Generating test/pod coverage reports ###'
# removed 'condition' from coverage as '||' 'or' doesn't work properly
cover -coverage branch,subroutine,pod -report_c0 50 -report_c1 85 -report_c2 100 -report html_basic perl/reports -silent > /dev/null
cover -coverage branch,subroutine,pod -report text perl/reports -silent > perl/docs/reports_text/coverage.txt
rm -rf perl/reports/structure perl/reports/digests perl/reports/cover.13 perl/reports/runs
cp perl/reports/coverage.html perl/reports/index.html
mv perl/reports perl/docs/reports_html
unset HARNESS_PERL_SWITCHES

echo '### Generating POD ###'
mkdir -p perl/docs/pod_html
perl -MPod::Simple::HTMLBatch -e 'Pod::Simple::HTMLBatch::go' perl/lib:perl/bin perl/docs/pod_html > /dev/null

echo '### Archiving docs folder ###'
tar cz -C $INIT_DIR/perl -f perl/docs.tar.gz docs

# generate manifest, and cleanup
echo '### Generating MANIFEST ###'
# delete incase any files are moved, the make target just adds stuff
rm -f MANIFEST
# cleanup things which could break the manifest
rm -rf install_tmp
perl Makefile.PL > /dev/null
make manifest &> /dev/null
rm -f Makefile MANIFEST.bak pm_to_blib

# change back to original dir
cd $INIT_DIR

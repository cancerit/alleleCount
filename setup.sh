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


SOURCE_SAMTOOLS="https://github.com/samtools/samtools/archive/0.1.20.tar.gz"

done_message () {
    if [ $? -eq 0 ]; then
        echo " done."
        if [ "x$1" != "x" ]; then
            echo $1
        fi
    else
        echo " failed.  See setup.log file for error messages." $2
        echo "    Please check INSTALL file for items that should be installed by a package manager"
        exit 1
    fi
}

get_distro () {
  EXT=""
  DECOMP="gunzip -f"
  if [[ $2 == *.tar.bz2* ]] ; then
    EXT="tar.bz2"
    DECOMP="bzip2 -fd"
  elif [[ $2 == *.tar.gz* ]] ; then
    EXT="tar.gz"
  else
    echo "I don't understand the file type for $1"
    exit 1
  fi
  if hash curl 2>/dev/null; then
    curl -sS -o $1.$EXT -L $2
  else
    wget -nv -O $1.$EXT $2
  fi
  mkdir -p $1
  `$DECOMP $1.$EXT`
  tar --strip-components 1 -C $1 -xf $1.tar
}

if [ "$#" -ne "1" ] ; then
  echo "Please provide an installation path  such as /opt/pancan"
  exit 0
fi

INST_PATH=$1

CPU=`grep -c ^processor /proc/cpuinfo`
if [ $? -eq 0 ]; then
  if [ "$CPU" -gt "6" ]; then
    CPU=6
  fi
else
  CPU=1
fi
echo "Max compilation CPUs set to $CPU"

# get current directory
INIT_DIR=`pwd`

# re-initialise log file
echo > $INIT_DIR/setup.log

# log information about this system
(
    echo '============== System information ===='
    set -x
    lsb_release -a
    uname -a
    sw_vers
    system_profiler
    grep MemTotal /proc/meminfo
    set +x
    echo; echo
) >>$INIT_DIR/setup.log 2>&1

# cleanup inst_path
mkdir -p $INST_PATH/bin
cd $INST_PATH
INST_PATH=`pwd`
cd $INIT_DIR

# make sure that build is self contained
unset PERL5LIB
ARCHNAME=`perl -e 'use Config; print $Config{archname};'`
PERLROOT=$INST_PATH/lib/perl5
PERLARCH=$PERLROOT/$ARCHNAME
export PERL5LIB="$PERLROOT:$PERLARCH"

#create a location to build dependencies
SETUP_DIR=$INIT_DIR/install_tmp
mkdir -p $SETUP_DIR

cd $SETUP_DIR

echo -n "Building samtools ..."
if [ -e "$SETUP_DIR/samtools.success" ]; then
  echo -n " previously installed ...";
else
  cd $SETUP_DIR
  (
    set -x
    if [ ! -e $SETUP_DIR/samtools ]; then
      get_distro "samtools" $SOURCE_SAMTOOLS
      perl -i -pe 's/^CFLAGS=\s*/CFLAGS=-fPIC / unless /\b-fPIC\b/' samtools/Makefile
    fi
    make -C samtools -j$CPU
    set +x
    cp $SETUP_DIR/samtools/samtools $INST_PATH/bin/.
    touch $SETUP_DIR/samtools.success
  )>>$INIT_DIR/setup.log 2>&1
fi
done_message "" "Failed to build samtools."

export SAMTOOLS="$SETUP_DIR/samtools"

if [ ! -e "$INST_PATH/bin/alleleCounter" ] ; then
  echo -n "Building alleleCounter ..."
  if [ -e "$SETUP_DIR/alleleCounter.success" ]; then
    echo -n " previously installed ...";
  else
    cd $INIT_DIR
    (
      set -xe
      mkdir -p $INIT_DIR/c/bin
      make -C c -j$CPU
      cp $INIT_DIR/c/bin/alleleCounter $INST_PATH/bin/.
      make -C c clean
      touch $SETUP_DIR/alleleCounter.success
    )>>$INIT_DIR/setup.log 2>&1
  fi
  done_message "" "Failed to build alleleCounter."
else
  echo "alleleCounter - already installed"
fi


#add bin path for install tests
export PATH="$INST_PATH/bin:$PATH"

cd $INIT_DIR/perl

echo -n "Installing Perl prerequisites ..."
if ! ( perl -MExtUtils::MakeMaker -e 1 >/dev/null 2>&1); then
    echo
    echo "WARNING: Your Perl installation does not seem to include a complete set of core modules.  Attempting to cope with this, but if installation fails please make sure that at least ExtUtils::MakeMaker is installed.  For most users, the best way to do this is to use your system's package manager: apt, yum, fink, homebrew, or similar."
fi
(
  set -x
  $INIT_DIR/perl/bin/cpanm -v --mirror http://cpan.metacpan.org --notest -l $INST_PATH/ --installdeps $INIT_DIR/perl/. < /dev/null
  set +x
) >>$INIT_DIR/setup.log 2>&1
done_message "" "Failed during installation of core dependencies."

echo -n "Installing alleleCount ..."
(
  cd $INIT_DIR/perl
  perl Makefile.PL INSTALL_BASE=$INST_PATH
  make
  make test
  make install
) >>$INIT_DIR/setup.log 2>&1
done_message "" "alleleCount install failed."

# cleanup all junk
rm -rf $SETUP_DIR

echo
echo
echo "Please add the following to beginning of path:"
echo "  $INST_PATH/bin"
echo "Please add the following to beginning of PERL5LIB:"
echo "  $PERLROOT"
echo

exit 0

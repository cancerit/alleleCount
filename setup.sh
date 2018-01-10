#!/bin/bash

##########LICENCE##########
# Copyright (c) 2014-2018 Genome Research Ltd.
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

SOURCE_SAMTOOLS="https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2"
SOURCE_HTSLIB="https://github.com/samtools/htslib/releases/download/1.3.2/htslib-1.3.2.tar.bz2"

EXP_SAMV="1.3.1"

version_gt () {
  test $(printf '%s\n' $@ | sort -V | head -n 1) == "$1";
}

get_distro () {
  EXT=""
  DECOMP=""
  if [[ $2 == *.tar.bz2* ]] ; then
    EXT="tar.bz2"
    DECOMP="-j"
  elif [[ $2 == *.tar.gz* ]] ; then
    EXT="tar.gz"
    DECOMP="-z"
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
  tar --strip-components 1 -C $1 $DECOMP -xf $1.$EXT
}

get_file () {
# output, source
  if hash curl 2>/dev/null; then
    curl -sS -o $1 -L $2
  else
    wget -nv -O $1 $2
  fi
}

if [[ ($# -ne 1 && $# -ne 2) ]] ; then
  echo "Please provide an installation path and optionally perl lib paths to allow, e.g."
  echo "  ./setup.sh /opt/myBundle"
  echo "OR all elements versioned:"
  echo "  ./setup.sh /opt/cgpVcf-X.X.X /opt/PCAP-X.X.X/lib/perl"
  exit 0
fi

INST_PATH=$1

if [[ $# -eq 2 ]] ; then
  CGP_PERLLIBS=$2
fi


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

set -e

# cleanup inst_path
mkdir -p $INST_PATH/bin
cd $INST_PATH
INST_PATH=`pwd`
cd $INIT_DIR

# make sure that build is self contained
unset PERL5LIB
PERLROOT=$INST_PATH/lib/perl5

# allows user to knowingly specify other PERL5LIB areas.
if [ -z ${CGP_PERLLIBS+x} ]; then
  export PERL5LIB="$PERLROOT"
else
  export PERL5LIB="$PERLROOT:$CGP_PERLLIBS"
fi

export PATH=$INST_PATH/bin:$PATH

#create a location to build dependencies
SETUP_DIR=$INIT_DIR/install_tmp
mkdir -p $SETUP_DIR

## grab cpanm and stick in workspace, then do a self upgrade into bin:
get_file $SETUP_DIR/cpanm https://cpanmin.us/
perl $SETUP_DIR/cpanm -l $INST_PATH App::cpanminus
CPANM=`which cpanm`

if [ -e $SETUP_DIR/basePerlDeps.success ]; then
  echo "Previously installed base perl deps..."
else
  perlmods=( "ExtUtils::CBuilder" "Module::Build~0.42" "Const::Fast" "File::Which" "LWP::UserAgent")
  for i in "${perlmods[@]}" ; do
    $CPANM --no-interactive --notest --mirror http://cpan.metacpan.org -l $INST_PATH $i
  done
  touch $SETUP_DIR/basePerlDeps.success
fi

cd $SETUP_DIR

if [ -e $SETUP_DIR/htslibGet.success ]; then
  echo " already staged ...";
else
  echo
  cd $SETUP_DIR
  get_distro "htslib" $SOURCE_HTSLIB
  touch $SETUP_DIR/htslibGet.success
fi

echo -n "Building htslib ..."
if [ -e $SETUP_DIR/htslib.success ]; then
  echo " previously installed ...";
else
  echo
  mkdir -p htslib
  tar --strip-components 1 -C htslib -jxf htslib.tar.bz2
  cd htslib
  ./configure --enable-plugins --enable-libcurl --prefix=$INST_PATH
  make -j$CPU
  make install
  cd $SETUP_DIR
  touch $SETUP_DIR/htslib.success
fi

export HTSLIB=$INST_PATH

SAMV=`samtools --version | grep samtools | cut -d ' ' -f 2`

if [[ "x$SAMV" == "x" ]] ; then
  echo -n "Building samtools ..."
  if [ -e $SETUP_DIR/samtools.success ]; then
    echo " previously installed ...";
  else
  echo
    cd $SETUP_DIR
    rm -rf samtools
    get_distro "samtools" $SOURCE_SAMTOOLS
    mkdir -p samtools
    tar --strip-components 1 -C samtools -xjf samtools.tar.bz2
    cd samtools
    ./configure --enable-plugins --enable-libcurl --prefix=$INST_PATH
    make -j$CPU all all-htslib
    make install all all-htslib
    cd $SETUP_DIR
    rm -f samtools.tar.bz2
    touch $SETUP_DIR/samtools.success
  fi
else
  if version_gt $SAMV $EXP_SAMV; then
    echo "  samtools version is good ($SAMV)"
    touch $SETUP_DIR/samtools.success
  else
    echo -n "Building samtools ..."
    if [ -e $SETUP_DIR/samtools.success ]; then
      echo " previously installed ...";
    else
    echo
      cd $SETUP_DIR
      rm -rf samtools
      get_distro "samtools" $SOURCE_SAMTOOLS
      mkdir -p samtools
      tar --strip-components 1 -C samtools -xjf samtools.tar.bz2
      cd samtools
      ./configure --enable-plugins --enable-libcurl --prefix=$INST_PATH
      make -j$CPU all all-htslib
      make install all all-htslib
      cd $SETUP_DIR
      rm -f samtools.tar.bz2
      touch $SETUP_DIR/samtools.success
    fi
  fi
fi

export HTSLIB="$SETUP_DIR/htslib"

echo -n "Building alleleCounter ..."
if [ -e "$SETUP_DIR/alleleCounter.success" ]; then
  echo " previously installed ...";
else
  cd $INIT_DIR
  mkdir -p $INIT_DIR/c/bin
  make -C c clean
  make -C c -j$CPU
  cp $INIT_DIR/c/bin/alleleCounter $INST_PATH/bin/.
  touch $SETUP_DIR/alleleCounter.success
fi

cd $INIT_DIR/perl

echo -n "Installing Perl prerequisites ..."
if ! ( perl -MExtUtils::MakeMaker -e 1 >/dev/null 2>&1); then
    echo
    echo "WARNING: Your Perl installation does not seem to include a complete set of core modules.  Attempting to cope with this, but if installation fails please make sure that at least ExtUtils::MakeMaker is installed.  For most users, the best way to do this is to use your system's package manager: apt, yum, fink, homebrew, or similar."
fi
$CPANM --no-interactive --notest --mirror http://cpan.metacpan.org -l $INST_PATH/ --installdeps $INIT_DIR/perl/. < /dev/null

echo -n "Installing alleleCount ..."
cd $INIT_DIR/perl
perl Makefile.PL INSTALL_BASE=$INST_PATH
make
make test
make install

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

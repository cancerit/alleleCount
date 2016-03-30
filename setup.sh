#!/bin/bash

##########LICENCE##########
# Copyright (c) 2014-2016 Genome Research Ltd.
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


SOURCE_SAMTOOLS="https://github.com/samtools/samtools/releases/download/1.3/samtools-1.3.tar.bz2"
SOURCE_HTSLIB="https://github.com/samtools/htslib/archive/1.3.tar.gz"
BIODBHTS_INSTALL="https://raw.githubusercontent.com/Ensembl/Bio-HTS/master/INSTALL.pl"

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
echo $CPANM

cd $SETUP_DIR

echo -n "Building samtools ..."
if [ -e "$SETUP_DIR/samtools.success" ]; then
  echo -n " previously installed ...";
else
  cd $SETUP_DIR &&
  get_distro "samtools" $SOURCE_SAMTOOLS &&
  cd samtools &&
  ./configure --enable-plugins --enable-libcurl --prefix=$INST_PATH &&
  make all all-htslib &&
  make install install-htslib &&
  touch $SETUP_DIR/samtools.success
fi
done_message "" "Failed to build samtools."

export SAMTOOLS="$SETUP_DIR/samtools"

echo -n "Building htslib ..."
if [ -e $SETUP_DIR/htslib.success ]; then
  echo -n " previously installed ...";
else
  cd $SETUP_DIR &&
  get_distro "htslib" $SOURCE_HTSLIB &&
  make -C htslib -j$CPU &&
  touch $SETUP_DIR/htslib.success
fi
done_message "" "Failed to build htslib."

export HTSLIB="$SETUP_DIR/htslib"

echo -n "Building alleleCounter ..."
if [ -e "$SETUP_DIR/alleleCounter.success" ]; then
  echo -n " previously installed ...";
else
  cd $INIT_DIR &&
  mkdir -p $INIT_DIR/c/bin &&
  make -C c -j$CPU &&
  cp $INIT_DIR/c/bin/alleleCounter $INST_PATH/bin/. &&
  make -C c clean &&
  touch $SETUP_DIR/alleleCounter.success
fi
done_message "" "Failed to build alleleCounter."

echo -n "Building Bio::DB::HTS ..."
if [ -e $SETUP_DIR/biohts.success ]; then
  echo -n " previously installed ...";
else
  cd $SETUP_DIR &&
  $CPANM --mirror http://cpan.metacpan.org --notest -l $INST_PATH Module::Build Bio::Perl &&
  # now Bio::DB::HTS
  get_file "INSTALL.pl" $BIODBHTS_INSTALL &&
  perl -I $PERL5LIB INSTALL.pl --prefix $INST_PATH --static &&
  rm -f BioDbHTS_INSTALL.pl &&
  touch $SETUP_DIR/biohts.success
fi


#add bin path for install tests
export PATH="$INST_PATH/bin:$PATH"

cd $INIT_DIR/perl

echo -n "Installing Perl prerequisites ..."
if ! ( perl -MExtUtils::MakeMaker -e 1 >/dev/null 2>&1); then
    echo
    echo "WARNING: Your Perl installation does not seem to include a complete set of core modules.  Attempting to cope with this, but if installation fails please make sure that at least ExtUtils::MakeMaker is installed.  For most users, the best way to do this is to use your system's package manager: apt, yum, fink, homebrew, or similar."
fi
$CPANM --mirror http://cpan.metacpan.org --notest -l $INST_PATH/ --installdeps $INIT_DIR/perl/. < /dev/null
done_message "" "Failed during installation of core dependencies."

echo -n "Installing alleleCount ..."
cd $INIT_DIR/perl &&
perl Makefile.PL INSTALL_BASE=$INST_PATH &&
make &&
make test &&
make install
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

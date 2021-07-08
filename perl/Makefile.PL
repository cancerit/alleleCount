#!/usr/bin/perl

##########LICENCE##########
# Copyright (c) 2014-2020 Genome Research Ltd.
#
# Author: CASM/Cancer IT <cgphelp@sanger.ac.uk>
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


use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'alleleCount',
  LICENSE       => 'agpl_3', # http://search.cpan.org/~dagolden/CPAN-Meta-2.142690/lib/CPAN/Meta/Spec.pm#license
  VERSION_FROM  => 'lib/Sanger/CGP/AlleleCount.pm',
  EXE_FILES     => [qw( bin/alleleCounter.pl bin/alleleCounterToJson.pl )],
  PREREQ_PM     => {
                     'Const::Fast' => 0.014,
                     'Try::Tiny' => 0.19,
                     'File::Slurp' => 9999.19,
                     'File::Which' => 0.05,
                     'Test::Fatal' => 0.013,
                     'Devel::Cover' => 1.09,
                     'Pod::Coverage' => 0.23,
                     'IPC::System::Simple' => 1.25,
                   }
);

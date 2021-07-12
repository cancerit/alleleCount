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

use strict;
use Test::More;
use Test::Fatal;
use Const::Fast qw(const);
use File::Temp qw(tempdir);
use File::Slurp;

use Sanger::CGP::AlleleCount::ToJson;


const my $MOD => 'Sanger::CGP::AlleleCount::ToJson';
const my $EXP_JSON  => '{"rs2369898":"CT"}';

const my @DEFAULT_RESULT => ( ['#CHR',qw(POS Count_A Count_C Count_G Count_T Good_depth)],
                              [qw(22 16165776 1 12 0 0 13)]
                              );
const my @PBQ20_RESULT => ( ['#CHR',qw(POS Count_A Count_C Count_G Count_T Good_depth)],
                            [qw(22 16165776 2 17 0 0 19)]
                              );

const my @MAPQ0_RESULT => ( ['#CHR',qw(POS Count_A Count_C Count_G Count_T Good_depth)],
                            [qw(22 16165776 1 17 0 0 18)]
                              );

const my @DEFAULT_RESULT_SNP6 => (['#CHR',qw(POS Count_Allele_A Count_Allele_B Good_depth)],
                                  [qw(22 16165776 12 1 13)]
                                  );
const my @PBQ20_RESULT_SNP6 => (['#CHR',qw(POS Count_Allele_A Count_Allele_B Good_depth)],
                                  [qw(22 16165776 17 2 19)]
                                  );
const my @MAPQ0_RESULT_SNP6 => (['#CHR',qw(POS Count_Allele_A Count_Allele_B Good_depth)],
                                  [qw(22 16165776 17 1 18)]
                                  );

use FindBin qw($Bin);
my $data_root = "$Bin/../../testData";

my $loci = "$data_root/test_loci.txt";
my $ac_output = "$data_root/test_ac_out.txt";

my $obj = new_ok($MOD); # no options

is($EXP_JSON, Sanger::CGP::AlleleCount::ToJson::alleleCountToJson($ac_output, $loci), "Check conversion to JSON"); 

done_testing();


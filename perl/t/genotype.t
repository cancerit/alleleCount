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

use strict;
use Test::More;
use Const::Fast qw(const);

use Sanger::CGP::AlleleCount::Genotype;

const my $MOD => 'Sanger::CGP::AlleleCount::Genotype';
const my @DEFAULT_RESULT => ( ['#CHR',qw(POS Count_A Count_C Count_G Count_T Good_depth)],
                              [qw(22 16165776 1 12 0 0 13)]
                              );
const my @PBQ20_RESULT => ( ['#CHR',qw(POS Count_A Count_C Count_G Count_T Good_depth)],
                            [qw(22 16165776 2 17 0 0 19)]
                              );

const my @MAPQ0_RESULT => ( ['#CHR',qw(POS Count_A Count_C Count_G Count_T Good_depth)],
                            [qw(22 16165776 1 17 0 0 18)]
                              );

use FindBin qw($Bin);
my $data_root = "$Bin/../../testData";

my $bam = "$data_root/test.bam";
my $cram = "$data_root/test.cram";
my $loci = "$data_root/loci_22.txt";


my $obj = new_ok($MOD); # no options
$obj = new_ok($MOD, [{'species' => 'HUMAN', 'build' => '37'}]);


my $buffer = "";
my $fh;

open $fh, '>', \$buffer or die $!;
is(1, $obj->get_full_loci_profile($bam, $fh, $loci), "Check execution of loci profile (BAM)");
close $fh;
is_deeply(tsv_to_data($buffer), \@DEFAULT_RESULT, "Expected result for defaults (BAM)");

# test with default result for C version (-m=20 (bpq))
$buffer = "";
open $fh, '>', \$buffer or die $!;
is(1, $obj->get_full_loci_profile($bam, $fh, $loci, 20), "Check execution of loci profile (BAM, pbq=20)");
close $fh;
is_deeply(tsv_to_data($buffer), \@PBQ20_RESULT, "Expected result for defaults (BAM, pbq=20)");

# test with mapq=1
$buffer = "";
open $fh, '>', \$buffer or die $!;
is(1, $obj->get_full_loci_profile($bam, $fh, $loci, undef, 1), "Check execution of loci profile (BAM, mapq=1)");
close $fh;
is_deeply(tsv_to_data($buffer), \@MAPQ0_RESULT, "Expected result for defaults (BAM, mapq=1)");

### !!! The test cram file has the reference embedded so works fine without fasta !!! ###
$buffer = "";
open $fh, '>', \$buffer or die $!;
is(1, $obj->get_full_loci_profile($cram, $fh, $loci), "Check execution of loci profile (CRAM)");
close $fh;
is_deeply(tsv_to_data($buffer), \@DEFAULT_RESULT, "Expected result for defaults (CRAM)");

# test with default result for C version (-m=20 (bpq))
$buffer = "";
open $fh, '>', \$buffer or die $!;
is(1, $obj->get_full_loci_profile($cram, $fh, $loci, 20), "Check execution of loci profile (CRAM, pbq=20)");
close $fh;
is_deeply(tsv_to_data($buffer), \@PBQ20_RESULT, "Expected result for defaults (CRAM, pbq=20)");

# test with mapq=1
$buffer = "";
open $fh, '>', \$buffer or die $!;
is(1, $obj->get_full_loci_profile($cram, $fh, $loci, undef, 1), "Check execution of loci profile (CRAM, mapq=1)");
close $fh;
is_deeply(tsv_to_data($buffer), \@MAPQ0_RESULT, "Expected result for defaults (CRAM, mapq=1)");

done_testing();

sub tsv_to_data {
  my ($data) = @_;
  my @tmp = split /\n/, $data;
  my @ret;
  for(@tmp) {
    push @ret, [split /\t/, $_];
  }
  return \@ret;
}

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
use Test::Fatal;
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

my $bam = "$data_root/test.bam";
my $cram = "$data_root/test.cram";
my $loci = "$data_root/loci_22.txt";
my $bad_loci = "$data_root/loci_22_bad.txt";
my $snp6_loci = "$data_root/loci_snp6.txt";


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

## do again with SNP6

$buffer = "";
open $fh, '>', \$buffer or die $!;
is(1, $obj->get_full_snp6_profile($bam, $fh, $snp6_loci), "Check execution of snp6 loci profile (BAM)");
close $fh;
is_deeply(tsv_to_data($buffer), \@DEFAULT_RESULT_SNP6, "Expected result for defaults (BAM)");

# test with default result for C version (-m=20 (bpq))
$buffer = "";
open $fh, '>', \$buffer or die $!;
is(1, $obj->get_full_snp6_profile($bam, $fh, $snp6_loci, 20), "Check execution of snp6 loci profile (BAM, pbq=20)");
close $fh;
is_deeply(tsv_to_data($buffer), \@PBQ20_RESULT_SNP6, "Expected result for defaults (BAM, pbq=20)");

# test with mapq=1
$buffer = "";
open $fh, '>', \$buffer or die $!;
is(1, $obj->get_full_snp6_profile($bam, $fh, $snp6_loci, undef, 1), "Check execution of snp6 loci profile (BAM, mapq=1)");
close $fh;
is_deeply(tsv_to_data($buffer), \@MAPQ0_RESULT_SNP6, "Expected result for defaults (BAM, mapq=1)");


# check fails with expected error message when seq not found in BAM
$buffer = "";
open $fh, '>', \$buffer or die $!;
like(
    exception { $obj->get_full_loci_profile($bam, $fh, $bad_loci); },
    qr/Chromosome '[^']+' at line [[:digit:]]+ in .+ cannot be found in .+[.]bam/,
    "Catch loci file with unknown sequences vs. BAM header",
  );
close $fh;

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

## do again with SNP6

$buffer = "";
open $fh, '>', \$buffer or die $!;
is(1, $obj->get_full_snp6_profile($cram, $fh, $snp6_loci), "Check execution of snp6 loci profile (CRAM)");
close $fh;
is_deeply(tsv_to_data($buffer), \@DEFAULT_RESULT_SNP6, "Expected result for defaults (CRAM)");

# test with default result for C version (-m=20 (bpq))
$buffer = "";
open $fh, '>', \$buffer or die $!;
is(1, $obj->get_full_snp6_profile($cram, $fh, $snp6_loci, 20), "Check execution of snp6 loci profile (CRAM, pbq=20)");
close $fh;
is_deeply(tsv_to_data($buffer), \@PBQ20_RESULT_SNP6, "Expected result for defaults (CRAM, pbq=20)");

# test with mapq=1
$buffer = "";
open $fh, '>', \$buffer or die $!;
is(1, $obj->get_full_snp6_profile($cram, $fh, $snp6_loci, undef, 1), "Check execution of snp6 loci profile (CRAM, mapq=1)");
close $fh;
is_deeply(tsv_to_data($buffer), \@MAPQ0_RESULT_SNP6, "Expected result for defaults (CRAM, mapq=1)");

# check fails with expected error message when seq not found in CRAM
$buffer = "";
open $fh, '>', \$buffer or die $!;
like(
    exception { $obj->get_full_loci_profile($cram, $fh, $bad_loci); },
    qr/Chromosome '[^']+' at line [[:digit:]]+ in .+ cannot be found in .+[.]cram/,
    "Catch loci file with unknown sequences vs. CRAM header",
  );
close $fh;

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

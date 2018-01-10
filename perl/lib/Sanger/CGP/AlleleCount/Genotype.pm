package Sanger::CGP::AlleleCount::Genotype;

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

use strict;

use Carp;
use English qw( -no_match_vars );
use warnings FATAL => 'all';

use FindBin qw($Bin);
use File::Which qw(which);
use File::Temp qw(tempdir);

use Sanger::CGP::AlleleCount;

use Const::Fast qw(const);

const my $MIN_MAPQ => 35;
const my $MIN_PBQ => 30;
const my $FLAG_REQ => 2;
const my $FLAG_FILT => 4+8+256+512+1024+2048; # 3852

=item new

Null constructor

=cut

sub new {
  my ($class) = @_;
  my $self = { };
  bless $self, $class;
  return $self;
}

=item configure

Set up the object for the current analysis.

  $genotype->configure('my.bam', $min_pbq, $min_mapq [, $fasta])

=cut

sub configure {
  my ($self, $bam_file, $min_pbq, $min_mapq, $fasta) = @_;
  $self->{'$fasta'} = $fasta if(defined $fasta);
  $self->{'min_pbq'} = $min_pbq // $MIN_PBQ;
  $self->{'min_mapq'} = $min_mapq // $MIN_MAPQ;
}

=item _wrap_c_alleleCounter

Generic function to generate allele counts from a chr\tpos\n formatted file (1-based)
by calling the C version.

Calling function should provided an intermediate path for the output if data needs reformatting for
SNP6 style loci input files.

=cut

sub _wrap_c_alleleCounter {
  my ($self, $hts_file, $out_file, $clean_loci) = @_;
  my $command = sprintf _alleleCounter_c().
                        ' --loci-file=%s'.
                        ' --hts-file=%s'.
                        ' --output-file=%s'.
                        ' --min-base-qual=%d'.
                        ' --min-map-qual=%d'.
                        ' --required-flag=%d'.
                        ' --filtered-flag=%d',
                        ($clean_loci, $hts_file, $out_file,
                         $self->{'min_pbq'}, $self->{'min_mapq'},
                         $FLAG_REQ, $FLAG_FILT);
  if(defined $self->{'$fasta'}) {
      $command .= ' --ref-file='.$self->{'$fasta'};
  }
  if($ENV{ALLELE_C_SILENT}) { #  only used for test harness
      $command .= ' >& /dev/null'
  }
  system($command) && die $!;
  return;
}

=item get_full_snp6_profile

Writes tab seperated allelic counts and depth to specified FH
Uses all snps defined in file used by ngs_cn (format slightly different)

=cut
sub get_full_snp6_profile {
  my ($self, $bam_file, $out_file, $loci_file, $min_pbq, $min_mapq, $fasta) = @_;
  $self->configure($bam_file, $min_pbq, $min_mapq, $fasta);

  my %stored;
  # process the original loci file
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $tmp_loci = $tmpdir.'/loci_tmp.out';
  my $tmp_out = $tmpdir.'/out_tmp.out';
  open my $N_LOC, '>', $tmp_loci or croak "Unable to open $tmp_loci for writing: $OS_ERROR\n";
  open my $SNP6, '<', $loci_file or croak "Unable to open $loci_file for reading: $OS_ERROR\n";
  while(my $line = <$SNP6>) {
    chomp $line;
    my ($chr, $pos, undef, undef, $allA, $allB) = split /\s/, $line;
    $stored{"$chr:$pos:A"} = uc $allA;
    $stored{"$chr:$pos:B"} = uc $allB;
    printf $N_LOC "%s\t%d\n", $chr, $pos;
  }
  close $N_LOC;
  close $SNP6;

  _wrap_c_alleleCounter($self, $bam_file, $tmp_out, $tmp_loci);

  open my $cfh, '<', $tmp_out or croak "Unable to open $loci_file for reading: $OS_ERROR\n";
  open my $ofh, '>', $out_file or croak "Unable to open $out_file for writing: $OS_ERROR\n";
  # header
  print $ofh "#CHR\tPOS\tCount_Allele_A\tCount_Allele_B\tGood_depth\n" or croak "Failed to write line: $OS_ERROR\n";

  while(my $line = <$cfh>) {
    next if($line =~ m/^#/);
    chomp $line;
    my ($chr, $pos, $c_a, $c_c, $c_g, $c_t, $depth) = split /\t/, $line;
    my %tmp = ('A', $c_a, 'C', $c_c, 'G', $c_g, 'T', $c_t);
    printf $ofh "%s\t%d\t%d\t%d\t%d\n", $chr,
                                        $pos,
                                        $tmp{$stored{"$chr:$pos:A"}},
                                        $tmp{$stored{"$chr:$pos:B"}},
                                        $depth;
  }
  close $cfh;
  close $ofh;
  return 1;
}

=item get_full_loci_profile

Writes tab seperated allelic counts and depth to specified FH
Uses all loci defined in specified file

=cut
sub get_full_loci_profile {
  my ($self, $bam_file, $out_file, $loci_file, $min_pbq, $min_mapq, $fasta) = @_;
  $self->configure($bam_file, $min_pbq, $min_mapq, $fasta);
  _wrap_c_alleleCounter($self, $bam_file, $out_file, $loci_file);
  return 1;
}

=item gender_chk

Writes the chromosome name for the Male sex chromosome as defined by loci file and 'Y/N'
indicating presence of any of the SNPs.  E.g.

  chrX  Y

or

  X  N

=cut
sub gender_chk {
  my ($self, $bam_file, $out_file, $loci_file, $min_pbq, $min_mapq, $fasta) = @_;
  $self->configure($bam_file, $min_pbq, $min_mapq, $fasta);
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $tmp_out = $tmpdir.'/gender_chk.out';
  _wrap_c_alleleCounter($self, $bam_file, $tmp_out, $loci_file);

  my $sex_chr;
  my $is_male = 'N';
  open my $fh, '<', $tmp_out or croak 'Unable to open '.$tmp_out.' for reading';
  while(my $line = <$fh>) {
    next if($line =~ /^#/);
    chomp $line;
    my ($chr, $pos, $depth) = (split /\t/, $line)[0,1,-1];
    if(defined $sex_chr) {
      die "Only loci expected on the 'male' sex chromosome should be included in: $loci_file\n\tYou have $sex_chr & $chr so far!\n" if($chr ne $sex_chr);
    }
    else {
      $sex_chr = $chr;
    }
    if($depth > 5) {
      $is_male = 'Y';
      # technically we could stop here, but we should check all the chrs to make sure this isn't the wrong LOCI file
    }
  }
  close $fh;

  open my $ofh, '>', $out_file or croak 'Unable to open '.$out_file.' for writing';
  printf $ofh "%s\t%s\n", $sex_chr, $is_male;
  close $ofh;
  return;
}

sub _alleleCounter_c {
  my $l_bin = $Bin.'/../../c/bin';
  my $prog = 'alleleCounter';
  my $path = File::Spec->catfile($l_bin, $prog);
  $path = which($prog) unless(-e $path);
  die "Failed to find alleleCounter in path or local bin folder ($l_bin)\n\tPATH: $ENV{PATH}\n" unless(defined $path && -e $path);
  return $path;
}

1;

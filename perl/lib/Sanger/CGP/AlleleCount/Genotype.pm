package Sanger::CGP::AlleleCount::Genotype;

##########LICENCE##########
# Copyright (c) 2014,2015 Genome Research Ltd.
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

use Sanger::CGP::AlleleCount;
use Sanger::CGP::AlleleCount::PileupData;

use Bio::DB::HTS;
use Bio::DB::HTS::AlignWrapper;

use Const::Fast qw(const);

const my $MAX_PILEUP_DEPTH => 1_000_000;
const my $MIN_MAPQ => 35;
const my $MIN_PBQ => 30;
const my $TAB => "\t";
const my $NL => "\n";

my $g_pu_data; # required for pileup;
my $g_pb_qual;
my $g_map_qual;
my $g_sam;
my $this_pos;

sub new {
  my ($class, $opts) = @_;
  my $self = { };
  bless $self, $class;
  if(defined $opts) {
    $self->{'species'} = $opts->{'species'};
    $self->{'build'} = $opts->{'build'};
  }
  return $self;
}

sub configure {
  my ($self, $bam_file, $min_pbq, $min_mapq, $fasta) = @_;
  $self->{'_min_pbq'} = $min_pbq || $MIN_PBQ;
  $self->{'_min_mapq'} = $min_mapq || $MIN_MAPQ;
  my $sam = Bio::DB::HTS->new(-bam => $bam_file, -fasta=> $fasta);
  $sam->max_pileup_cnt($MAX_PILEUP_DEPTH);
  $self->{'_sam'} = $sam;
}

=item get_full_snp6_profile

Writes tab seperated allelic counts and depth to specified FH
Uses all snps defined in file used by ngs_cn (format slightly different)

=cut
sub get_full_snp6_profile {
  my ($self, $fh) = @_;
  $g_pb_qual = $self->{'_min_pbq'};
  $g_map_qual = $self->{'_min_mapq'};
  $g_sam = $self->{'_sam'};
  my $snp6_file = $self->ngs_cn_snps({'species'=>'HUMAN','build'=>37});
  my ($region, $chr, $pos, $allA, $allB);
  print $fh "#CHR\tPOS\tCount_Allele_A\tCount_Allele_B\tGood_depth\n" or croak "Failed to write line: $OS_ERROR\n";
  open my $SNP6, '<', $snp6_file or croak "Unable to open $snp6_file for reading: $OS_ERROR\n";
  while(my $line = <$SNP6>) {
    chomp $line;
    ($chr, $pos, undef, undef, $allA, $allB) = split /\s/, $line;
    $g_pu_data = Sanger::CGP::AlleleCount::PileupData->new($chr, $pos, $allA, $allB);
    $this_pos = $pos;
    $region = $chr.':'.$pos.'-'.$pos;
    $g_sam->fast_pileup($region, \&allele_counts_callback);
    print $fh $g_pu_data->chr,$TAB,$g_pu_data->pos,$TAB,$g_pu_data->count_A,$TAB,$g_pu_data->count_B,$TAB,$g_pu_data->depth,$NL or croak "Failed to write line: $OS_ERROR\n";
  }
  close $SNP6;
  return 1;
}

=item get_full_loci_profile

Writes tab seperated allelic counts and depth to specified FH
Uses all loci defined in specified file

=cut
sub get_full_loci_profile {
  my ($self, $fh, $loci_file) = @_;
  $g_pb_qual = $self->{'_min_pbq'};
  $g_map_qual = $self->{'_min_mapq'};
  $g_sam = $self->{'_sam'};
  my ($region, $chr, $pos, $allA, $allB);
  print $fh "#CHR\tPOS\tCount_A\tCount_C\tCount_G\tCount_T\tGood_depth\n" or croak "Failed to write line: $OS_ERROR\n";
  open my $LOCI, '<', $loci_file or croak 'Unable to open '.$loci_file.' for reading';
  while(my $line = <$LOCI>) {
    chomp $line;
    ($chr, $pos) = split /\s/, $line;
    $g_pu_data = Sanger::CGP::AlleleCount::PileupData->new($chr, $pos);
    $this_pos = $pos;
    $region = $chr.':'.$pos.'-'.$pos;
    $g_sam->fast_pileup($region, \&allele_counts_callback);
    print $fh $chr or croak "Failed to write line: $OS_ERROR\n";
    print $fh $TAB,$pos or croak "Failed to write line: $OS_ERROR\n";
    print $fh $TAB,$g_pu_data->residue_count('A') or croak "Failed to write line: $OS_ERROR\n";
    print $fh $TAB,$g_pu_data->residue_count('C') or croak "Failed to write line: $OS_ERROR\n";
    print $fh $TAB,$g_pu_data->residue_count('G') or croak "Failed to write line: $OS_ERROR\n";
    print $fh $TAB,$g_pu_data->residue_count('T') or croak "Failed to write line: $OS_ERROR\n";
    print $fh $TAB,$g_pu_data->depth,$NL or croak "Failed to write line: $OS_ERROR\n";
  }
  close $LOCI;
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
  my ($self, $fh, $loci_file) = @_;
  $g_pb_qual = $self->{'_min_pbq'};
  $g_map_qual = $self->{'_min_mapq'};
  $g_sam = $self->{'_sam'};
  my $sex_chr;
  my $is_male = 'N';
  my ($region, $chr, $pos, $allA, $allB);
  open my $LOCI, '<', $loci_file or croak 'Unable to open '.$loci_file.' for reading';
  while(my $line = <$LOCI>) {
    chomp $line;
    ($chr, $pos) = split /\s/, $line;
    if(defined $sex_chr) {
      die "Only loci expected on the 'male' sex chromosome should be included in: $loci_file\n\tYou have $sex_chr & $chr so far!\n" if($chr ne $sex_chr);
    }
    else {
      $sex_chr = $chr;
    }
    $g_pu_data = Sanger::CGP::AlleleCount::PileupData->new($chr, $pos);
    $this_pos = $pos;
    $region = $chr.':'.$pos.'-'.$pos;
    $g_sam->fast_pileup($region, \&allele_counts_callback);
    if($g_pu_data->depth > 5) {
      $is_male = 'Y';
      # technically we could stop here, but we should check all the chrs to make sure this isn't the wrong LOCI file
    }
  }
  close $LOCI;
  printf $fh "%s\t%s\n", $sex_chr, $is_male;
}

sub allele_counts_callback {
  my ($seqid, $pos, $pu) = @_;
  return if($pos != $this_pos);
  foreach my $p (@{$pu}) {

    next if($p->is_del || $p->is_refskip);
    my $a = $p->alignment;

    my $flagValue = $a->flag;

    next if(($flagValue & 4)); #Unmapped read
    next if(($flagValue & 8)); #Mate unmapped read
    next if(!($flagValue & 2)); #Not a proper pair
    next if(($flagValue & 1024)); #PCR/Optical duplicate
    next if(($flagValue & 256)); #Not primary alignment
    next if(($flagValue & 512)); #Fails vendor checks
    next if(($flagValue & 2048)); #Supp. alignment
		next if($a->qual < $g_map_qual); # check mapping quality

		my $qpos = $p->qpos;
    if($g_pb_qual){
    	next if ((unpack('C*',$a->_qscore))[$qpos] < $g_pb_qual);
    }

    # get the base at this pos
    my $qbase  = substr($a->qseq, $qpos, 1);
    $g_pu_data->register_allele($qbase);
  }
  return 1;
}




1;

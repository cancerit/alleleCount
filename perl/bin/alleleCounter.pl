#!/usr/bin/perl

##########LICENCE##########
# Copyright (c) 2014,2015 Genome Research Ltd.
#
# Author:  CancerIT <cgpit@sanger.ac.uk>
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

BEGIN {
  use Cwd qw(abs_path);
  use File::Basename;
  unshift (@INC,dirname(abs_path($0)).'/../lib');
};

use strict;
use Data::Dumper;
use Carp;
use English qw( -no_match_vars );
use warnings FATAL => 'all';

use Getopt::Long 'GetOptions';
use Pod::Usage;
use Const::Fast qw(const);

use Sanger::CGP::AlleleCount::Genotype;

const my $MIN_MAPQ => 35;
const my $MIN_PBQ => 30; # needs to correlate with Illumina bins

{
  my $options = option_builder();
  my $FH = *STDOUT;
  open $FH, '>', $options->{'o'} or croak 'Failed to create '.$options->{'o'} if(defined $options->{'o'});
  run($FH, $options);
  close $FH if(defined $options->{'o'});
}

sub run {
  my ($FH, $options) = @_;
  my $geno_ob = Sanger::CGP::AlleleCount::Genotype->new();
  if($options->{'g'}) {
    $geno_ob->gender_chk($options->{'b'}, $FH, $options->{'l'}, $options->{'m'}, $options->{'q'}, $options->{'r'});
  }
  elsif($options->{'s'}) {
    $geno_ob->get_full_snp6_profile($options->{'b'}, $FH, $options->{'l'}, $options->{'m'}, $options->{'q'}, $options->{'r'});
  }
  else {
    $geno_ob->get_full_loci_profile($options->{'b'}, $FH, $options->{'l'}, $options->{'m'}, $options->{'q'}, $options->{'r'});
  }
}

sub option_builder {
	my ($factory) = @_;

	my %opts;

	&GetOptions (
		'h|help'    => \$opts{'h'},
		'b|bam=s' => \$opts{'b'},
		'o|output=s' => \$opts{'o'},
		'l|locus=s' => \$opts{'l'},
		'g|gender' => \$opts{'g'},
		's|snp6' => \$opts{'s'},
		'r|ref=s' => \$opts{'r'},
		'm|minqual=n' => \$opts{'m'},
		'q|mapqual=n' => \$opts{'q'},
    'v|version'   => \$opts{'v'},
	);

	pod2usage(0) if($opts{'h'});
  if($opts{'v'}){
    print Sanger::CGP::AlleleCount->VERSION."\n";
    exit;
  }
	pod2usage(1) if(!$opts{'b'} || !$opts{'l'});
	pod2usage(1) if($opts{'g'} && $opts{'s'});
	$opts{'m'} = $MIN_PBQ unless(defined $opts{'m'});
	$opts{'q'} = $MIN_MAPQ unless(defined $opts{'q'});

	return \%opts;
}

__END__

=head1 NAME

alleleCounts.pl - Generate tab seperated file with allelic counts and depth for each specified locus.

=head1 SYNOPSIS

alleleCounts.pl

  Required:

    -bam      -b      BAM/CRAM file (expects co-located index)
                       - if CRAM see '-ref'
    -output   -o      Output file [STDOUT]
    -loci     -l      Alternate loci file (just needs chr pos)
                       - output is different, counts for each residue

  Optional:
    -ref      -r      genome.fa, required for CRAM (with colocated .fai)
    -minqual  -m      Minimum base quality to include (integer) [30]
    -mapqual  -q      Minimum mapping quality of read (integer) [35]
    -gender   -g      flag, presence indicates loci file to be treated as gender SNPs.
                       - cannot be used with 's'
    -snp6     -s      flag, presence indicates loci file is SNP6 format.
                       - cannot be used with 'g'
                       - changes output format
    -help     -h      This message
    -version  -v      Version number

=cut

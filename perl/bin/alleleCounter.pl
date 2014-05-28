#!/usr/bin/perl

##########LICENCE##########
# Copyright (c) 2014 Genome Research Ltd. 
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


use strict;
use Data::Dumper;
use Carp;
use English qw( -no_match_vars );
use warnings FATAL => 'all';

use Getopt::Long 'GetOptions';
use Pod::Usage;

use Sanger::CGP::AlleleCount::Genotype;

{
  my $options = option_builder();
  run($options);
}

sub run {
  my ($options) = @_;
  open my $FH, '>', $options->{'o'} or croak 'Failed to create '.$options->{'o'};
  my $geno_ob = Sanger::CGP::AlleleCount::Genotype->new();
  if($options->{'l'}) {
    $geno_ob->get_full_loci_profile($options->{'b'}, $FH, $options->{'l'}, $options->{'m'});
  }
  else {
    $geno_ob->get_full_snp6_profile($options->{'b'}, $FH, $options->{'m'});
  }
  close $FH;
}

sub option_builder {
	my ($factory) = @_;

	my %opts;

	&GetOptions (
		'h|help'    => \$opts{'h'},
		'b|bam=s' => \$opts{'b'},
		'o|output=s' => \$opts{'o'},
		'l|locus=s' => \$opts{'l'},
		'm|minqual=n' => \$opts{'m'},
    'v|version'   => \$opts{'v'},
	);

	pod2usage(0) if($opts{'h'});
  if($opts{'v'}){
    print Sanger::CGP::AlleleCount::Genotype->VERSION."\n";
    exit;
  }
	pod2usage(1) if(!$opts{'o'} || !$opts{'b'});

	return \%opts;
}

__END__

=head1 NAME

alleleCounts.pl - Generate tab seperated file with allelic counts and depth for each specified locus.

=head1 SYNOPSIS

alleleCounts.pl

  Required:

    -bam      -b      BWA bam file (expects co-located index)
    -output   -o      Output file
    -minqual  -m      Minimum base quality to include (integer)
    -loci     -l      Alternate loci file (just needs chr pos)
                      - output is different, counts for each residue

  Optional:
    -help     -h      This message
    -version  -v      Version number

=cut

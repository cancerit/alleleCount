#!/usr/bin/perl

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

#!/usr/bin/perl

##########LICENCE##########
# Copyright (c) 2014-2021 Genome Research Ltd.
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
use Carp;
use English qw( -no_match_vars );
use warnings FATAL => 'all';

use Getopt::Long 'GetOptions';
use Pod::Usage;

use Sanger::CGP::AlleleCount;
use Sanger::CGP::AlleleCount::ToJson;

{
  my $options = option_builder();
  $options->{'o'} = '/dev/stdout' unless(defined $options->{'o'});
  run($options);
}

sub run {
  my ($options) = @_;
  my $json_string = Sanger::CGP::AlleleCount::ToJson->alleleCountToJson($options->{'a'}, $options->{'l'});
  my $OUT;
  open($OUT, '>', $options->{'o'}) or croak("Error opening file for output: $!");
    print $OUT "$json_string";
  close($OUT) or croak("Error closing output file for JSON conversion: $!");
}


sub option_builder {
  my ($factory) = @_;

  my %opts;

  &GetOptions (
        'h|help'    => \$opts{'h'},
        'l|locus-file=s' => \$opts{'l'},
        'a|allelecount-file=s' => \$opts{'a'},
        'o|output-file=s' => \$opts{'o'},
        'v|version'   => \$opts{'v'},
  );

  pod2usage(0) if($opts{'h'});
  if($opts{'v'}){
    print Sanger::CGP::AlleleCount->VERSION."\n";
    exit;
  }
  pod2usage(1) if(!$opts{'l'} || !$opts{'a'});
  return \%opts;
}

__END__

=head1 NAME

alleleCounterToJson.pl - Generate JSON format file from the tab seperated format

=head1 SYNOPSIS

alleleCounterToJson.pl

  Required:

    -locus-file          -l     File containing SNP positions used for allelecounter
    -allelecount-file    -a     Allelecounter output file

  Optional:
    -output-file         -o      Output file (default: stdout)
    -help                -h      This message
    -version             -v      Version number

=cut

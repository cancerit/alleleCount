package Sanger::CGP::AlleleCount::ToJson;

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

use Const::Fast qw(const);

=item new

Null constructor

=cut

sub new {
  my ($class) = @_;
  my $self = { };
  bless $self, $class;
  return $self;
}

=item alleleCountToJson

Convert allele count file result format to JSON

=cut

sub alleleCountToJson{
  my ($countsfile, $snpsfile) = @_;
  my $tmp;
  my $FH;
  my $SNPS;
  my $snp_list;

  #TODO open gzipped file....
  open($SNPS, '<', $snpsfile) or $log->logcroak("Error opening allele count locus file for JSON conversion: $!");
    while(<$SNPS>){
      my $line = $_;
      next if($line =~ m/^\s*#/);
      chomp($line);
      my ($chr,$pos,$name,undef) = split(/\s+/,$line);
      $snp_list->{$chr}->{$pos} = $name;
    }
  close($SNPS) or $log->logcroak("Error closing allele count locus file for JSON conversion: $!");

  my $fh = new IO::Zlib;
  if($fh->open($countsfile, "rb")){
    while(<$fh>){
      my $line = $_;
      next if($line =~ m/^\s*#/);
      chomp($line);
      my ($chr,$pos,$a,$c,$g,$t,$good) = split(/\s+/,$line);
      my $nom = $snp_list->{$chr}->{$pos};
      my $genotype = _calculate_genotype_from_allele_count($a,$c,$g,$t,$good);
      $tmp->{$nom} = $genotype;
    }
    $fh->close;
  }else{
    $log->logcroak("Error trying to open file for SNP locus loading: $countsfile\n");
  }
  my $jsonstr = encode_json($tmp);
  return $jsonstr;
}

1;
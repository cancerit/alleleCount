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
use Carp;
use English qw( -no_match_vars );
use warnings FATAL => 'all';

use Getopt::Long 'GetOptions';
use Pod::Usage;
use Const::Fast qw(const);

use Sanger::CGP::AlleleCount;

print Sanger::CGP::AlleleCount->VERSION."\n";

__END__

=head1 NAME

alleleCounter_version.pl - Supply a version numnber for the alleleCounter code.

=head1 SYNOPSIS

alleleCounter_version.pl

=cut

/**   LICENSE
* Copyright (c) 2014 Genome Research Ltd.
*
* Author: Cancer Genome Project cgpit@sanger.ac.uk
*
* This file is part of alleleCount.
*
* alleleCount is free software: you can redistribute it and/or modify it under
* the terms of the GNU Affero General Public License as published by the Free
* Software Foundation; either version 3 of the License, or (at your option) any
* later version.
*
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
* details.
*
* You should have received a copy of the GNU Affero General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#include "minunit.h"
#include <bam_access.h>

char *test_bam = "../testData/test.bam";

char *test_bam_access_get_position_base_counts(){
	//Check with default settings
	char *chr = "22";
	int pos = 16165776;
	int chk = -1;
	chk = bam_access_openbam(test_bam);
	check(chk == 0,"Error trying to open bam file '%s'.",test_bam);
	loci_stats *stats = bam_access_get_position_base_counts(chr,pos);
	mu_assert(stats->base_counts[0]==2,"Check A count 1");
	mu_assert(stats->base_counts[1]==17,"Check C count 1");
	mu_assert(stats->base_counts[2]==0,"Check G count 1");
	mu_assert(stats->base_counts[3]==0,"Check T count 1");

	free(stats->base_counts);

	int min_bq = 15;
	bam_access_min_base_qual(min_bq);
	stats = bam_access_get_position_base_counts(chr,pos);
	mu_assert(stats->base_counts[0]==2,"Check A count 2");
	mu_assert(stats->base_counts[1]==18,"Check C count 2");
	mu_assert(stats->base_counts[2]==0,"Check G count 2");
	mu_assert(stats->base_counts[3]==0,"Check T count 2");

	free(stats->base_counts);

	int min_mq = 15;
	bam_access_min_map_qual(min_mq);
	stats = bam_access_get_position_base_counts(chr,pos);
	mu_assert(stats->base_counts[0]==2,"Check A count 3");
	mu_assert(stats->base_counts[1]==24,"Check C count 3");
	mu_assert(stats->base_counts[2]==0,"Check G count 3");
	mu_assert(stats->base_counts[3]==0,"Check T count 3");

	free(stats->base_counts);

	bam_access_closebam();

	return NULL;
error:
	return "1";
}

char *all_tests() {
   mu_suite_start();
   mu_run_test(test_bam_access_get_position_base_counts);
   return NULL;
}

RUN_TESTS(all_tests);

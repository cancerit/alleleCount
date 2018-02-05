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
char *test_ref = "../testData/ref.fa.fai";
char *test_bam10X = "../testData/test10X.bam";
char *test_10X_cnts = "../testData/test10X_true.cnts";

char *test_bam_access_get_position_base_counts(){
	//Check with default settings
	char *chr = "22";
	int pos = 16165776;
	loci_stats *stats = malloc(sizeof(loci_stats));
	stats->pos = pos;
	stats->chr = chr;
	stats->base_counts = malloc(sizeof(int) * 4);
	stats->base_counts[0] = 0;
	stats->base_counts[1] = 0;
	stats->base_counts[2] = 0;
	stats->base_counts[3] = 0;
	int chk = -1;
	chk = bam_access_openhts(test_bam,test_ref);
	check(chk == 0,"Error trying to open bam file '%s'.",test_bam);
	int res = bam_access_get_position_base_counts(chr,pos,stats,0,NULL);
	mu_assert(stats->base_counts[0]==2,"Check A count 1");
	mu_assert(stats->base_counts[1]==17,"Check C count 1");
	mu_assert(stats->base_counts[2]==0,"Check G count 1");
	mu_assert(stats->base_counts[3]==0,"Check T count 1");

	free(stats->base_counts);
	stats->base_counts = malloc(sizeof(int) * 4);
	stats->base_counts[0] = 0;
	stats->base_counts[1] = 0;
	stats->base_counts[2] = 0;
	stats->base_counts[3] = 0;
	int min_bq = 15;
	bam_access_min_base_qual(min_bq);
	res = bam_access_get_position_base_counts(chr,pos,stats,0,NULL);
	mu_assert(stats->base_counts[0]==2,"Check A count 2");
	mu_assert(stats->base_counts[1]==18,"Check C count 2");
	mu_assert(stats->base_counts[2]==0,"Check G count 2");
	mu_assert(stats->base_counts[3]==0,"Check T count 2");

	free(stats->base_counts);
	stats->base_counts = malloc(sizeof(int) * 4);
	stats->base_counts[0] = 0;
	stats->base_counts[1] = 0;
	stats->base_counts[2] = 0;
	stats->base_counts[3] = 0;
	int min_mq = 15;
	bam_access_min_map_qual(min_mq);
	res = bam_access_get_position_base_counts(chr,pos,stats,0,NULL);
	mu_assert(stats->base_counts[0]==2,"Check A count 3");
	mu_assert(stats->base_counts[1]==24,"Check C count 3");
	mu_assert(stats->base_counts[2]==0,"Check G count 3");
	mu_assert(stats->base_counts[3]==0,"Check T count 3");
	free(stats->base_counts);
	bam_access_closehts();

   //Check 10X mode
   //Open the 10X BAM
	bam_access_min_base_qual(20);
	bam_access_min_map_qual(200);
	bam_access_inc_flag(0);
	bam_access_exc_flag(0);
	chk = bam_access_openhts(test_bam10X,test_ref);
	check(chk == 0,"Error trying to open bam file '%s'.",test_bam10X);
   FILE *output = fopen("../testData/test10X.cnts","w");
   int loci_count=1;
	chr = "1";
	pos = 198661939;
	stats->pos = pos;
	stats->chr = chr;
	stats->base_counts = malloc(sizeof(int) * 4);
	stats->base_counts[0] = 0;
	stats->base_counts[1] = 0;
	stats->base_counts[2] = 0;
	stats->base_counts[3] = 0;
   res = bam_access_get_multi_position_base_counts(&stats,loci_count,1,output);
   fclose(output);
	free(stats->base_counts);
   //Now load the output and check it's correct
   FILE *gold = fopen(test_10X_cnts,"r");
   FILE *cnts10X = fopen("../testData/test10X.cnts","r");
   //Check we can get the files
   check(cnts10X != NULL && gold !=NULL,"Error trying to open 10X output file.");
   //Now compare them for being identical
   int ch1,ch2;
   do{
     ch1 = getc(gold);
     ch2 = getc(cnts10X);
   }while((ch1 != EOF) && (ch2 != EOF) && (ch1 == ch2));
   mu_assert(ch1==ch2,"Check 10X output");
   fclose(cnts10X);
   fclose(gold);

	bam_access_closehts();
	free(stats);

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

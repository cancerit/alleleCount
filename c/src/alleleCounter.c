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

#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <string.h>
#include <assert.h>
#include <bam_access.h>
#include "dbg.h"

static int min_base_q = 20;
static int min_map_q = 35;
static char *hts_file;
static char *loci_file;
static char *out_file;
static char *ref_file;
static int snp6 = 0;

int check_exist(char *fname){
	FILE *fp;
	if((fp = fopen(fname,"r"))){
		fclose(fp);
		return 1;
	}
	return 0;
}

void alleleCounter_print_usage (int exit_code){

	printf ("Usage: alleleCounter -l loci_file.txt -b sample.bam -o output.txt [-m int] [-r ref.fa.fai]\n\n");
  printf (" -l  --loci-file [file]           Path to loci file.\n");
  printf (" -b  --hts-file [file]            Path to sample HTS file.\n");
  printf (" -o  --output-file [file]         Path write output file.\n\n");

	printf ("Optional\n");
	printf (" -r  --ref-file [file]           Path to reference fasta index file.\n");
	printf ("                                 NB. If cram format is supplied via -b and the reference listed in the cram header can't be found alleleCounter may fail to work correctly.\n");
	printf (" -m  --min-base-qual [int]       Minimum base quality [Default: %d].\n",min_base_q);
	printf (" -q  --min-map-qual [int]        Minimum mapping quality [Default: %d].\n",min_map_q);
	printf (" -v  --version                   Display version number.\n");
	printf (" -h  --help                      Display this usage information.\n\n");
  exit(exit_code);
}

void alleleCounter_print_version (int exit_code){
  printf ("%s\n",ALLELECOUNTER_VERSION);
  exit(exit_code);
}

void alleleCounter_setup_options(int argc, char *argv[]){
  ref_file = NULL;
	const struct option long_opts[] =
	{
             	{"loci-file", required_argument, 0, 'l'},
             	{"hts-file", required_argument, 0, 'b'},
             	{"ref-file", required_argument, 0, 'r'},
             	{"output-file",required_argument , 0, 'o'},
             	{"min-base-qual", required_argument, 0, 'm'},
							{"min-map-qual", required_argument, 0, 'q'},
							{"is-snp6", required_argument, 0, 's'},
							{"version", no_argument, 0, 'v'},
             	{"help", no_argument, 0, 'h'},
             	{ NULL, 0, NULL, 0}
   }; //End of declaring opts

   int index = 0;
   int iarg = 0;

   //Iterate through options
   while((iarg = getopt_long(argc, argv, "l:b:m:o:q:r:hsv", long_opts, &index)) != -1){
   	switch(iarg){
   		  case 'h':
         	alleleCounter_print_usage(0);
         	break;

        case 'v':
          alleleCounter_print_version(0);
          break;

      	case 'l':
      		loci_file = optarg;
      		break;

      	case 'm':
      		min_base_q = atoi(optarg);
      		break;

        case 'r':
          ref_file = optarg;
          break;

      	case 'q':
      		min_map_q = atoi(optarg);
      		break;

      	case 'b':
      		hts_file = optarg;
      		break;

      	case 'o':
      		out_file = optarg;
      		break;

      	case 's':
      		snp6 = 1;
      		break;

				case '?':
          alleleCounter_print_usage (1);
          break;

      	default:
      		alleleCounter_print_usage (1);

   	}; // End of args switch statement

   }//End of iteration through options

   if(check_exist(loci_file) != 1){
   	printf("Loci file %s does not appear to exist.\n",loci_file);
   	alleleCounter_print_usage(1);
   }
   if(check_exist(hts_file) != 1){
   	printf("HTS file %s does not appear to exist.\n",hts_file);
   	alleleCounter_print_usage(1);
   }
   if(ref_file){
    if( check_exist(ref_file) != 1){
   	  printf("Reference file provided %s does not appear to exist.\n",ref_file);
   	  alleleCounter_print_usage(1);
   	 }
   }
   return;
}

int print_loci_head(FILE *output){
	int chk = fprintf(output,"#CHR\tPOS\tCount_A\tCount_C\tCount_G\tCount_T\tGood_depth\n");
	return chk;
}

int print_snp6_header(FILE *output){
	int chk = fprintf(output,"#CHR\tPOS\tCount_Allele_A\tCount_Allele_B\tGood_depth\n");
	return chk;
}

int print_header(FILE *output, int snp6){
	if(snp6 == 1){
		return print_snp6_header(output);
	}else{
		return print_loci_head(output);
	}
}

int calculateAlleleCount(int a_cnt, int c_cnt, int g_cnt, int t_cnt, int allele){
	switch (allele){
		case 'A':
			return a_cnt;

		case 'C':
			return c_cnt;

		case 'G':
			return g_cnt;

		case 'T':
			return t_cnt;

		default:
			return -1;
	};
}

int print_loci_section(FILE *output, char *chr, int pos, int a_cnt, int c_cnt, int g_cnt, int t_cnt, int depth){
	assert(output !=NULL);
	return (fprintf(output,"%s\t%d\t%d\t%d\t%d\t%d\t%d\n",chr,pos,a_cnt,c_cnt,g_cnt,t_cnt,depth));
}

int print_snp6_section(FILE *output, char *chr, int pos, int allele_a, int allele_b, int depth){
	assert(output !=NULL);
	return (fprintf(output,"%s\t%d\t%d\t%d\t%d\n",chr,pos,allele_a,allele_b,depth));
}

int print_section(FILE *output, char *chr, int pos, int a_cnt, int c_cnt, int g_cnt,
															int t_cnt, int depth, int snp6, char allele_A, char allele_B){
	if(snp6 == 1){
		int all_a_cnt = calculateAlleleCount(a_cnt, c_cnt, g_cnt, t_cnt, allele_A);
		check(all_a_cnt>=0,"Error getting A Allele count '%c'",allele_A);
		int all_b_cnt = calculateAlleleCount(a_cnt, c_cnt, g_cnt, t_cnt, allele_B);
		check(all_b_cnt>=0,"Error getting B Allele count '%c'",allele_B);
		return print_snp6_section(output, chr, pos, all_a_cnt, all_b_cnt, depth);
	}else{
		return print_loci_section(output, chr, pos, a_cnt, c_cnt, g_cnt,t_cnt, depth);
	}
	error:
		return -1;
}

int get_position_info_from_file(char *line, char *chr, int *pos,int snp6, char *allele_A, char *allele_B, int i){
	int chr_d = 0;

	if(snp6==1){
		int chk = sscanf(line,"%d%*[ \t]%d%*[ \t]%*s%*[ \t]%*s%*[ \t]%c%*[ \t]%c",&chr_d,pos,allele_A,allele_B);
		if(chk == 2){
			int try = sprintf(chr,"%d",chr_d);
			check(try >0,"Error trying to convert chromosome name '%d'to string.",chr_d);
		}else{
			//Try again but a string match
			chk = sscanf(line,"%s%*[ \t]%d%*[ \t]%*s%*[ \t]%*s%*[ \t]%c%*[ \t]%c",chr,pos,allele_A,allele_B);
			check(chk==4,"Error attempting string match of allele position info from SNP6 line %s.",line);
		}
		check(chk==2,"Error parsing SNP6 file line number %d: '%s'.",i,line);
	}else{
		int chk = sscanf(line,"%d%*[ \t]%d",&chr_d,pos);
		if(chk == 2){
			int try = sprintf(chr,"%d",chr_d);
			check(try >0,"Error trying to convert chromosome name '%d'to string.",chr_d);
		}else{
			//Try again but a string match
			chk = sscanf(line,"%s%*[ \t]%d",chr,pos);
			check(chk==2,"Error parsing loci file line number %d as a string match: '%s'.",i,line);
		}
		check(chk==2,"Error parsing loci file line number %d: '%s'.",i,line);
	}
	return 0;
error:
	return -1;
}

int main(int argc, char *argv[]){
	//Get the options commandline
	alleleCounter_setup_options(argc,argv);
	//Set the min base and mapping quality.
	bam_access_min_base_qual(min_base_q);

	bam_access_min_map_qual(min_map_q);

	FILE *loci_in = NULL;
	//Open output file for writing
	FILE *output = fopen(out_file,"w");
  check(output != NULL, "Error opening file %s for write.",out_file);
	int chk = print_header(output,snp6);
	check(chk >= 0,"Error trying to write header '%s'.",out_file);
	//Open bam file and iterate through chunks until we reach the cutoff.
	chk = -1;

	chk = bam_access_openhts(hts_file,ref_file);
	check(chk == 0,"Error trying to open sequence/index files '%s'.",hts_file);

	//Open loci file
	loci_in = fopen(loci_file,"r");
	check(loci_in != NULL, "Error opening loci file %s for reading.",loci_file);
	char chr[50];
	int pos;
	char allele_A;
	char allele_B;
	char line[512];
	int i = 0;
	while ( fgets(line,sizeof(line),loci_in) != NULL ){
		i++;
		int check = get_position_info_from_file(line,chr,&pos,snp6,&allele_A,&allele_B,i);
		check(check==0,"Error trying to fetch position from file.");

		loci_stats *stats = bam_access_get_position_base_counts(chr,pos);
		int depth = stats->base_counts[0]+stats->base_counts[1]+stats->base_counts[2]+stats->base_counts[3];
		int check_print = print_section(output,chr,pos,stats->base_counts[0],
								stats->base_counts[1],stats->base_counts[2],stats->base_counts[3],depth,
								snp6,allele_A,allele_B);
		check(check_print>0,"Error printing line to output file: %s: %d.",chr,pos);

		free(stats);
	}

	//Close files.
	fclose(loci_in);
	bam_access_closehts();
	fclose(output);
	return 0;

error:
	bam_access_closehts();
	if(loci_in) fclose(loci_in);
	if(output) fclose(output);
	if(hts_file) free(hts_file);
	if(out_file) free(out_file);
	if(loci_file) free(loci_file);
	return 1;
}

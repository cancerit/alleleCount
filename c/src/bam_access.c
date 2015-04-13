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

#include <bam_access.h>
#include <stdlib.h>
#include <stdio.h>
#include <dbg.h>
#include <assert.h>
#include <limits.h>
#include <cram/cram.h>

#define PO10_LIMIT (INT_MAX/10)

file_holder *fholder;
int counter = -1;
int include_sw = 0;
int include_dup = 0;
int include_se = 0;
int min_base_qual = 20;
int min_map_qual = 35;
int maxitercnt = 1000000000; //Overrride internal maxcnt for iterator!

typedef struct {

} plp_aux_t;

int bam_access_openhts(char *hts_file, char *ref_file){
	assert(hts_file != NULL);
	//Assign memory for the file name etc holding struct
	fholder = malloc(sizeof(file_holder));
	check_mem(fholder);
	//Beginning and end of tmp struct for bam access
	fholder->beg = 0; fholder->end = 0x7fffffff;  // The max 32 bit integer.
	//Open a file for read from compressed bam.
	fholder->in = hts_open(hts_file, "r");
	check(fholder->in != 0,"HTS file %s failed to open.",hts_file);
  fholder->idx = sam_index_load(fholder->in,hts_file);
	check(fholder->idx != 0,"HTS index file %s failed to open.",hts_file);
	if(ref_file){
	  hts_set_fai_filename(fholder->in, ref_file);
	}else{

	  if(fholder->in->format.format == cram) log_warn("No reference file provided for a cram input file, if the reference described in the cram header can't be located this script may fail.");
	}
  //Check for generic header read method.
  fholder->head = sam_hdr_read(fholder->in);
	return 0;
error:
	if(fholder->in) hts_close(fholder->in);
	if(fholder) free(fholder);
	return -1;
}

void bam_access_closehts(){
	if(fholder->idx) hts_idx_destroy(fholder->idx);
	if(fholder->in) hts_close(fholder->in);
	if(fholder) free(fholder);
	return;
}

int no_of_digits(int i){
	int n,po10;

  if (i < 0) i = -i;
  n=1;
  po10=10;
  while(i>=po10)
  {
    n++;
    if (po10 > PO10_LIMIT) break;
    po10*=10;
  }
  return n;
}

//callback for bam_plp_init
static int pileup_func(void *data, bam1_t *b){
  return 0;
}

loci_stats *bam_access_get_position_base_counts(char *chr, int posn){
	char *region = NULL;
	hts_itr_t *iter = NULL;
	bam1_t* b = NULL;
	bam_plp_t buf;
	loci_stats *stats = malloc(sizeof(loci_stats *));
	check_mem(stats);
	stats->base_counts = malloc(sizeof(int) * 4);
	check_mem(stats->base_counts);
	stats->base_counts[0] = 0;
	stats->base_counts[1] = 0;
	stats->base_counts[2] = 0;
	stats->base_counts[3] = 0;
	fholder->stats = stats;

	region = malloc((sizeof(char *) * (strlen(chr)+1))+sizeof(":")+sizeof("-")+(sizeof(char)*((no_of_digits(posn)*2)+1)));
	sprintf(region,"%s:%d-%d",chr,posn,posn);
	fholder->beg = posn;
	fholder->end = posn;

  // initialize pileup
	buf = bam_plp_init(pileup_func, (void *)fholder);
	bam_plp_set_maxcnt(buf,maxitercnt);

  /*
  sam_fetch(fholder->in, fholder->idx, ref, fholder->beg, fholder->end, buf, fetch_algo_func);
  */
  //Replace fetch with iterator for htslib compatibility.
  b = bam_init1();
  iter = sam_itr_querys(fholder->idx, fholder->head, region);
  int result;
  int count = 0;
  while ((result = sam_itr_next(fholder->in, iter, b)) >= 0) {
    if(b->core.qual < min_map_qual || (b->core.flag & BAM_FUNMAP)
			|| !(b->core.flag & BAM_FPROPER_PAIR) || (b->core.flag & BAM_FMUNMAP)//Proper pair and mate unmapped
			|| (b->core.flag & BAM_FDUP)//1024 is PCR/optical duplicate
			|| (b->core.flag & BAM_FSECONDARY) || (b->core.flag & BAM_FQCFAIL)//Secondary alignment, quality fail
			|| (b->core.flag & BAM_FSUPPLEMENTARY) ) continue;
    count++;
    bam_plp_push(buf, b);
  }
  sam_itr_destroy(iter);
  bam_plp_push(buf, 0);
  int tid, pos, n_plp = -1;
  const bam_pileup1_t *pil;
  while ( (pil=bam_plp_next(buf, &tid, &pos, &n_plp)) > 0) {
    if((pos+1) != posn) continue;
    int i=0;
   	for(i=0;i<n_plp;i++){
      const bam_pileup1_t *p = pil + i;
      int qual = bam_get_qual(p->b)[p->qpos];
      uint8_t c = bam_seqi(bam_get_seq(p->b), p->qpos);
      if(!(p->is_del) &&  qual >= min_base_qual
            &&  p->b->core.qual >= min_map_qual){
           //&& (c == 1 /*A*/|| c == 2 /*C*/|| c == 4 /*G*/|| c == 8 /*T*/)){
        //Now we add a new read pos struct to the list since the read is valid.
        //char cbase = toupper(bam_nt16_rev_table[c]);
        switch(c){
          case 1:
            fholder->stats->base_counts[0]++;
            break;

          case 2:
            fholder->stats->base_counts[1]++;
            break;

          case 4:
            fholder->stats->base_counts[2]++;
            break;

          case 8:
            fholder->stats->base_counts[3]++;
            break;

          default:
            break;

          }; // End of args switch statement */
   	    }
   	  }
  } //End of iteration through pileup
	//bam_plp_push(buf, 0); // finalize pileup
  bam_plp_destroy(buf);
	free(region);
	return fholder->stats;

error:
	//if(region) free(region);
	if(fholder->stats){
		if(fholder->stats->base_counts) free(fholder->stats->base_counts);
		free(fholder->stats);
	}
	if(iter) sam_itr_destroy(iter);
	if(b) bam_destroy1(b);
	if(region) free(region);
	return NULL;
}



void bam_access_min_base_qual(int qual){
	min_base_qual = qual;
	return;
}

void bam_access_min_map_qual(int qual){
	min_map_qual = qual;
	return;
}

/**   LICENSE
* Copyright (c) 2014-2017 Genome Research Ltd.
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
#include <htslib/cram.h>
#include "khash.h"

#define PO10_LIMIT (INT_MAX/10)
KHASH_SET_INIT_STR(strh)

file_holder *fholder;
int counter = -1;
int include_sw = 0;
int include_dup = 0;
int include_se = 0;
int min_base_qual = 20;
int min_map_qual = 35;
int inc_flag = 3;
int exc_flag = 3852;
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
	check(fholder->idx != 0,"HTS index file for %s failed to open.",hts_file);
	if(ref_file){
	  int chk = hts_set_fai_filename(fholder->in, ref_file);
		check(chk==0,"Error setting fai filename %s.",ref_file);
	}else{
	  if(fholder->in->format.format == cram) log_warn("No reference file provided for a cram input file, if the reference described in the cram header can't be located this script may fail.");
	}
  //Check for generic header read method.
  fholder->head = sam_hdr_read(fholder->in);
	return 0;
error:
  if(fholder->idx) hts_idx_destroy(fholder->idx);
	if(fholder->in) hts_close(fholder->in);
	if(fholder->head) bam_hdr_destroy(fholder->head);
	if(fholder) free(fholder);
	return -1;
}

void bam_access_closehts(){
	if(fholder && fholder->idx) hts_idx_destroy(fholder->idx);
	if(fholder && fholder->in) hts_close(fholder->in);
	if(fholder && fholder->head) bam_hdr_destroy(fholder->head);
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

void pileupCounts(const bam_pileup1_t *pil, int n_plp, loci_stats *stats){
	khash_t(strh) *h;
	khint_t k;
	h = kh_init(strh);
	int i=0;
	for(i=0;i<n_plp;i++){
		const bam_pileup1_t *p = pil + i;
		int qual = bam_get_qual(p->b)[p->qpos];
		uint8_t c = bam_seqi(bam_get_seq(p->b), p->qpos);
		int absent;
    k = kh_put(strh, h, bam_get_qname(p->b), &absent);
		if(!(p->is_del) &&  qual >= min_base_qual && absent){
			//&& (c == 1 /*A*/|| c == 2 /*C*/|| c == 4 /*G*/|| c == 8 /*T*/)){
			//Now we add a new read pos struct to the list since the read is valid.
			//char cbase = toupper(bam_nt16_rev_table[c]);
			switch(c){
				case 1:
				stats->base_counts[0]++;
				break;

				case 2:
				stats->base_counts[1]++;
				break;

				case 4:
				stats->base_counts[2]++;
				break;

				case 8:
				stats->base_counts[3]++;
				break;

				default:
				break;

			}; // End of args switch statement */
			//Add the readname to the hash
			kh_key(h, k) = bam_get_qname(p->b);
		}
	}
	kh_destroy(strh, h);
	return;
}

int bam_access_get_multi_position_base_counts(loci_stats **stats, int stats_count){
	char *region = NULL;
	hts_itr_t *iter = NULL;
	bam1_t* b = NULL;
	bam_plp_t buf;

	//Find start and stop for each contig and retrieve a contig at once
	int start = 0;
	int stop = 0;
	char* this_chr;
	int stop_idx = 0;
	int start_idx = 0;
	while(start_idx<stats_count){
		int i=start_idx;
		stop = stats[i]->pos;
		stop_idx = i;
		this_chr = stats[start_idx]->chr;
		start = stats[start_idx]->pos;
		if(i+1<stats_count){
			i++;
			//Calculate stop of contig
			while(strcmp(this_chr,stats[i]->chr)==0){
				stop = stats[i]->pos;
				stop_idx = i;
				i++;
				if(i==stats_count) break;
			}
		}
		region = malloc((sizeof(char *) * (strlen(this_chr)+1))+sizeof(":")+sizeof("-")+(sizeof(char)*((no_of_digits(start)+no_of_digits(stop))+1)));
		check_mem(region);
		sprintf(region,"%s:%d-%d",this_chr,start,stop);
		// initialize pileup
		buf = bam_plp_init(pileup_func, (void *)fholder);
		bam_plp_set_maxcnt(buf,maxitercnt);
		b = bam_init1();
	  iter = sam_itr_querys(fholder->idx, fholder->head, region);
		int j=start_idx;
		int result;
		const bam_pileup1_t *pl;
		int tid, pos, n_plp = -1;
	  while ((result = sam_itr_next(fholder->in, iter, b)) >= 0) {
	    if(b->core.qual < min_map_qual || (b->core.flag & exc_flag) || (b->core.flag & inc_flag) != inc_flag) continue;
	    bam_plp_push(buf, b);
			while ((pl=bam_plp_next(buf, &tid, &pos, &n_plp)) > 0) {
				if(j==stats_count || pos+1>stats[stop_idx]->pos) break;
				while(pos+1>stats[j]->pos){
					if(j==stop_idx) break;
					j++;//WE've finished this position, move on (no cvg?)
				}
				if(pos+1==stats[j]->pos){
					pileupCounts(pl, n_plp, stats[j]);
				}
				if(pos+1>=stats[j]->pos && j==stop_idx) break;
	    }
	  }//End of iteration through sam_iter
		bam_plp_push(buf, 0); // finalize pileup
		while ((pl=bam_plp_next(buf, &tid, &pos, &n_plp)) > 0) {
			if(j==stats_count || pos+1>stats[stop_idx]->pos) break;
			while(pos+1>stats[j]->pos){
				if(j==stop_idx) break;
				j++;//WE've finished this position, move on (no cvg?)
			}
			if(pos+1==stats[j]->pos){
				pileupCounts(pl, n_plp, stats[j]);
			}
			if(pos+1>=stats[j]->pos && j==stop_idx) break;
		}
		bam_plp_destroy(buf);
		free(region);
		bam_destroy1(b);
		start_idx = stop_idx+1;
	}
	return 0;
	error:
	if(iter) sam_itr_destroy(iter);
	if(b) bam_destroy1(b);
	if(region) free(region);
	return 1;


}

int bam_access_get_position_base_counts(char *chr, int posn, loci_stats *stats){
	char *region = NULL;
	hts_itr_t *iter = NULL;
	bam1_t* b = NULL;
	bam_plp_t buf;
	fholder->stats = stats;

	region = malloc((sizeof(char *) * (strlen(chr)+1))+sizeof(":")+sizeof("-")+(sizeof(char)*((no_of_digits(posn)*2)+1)));
	check_mem(region);
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
  while ((result = sam_itr_next(fholder->in, iter, b)) >= 0) {
    if(b->core.qual < min_map_qual || (b->core.flag & exc_flag) || (b->core.flag & inc_flag) != inc_flag) continue;
    bam_plp_push(buf, b);
  }
  sam_itr_destroy(iter);
  bam_plp_push(buf, 0);
  int tid, pos, n_plp = -1;
  const bam_pileup1_t *pil;
  while ( (pil=bam_plp_next(buf, &tid, &pos, &n_plp)) > 0) {
    if((pos+1) != posn) continue;
		pileupCounts(pil, n_plp, fholder->stats);
  } //End of iteration through pileup
	//bam_plp_push(buf, 0); // finalize pileup
  bam_plp_destroy(buf);
	free(region);
	bam_destroy1(b);
	return 0;

error:
	//if(region) free(region);
	if(fholder->stats){
		if(fholder->stats->base_counts) free(fholder->stats->base_counts);
		free(fholder->stats);
	}
	if(iter) sam_itr_destroy(iter);
	if(b) bam_destroy1(b);
	if(region) free(region);
	return 1;
}

void bam_access_min_base_qual(int qual){
	min_base_qual = qual;
	return;
}

void bam_access_min_map_qual(int qual){
	min_map_qual = qual;
	return;
}

void bam_access_inc_flag(int inc){
  inc_flag = inc;
  return;
}

void bam_access_exc_flag(int exc){
  exc_flag = exc;
  return;
}

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

file_holder *fholder;
int counter = -1;
int include_sw = 0;
int include_dup = 0;
int include_se = 0;
int min_base_qual = 20;
int min_map_qual = 35;

int bam_access_openbam(char *bam_file){
	assert(bam_file != NULL);
	//Assign memory for the file name etc holding struct
	fholder = malloc(sizeof(file_holder));
	check_mem(fholder);
	//Beginning and end of tmp struct for bam access
	fholder->beg = 0; fholder->end = 0x7fffffff;  // The max 32 bit integer.
	//Open a file for read from compressed bam.
	fholder->in = samopen(bam_file, "rb", 0);
	check(fholder->in != 0,"Normal file %s failed to open.",bam_file);
	fholder->idx = bam_index_load(bam_file);
	check(fholder->idx != 0,"Normal index file %s failed to open.",bam_file);
	return 0;
error:
	if(fholder->in) samclose(fholder->in);
	return -1;
}

void bam_access_closebam(){
	if(fholder->idx) bam_index_destroy(fholder->idx);
	if(fholder->in) samclose(fholder->in);
	if(fholder) free(fholder);
	return;
}

// callback for bam_plbuf_init()
static int pileup_algo_func(uint32_t tid, uint32_t pos, int n, const bam_pileup1_t *pil, void *data) {

   //Finally check the base quality is more than or equal to the min base quality and it's not an 'N'.
   file_holder *tmp = (file_holder*)data;
   if ((pos+1) > tmp->beg && (pos+1) <= tmp->end) {
   	int i=0;
   	for(i=0;i<n;i++){
   		const bam_pileup1_t *p = pil + i;
			int qual = bam1_qual(p->b)[p->qpos];
			uint8_t c = bam1_seqi(bam1_seq(p->b), p->qpos);
			if(!(p->is_del) &&  qual >= min_base_qual
								&&  p->b->core.qual >= min_map_qual
								&& (c == 1 || c == 2 || c == 4 || c == 8)){
				//Now we add a new read pos struct to the list since the read is valid.
				char cbase = toupper(bam_nt16_rev_table[c]);
				switch(cbase){
					case 'A':
						tmp->stats->base_counts[0]++;
						break;

					case 'C':
						tmp->stats->base_counts[1]++;
						break;

					case 'G':
						tmp->stats->base_counts[2]++;
						break;

					case 'T':
						tmp->stats->base_counts[3]++;
						break;

					default:
						break;

   				}; // End of args switch statement
			}
		}//End of iteration through each pileup read in this pos.
	}
	return 0;
}

static int fetch_algo_func(const bam1_t *b, void *data){
	bam_plbuf_t *pileup = (bam_plbuf_t*) data;
	//check Mapping Quality and not un mapped //4 // read unmapped
	if(b->core.qual < min_map_qual || (b->core.flag & BAM_FUNMAP)
			|| !(b->core.flag & BAM_FPROPER_PAIR) || (b->core.flag & BAM_FMUNMAP)//Proper pair and mate unmapped
			|| (b->core.flag & BAM_FDUP)//1024 is PCR/optical duplicate
			|| (b->core.flag & BAM_FSECONDARY) || (b->core.flag & BAM_FQCFAIL)//Secondary alignment, quality fail
			|| (b->core.flag & 2048) ){
		return 0;
	}
	bam_plbuf_push(b,pileup);
  return 0;
}

loci_stats *bam_access_get_position_base_counts(char *chr, int pos){
	char *region = NULL;
	loci_stats *stats = malloc(sizeof(loci_stats *));
	check_mem(stats);
	stats->base_counts = malloc(sizeof(int) * 4);
	check_mem(stats->base_counts);
	stats->base_counts[0] = 0;
	stats->base_counts[1] = 0;
	stats->base_counts[2] = 0;
	stats->base_counts[3] = 0;
	fholder->stats = stats;

	region = malloc(sizeof(chr)+sizeof(":")+sizeof("-")+(sizeof(char)*10));
	sprintf(region,"%s:%d-%d",chr,pos,pos);
	fholder->beg = pos;
	fholder->end = pos;
	int ref;
	bam_plbuf_t *buf;
	// parse the tumour region
	bam_parse_region(fholder->in->header, region, &ref,
						 &fholder->beg, &fholder->end);
	check(ref >= 0,"Invalid bam region: %s.",region);

	// initialize pileup
	buf = bam_plbuf_init(pileup_algo_func, fholder);

  bam_fetch(fholder->in->x.bam, fholder->idx, ref, fholder->beg, fholder->end, buf, fetch_algo_func);
	bam_plbuf_push(0, buf); // finalize pileup
  bam_plbuf_destroy(buf);

	free(region);
	return fholder->stats;

error:
	if(region) free(region);
	if(fholder->stats){
		if(fholder->stats->base_counts) free(fholder->stats->base_counts);
		free(fholder->stats);
	}
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

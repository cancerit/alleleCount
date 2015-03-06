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

#ifndef _bam_access_h
#define _bam_access_h

#include <ctype.h>
#include <stdlib.h>
#include <htslib/sam.h>

typedef struct loci_stats{
	int *base_counts;
} loci_stats;

typedef struct file_holder{
	int beg, end;
	htsFile *in;
	hts_idx_t *idx;
	loci_stats *stats;
	bam_hdr_t *head;
} file_holder;

void bam_access_min_base_qual(int qual);

void bam_access_min_map_qual(int qual);

int bam_access_openhts(char *hts_file, char *ref_file);

loci_stats *bam_access_get_position_base_counts(char *chr, int pos);

void bam_access_closehts();

#endif

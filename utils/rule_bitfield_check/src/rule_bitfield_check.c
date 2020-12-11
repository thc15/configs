#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "mppa_hw_eth_parser.h"
#include "rule_bitfield_check.h"


static void fill_struct_mac(int ptype, struct mppa_eth_filter_desc *filter_desc,
			union mppa_eth_filter_desc_b *filter_desc_b)
{
	struct mac_filter_desc *ref = &filter_desc->mac_vlan;
	struct mac_filter_desc_b *m  = &filter_desc_b->mac_vlan;

	printf("%s sizeof %d bytes -> %d words\n", __func__,
	      (int) sizeof(*m), sizeof(*m)>>2);
	u64 amask = rand() & 0x1FFFFFFFFFFFFUL;
	u64 sa     = rand() & 0x1FFFFFFFFFFFFUL;
	u64 da     = rand() & 0x1FFFFFFFFFFFFUL;
	u16 tcimask = rand() & 0xFFFFUL;
	u16 etype   = rand() & 0xFFFFUL;
	u16 tci = rand() & 0xFFFFUL;

	filter_desc->ptype = ptype;
	m->ptype = ptype;

	ref->add_metadata_index  = m->add_metadata_index = 1;
	ref->min_max_swap        = m->min_max_swap       = 1;
	ref->vlan_ctrl           = m->vlan_ctrl          = 2;
	ref->pfc_en              = m->pfc_en             = 0;
	ref->da_cmp_polarity     = m->da_cmp_polarity    = 1;
	ref->da                  = m->da                 = da;
	ref->da_mask             = m->da_mask            = amask;
	ref->da_hash_mask        = m->da_hash_mask       = amask;
	ref->sa_cmp_polarity     = m->sa_cmp_polarity    = 1;
	ref->sa                  = m->sa                 = sa;
	ref->sa_mask             = m->sa_mask            = amask;
	ref->sa_hash_mask        = m->sa_hash_mask       = amask;
	ref->etype_cmp_polarity  = m->etype_cmp_polarity = 1;
	ref->etype               = m->etype              = etype;
	ref->tci_cmp_polarity[0] = m->tci0_cmp_polarity  = 1;
	ref->tci[0]              = m->tci0               = tci;
	ref->tci_mask[0]         = m->tci0_mask          = tcimask;
	ref->tci_hash_mask[0]    = m->tci0_hash_mask     = tcimask;
	ref->tci_cmp_polarity[1] = m->tci1_cmp_polarity  = 1;
	ref->tci[1]              = m->tci1               = tci;
	ref->tci_mask[1]         = m->tci1_mask          = tcimask;
	ref->tci_hash_mask[1]    = m->tci1_hash_mask     = tcimask;
}


static int parser_add_filter_b(char *buf, unsigned int idx,
			       union mppa_eth_filter_desc_b *desc)
{
	int i = idx;

	switch (((u32 *)desc)[0] & 0x1F) {
	case ptype_MAC_VLAN:
	default:
		memcpy(buf + (i << 2), (void*)desc, sizeof(*desc));
		i += sizeof(*desc) >> 2;
	}
	return i;
}

/* Parser must be disabled */
static void parser_ram_disp(const char *buf, int idx)
{
	int ram_line;
	u32 *p = (u32 *)buf;

	for (ram_line = 0; ram_line < idx/13 + 1; ++ram_line) {
		printf ("0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x\n"
			"0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x\n",
			p[0], p[1], p[2], p[3],
			p[4], p[5], p[6], p[7],
			p[8], p[9], p[10], p[11], p[12]);
		p += 13;
	}
}

int main()
{
	int idx = 0;
	int ref_idx = 0;
	char ref_buf[4096];
	char buf[4096];

	struct mppa_eth_filter_desc filter_desc;
	union mppa_eth_filter_desc_b filter_desc_b;

	srand ( 123 );
	fill_struct_mac(ptype_MAC_VLAN, &filter_desc, &filter_desc_b);
	ref_idx = eth_lb_add_filter(&ref_buf[0], 0, ref_idx, &filter_desc);
	idx = parser_add_filter_b(buf, idx, &filter_desc_b);
	if (idx != ref_idx)
		fprintf(stderr, "FAILED idx(%d) != ref_idx(%d)\n", idx, ref_idx);

	if (memcmp(buf, ref_buf, sizeof(buf))) {
		fprintf(stderr, "memcmp FAILED\n");
		printf("buf:\n");
		parser_ram_disp(buf, idx);
		printf("ref_buf:\n");
		parser_ram_disp(ref_buf, ref_idx);
	}

	return 0;
}

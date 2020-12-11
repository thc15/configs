#ifndef RULE_BITFIELD_CHECK_H_
#define RULE_BITFIELD_CHECK_H_

//#include "linux/types.h"
typedef  uint8_t u8;
typedef  uint16_t u16;
typedef  uint32_t u32;
typedef  uint64_t u64;

/**
 * struct mac_filter_desc - using bitfield
 */
struct mac_filter_desc_b {
/*	u32 word[13];
	struct {*/
		u32 ptype             : 5;
		u32 add_metadata_index : 1;
		u32 min_max_swap     : 1;
		u32 vlan_ctrl        : 2;   /* 0: No Vlan, 1: 1 Vlan, 2: Dual Vlan,
		      		     * 3: (skip any vlan tags)
		      		     */
		u32 pfc_en           : 1;
		u32 da_cmp_polarity  : 1;
		u64 da               : 48;
		u64 da_mask          : 48;
		u64 da_hash_mask     : 48;
		u32 sa_cmp_polarity  : 1;    /* 0: src == expected,
					      * 1: src != expected
					      * */
		u64 sa               : 48;
		u64 sa_mask          : 48;
		u64 sa_hash_mask     : 48;
		u32 etype_cmp_polarity : 2;  /* 0: disabled, 1: Match etype = expected,
					       * 2: Match if etype != expected
					       */
		u32 etype             : 16;
		u32 tci0_cmp_polarity : 1; /* 0: tci[i] == expected_tci[i],
					    * 1: tci[i] != expected_tci[i]
					    */
		u32 tci0              : 16;
		u32 tci0_mask         : 16;
		u32 tci0_hash_mask    : 16;
		u32 tci1_cmp_polarity : 1; /* 0: tci[i] == expected_tci[i],
					    * 1: tci[i] != expected_tci[i]
					    */
		u32 tci1              : 16;
		u32 tci1_mask         : 16;
		u32 tci1_hash_mask    : 16;
//	} __packed;
} __packed;


union mppa_eth_filter_desc_b {
	struct mac_filter_desc_b mac_vlan;
	//union custom_filter_desc_b custom;
};

#endif // RULE_BITFIELD_CHECK_H_

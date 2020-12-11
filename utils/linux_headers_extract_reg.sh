#!/bin/bash

usage() {
	echo "Usage $0 [input_header_file] [prefix] [reg] [bit_accessors]"
	echo "   input_header_file: linux_header with reg spec"
	echo "   prefix:            prefix to be added to accessors"
	echo "   reg:               register name (define)"
	echo "   bit_accessors:     generate 1-bit accessors"
}

IN="$1"

if [ ! -f "$IN" ]; then
  echo "$IN does not exist"
  usage
  exit 1
fi

if [ $# -ne 4 ]; then
	usage
	echo "Bad arg number"
	exit 2
fi

PREFIX=$2
REG=$3
GEN_BITFIELD_ACCESSOR=$4
OUT_FILE="./accessors.h"


TMP=`mktemp`

echo "Looking $REG in $IN"
echo $TMP
grep $REG $IN | sed -e 's/^\#define\s//g' > $TMP
#first occurence of $REG
BASE_REG=`grep "BASE" $TMP | head -1 |  cut -d ')' -f1 `

# Args
BASE_REG="${BASE_REG,,}"
REG_ARGS=`echo $BASE_REG | cut -d '(' -f2`
FARGS=`echo $REG_ARGS | sed -e 's/.*base//'`
FARGS=`echo $FARGS | sed -e 's/^,\s//'`
if [ "$FARGS" != "" ]; then
FARGS=`echo unsigned int $FARGS | sed -e 's/\,\s/, unsigned int /g'`
FARGS="${FARGS}, "
fi

echo "/* $REG */" > $OUT_FILE

T=`mktemp`
echo $T
grep "_SHIFT" $TMP > $T

if [ $? -ne 0 ]; then
	SEP=`echo $PREFIX | sed s/.*_//`
	BASE=`echo $BASE_REG | cut -d ')' -f1`
	BASE=`echo $BASE | cut -d '(' -f1`
	f=`echo $BASE | sed -e s/.*_$SEP//`
	echo $f
#get
cat >> $OUT_FILE <<DELIM
mppa_eth_ret_t
${PREFIX}_get${f}(${FARGS}u32 *val)
{
	*val = readl(${REG}(${REG_ARGS}));
	return MPPA_ETH_RET_OK;
}

DELIM
#set
cat >> $OUT_FILE <<DELIM
mppa_eth_ret_t
${PREFIX}_set${f}(${FARGS}u32 val)
{
	writel(val, ${REG}(${REG_ARGS}));
	return MPPA_ETH_RET_OK;
}

DELIM
fi


while read p; do
  field=`echo $p | sed -e 's/_SHIFT.*//g'`
  echo $field
  REG_PREFIX="MPPA_ETH_PHY_MAC_CTRL"
  f=$(eval "echo $field | sed -e s/$REG_PREFIX// ")

#  echo "${f,,}"
  fieldlc="${f,,}"

egrep "${field}_MASK.*ULL" $TMP
if [ $? -eq 0 ]; then
#####################64 bits##########################
#get
cat >> $OUT_FILE <<DELIM
mppa_eth_ret_t
${PREFIX}_get${fieldlc}(${FARGS}u64 *val)
{
	u64 reg = 0;
	reg = readq(${REG}(${REG_ARGS}));
	reg &= (${field}_MASK);
	*val = reg >> (${field}_SHIFT);
	return MPPA_ETH_RET_OK;
}

DELIM
#set
cat >> $OUT_FILE <<DELIM
mppa_eth_ret_t
${PREFIX}_set${fieldlc}(${FARGS}u64 val)
{
	u64 reg = 0;
	reg = readq(${REG}(${REG_ARGS}));
	reg &= ~(${field}_MASK);
	reg |= val << (${field}_SHIFT);
	writeq(reg, ${REG}(${REG_ARGS}));
	return MPPA_ETH_RET_OK;
}

DELIM

else
#####################32 bits##########################
if [ "$GEN_BITFIELD_ACCESSOR" == "0" ]; then
#get
cat >> $OUT_FILE <<DELIM
mppa_eth_ret_t
${PREFIX}_get${fieldlc}(${FARGS}u8 *val)
{
	u32 reg = 0;
	reg = readl(${REG}(${REG_ARGS}));
	reg &= (${field}_MASK);
	*val = reg >> (${field}_SHIFT);
	return MPPA_ETH_RET_OK;
}

DELIM

#set
cat >> $OUT_FILE <<DELIM
mppa_eth_ret_t
${PREFIX}_set${fieldlc}(${FARGS}u8 val)
{
	u32 reg = 0;
	reg = readl(${REG}(${REG_ARGS}));
	reg &= ~(${field}_MASK);
	reg |= val << (${field}_SHIFT);
	writel(reg, ${REG}(${REG_ARGS}));
	return MPPA_ETH_RET_OK;
}

DELIM
else
	fargs=`echo $FARGS | sed -e 's/,$//'`
cat >> $OUT_FILE <<DELIM
mppa_eth_ret_t
${PREFIX}_get${fieldlc}(${fargs}, bool *is_enabled)
{
	*is_enabled = mppa_eth_test_bit( ${field}_SHIFT,
			${REG}(${REG_ARGS}));
	return MPPA_ETH_RET_OK;
}

mppa_eth_ret_t
${PREFIX}_set${fieldlc}(${fargs})
{
	mppa_eth_set_bit( ${field}_SHIFT,
			${REG}(${REG_ARGS}));
	return MPPA_ETH_RET_OK;
}

mppa_eth_ret_t
${PREFIX}_clear${fieldlc}(${fargs})
{
	mppa_eth_clear_bit( ${field}_SHIFT,
			${REG}(${REG_ARGS}));
	return MPPA_ETH_RET_OK;
}

DELIM

fi # $GEN_BITFIELD_ACCESSOR
fi # 64bits
done <$T

#cat $OUT_FILE

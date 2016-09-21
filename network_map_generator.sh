#!/bin/bash
################################################################################
# Global vars
export LAST
export TMP_FILE
declare -A RESULT_FILE
mtr_stat_count=4
################################################################################
# Define logging function
INFO(){ echo -n "INFO: "; echo "$@"; }

################################################################################
# Initialization
RESULT_FILE[DOT]=new_map.dot
INFO "Result dot file: ${RESULT_FILE[DOT]}"

################################################################################
# Define some function
mtr_w(){
    DEST_HOST="$1"
    mtr -w -r -c $mtr_stat_count "$DEST_HOST" | \
        tail -n +3 | \
        awk '{print $1 $2}' | sed 's/.|--/.|/g'
}

GEN_ROUTE_GRAPH(){
    IP=$1 LAST="0.|$(hostname)"
    for node in $(mtr_w $IP); do
        echo \"$LAST\" -- \"$node\"
        LAST=$node
    done
    echo \"$LAST\" -- \"Target:'\n'$IP\"
}
################################################################################
# Destination host for L3 Network map
hosts=(
    google.com vk.com github.com
)

TMP_FILE=$(mktemp)

INFO "Gathering data"
for IP in "${hosts[@]}" ; do
    GEN_ROUTE_GRAPH $IP >> $TMP_FILE &
    sleep 0.1
    echo -n "$IP "
done

echo
INFO "Please wait for ~ ${mtr_stat_count}s"
wait

################################################################################
INFO "Generating dot file"
{
    echo 'graph {'
    sort -u $TMP_FILE
    echo '}'
} > ${RESULT_FILE[DOT]}

rm $TMP_FILE

################################################################################
# Generate png/svg
for dot_file in ./*.dot; do
    BASENAME=$(basename $dot_file .dot)
    INFO "Generate: $BASENAME.png"
    dot $dot_file -Goverlap=false -Tpng -o $BASENAME.png
    INFO "Generate: $BASENAME.svg"
    dot $dot_file -Goverlap=false -Tsvg -o $BASENAME.svg
done

#!/bin/bash
################################################################################
# Global vars
export LAST
export TMP_FILE
declare -A RESULT_FILE
mtr_stat_count=16

################################################################################
# Define logging function
INFO(){ echo -n "INFO: "; echo "$@"; }
ERRO(){ echo -n "ERRO: "; echo -n "$@"; echo " Abort!"; exit 1; }

################################################################################
# Check deps
if [ ! -f "$(whereis -b dot | cut -d' ' -f2)" ]; then
    ERRO "dot binary are missing! Install graphviz!"
fi

if [ ! -f "$(whereis -b mtr | cut -d' ' -f2)" ]; then
    ERRO "mtr binary are missing! Install mtr!"
fi

################################################################################
# Parse args
for i in "$@"; do
    case $i in
        MAP_NAME=*) MAP_NAME="${i//MAP_NAME=/}" ;;
        HOSTS=*)    HOSTS="${i//HOSTS=/}"       ;;
    esac
done

[ -z "$MAP_NAME" ] && ERRO "Missing arg: MAP_NAME=<map_name>"
[ -z "$HOSTS" ] && ERRO "Missing arg: HOSTS=\"host1 host2...\""

################################################################################
# Initialization
RESULT_FILE[DOT]=$MAP_NAME
INFO "Result dot file: ${RESULT_FILE[DOT]}"
################################################################################
# Destination host for L3 Network map
hosts=( $HOSTS )

################################################################################
# Define some function
mtr_w(){
    DEST_HOST="$1"
    mtr -w -r -c $mtr_stat_count "$DEST_HOST" | \
        tail -n +3 | \
        awk '{print $1 $2}' | sed 's/.|--/|/g'
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
# main()
TMP_FILE=$(mktemp)

INFO "Gathering data"
for IP in "${hosts[@]}" ; do
    GEN_ROUTE_GRAPH $IP >> $TMP_FILE &
    sleep 0.1
    echo -n "$IP "
done

echo
INFO "Please wait for ~ $((mtr_stat_count*2))s"
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
BASENAME=$(basename ${RESULT_FILE[DOT]} .dot)
INFO "Generate: ${RESULT_FILE[DOT]}.png"
dot ${RESULT_FILE[DOT]} -Goverlap=false -Tpng -o ${RESULT_FILE[DOT]}.png
INFO "Generate: ${RESULT_FILE[DOT]}.svg"
dot ${RESULT_FILE[DOT]} -Goverlap=false -Tsvg -o ${RESULT_FILE[DOT]}.svg

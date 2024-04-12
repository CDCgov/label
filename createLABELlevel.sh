#!/bin/bash
# createLABELlevel.sh
# Sam Shepard - 2023

#### PARAMETERS one can adjsut ##########
P=8            #   parallel procs	    #
doAppend=0     #   whether to spike	    #
X=10           #   spike every X	    #
staticAppend=1 #   static appendix	    #
doHMM=1        #   generate HMMs	    #
rmGAP=1        #   remove Gap columns	#
#########################################
#########################################

# OS and ARCH
if [ -x "$(which uname)" ]; then
    OS=$(uname -s)
    if [ "$(uname -m)" != "x86_64" -a "$OS" == "Linux" ]; then
        OS="Linux32"
    fi
else
    OS="Linux"
fi

SELF=$(basename "$0" .sh)
# FNC - ERROR TEST #
# Idea courtesy: steve-parker.org/sh/exitcodes.shtml
function err_test() {
    local LN=$(($2 - 1))
    if [ "$1" -ne "0" ]; then
        echo "$SELF ERROR (line $LN): operations ABORTED!"
        exit 1
    fi
}

function warn() {
    local t=$(date +"%Y-%m-%d %k:%M:%S")
    echo -e "[$t] $SELF WARNING :: $1" 1>&2
    return 1
}

function die() {
    local t=$(date +"%Y-%m-%d %k:%M:%S")
    echo -e "[$t] $SELF ERROR :: $1" 1>&2
    exit 1
}

function check_prgm() {
    if (! hash "$1" > dev/null); then
        echo "$SELF ERROR: Program '$1' not found, please check your PATH or install it."
        exit 1
    fi
}

## Make sure program will run properly by getting resources ##
if (! hash LABEL); then
    echo "$SELF ERROR: LABEL not found, install or make sure it is in your PATH."
    exit 1
fi
LABEL=$(which LABEL)
spath=$(dirname "$LABEL")/LABEL_RES/scripts
tnpath=$(dirname "$LABEL")/LABEL_RES/training_data
cpath=$(dirname "$LABEL")/LABEL_RES/scripts/creation
modelfromalign="$spath"/modelfromalign_$OS
hmmscore="$spath"/hmmscore_$OS
shogun="$spath"/shogun_$OS

# need jot or seq
if (hash jot > /dev/null 2>&1); then
    enum=$(which jot)
elif (hash seq > /dev/null); then
    enum=$(which seq)
else
    check_prgm jot
fi

if [ ! -d "$cpath" ]; then
    echo "$SELF ERROR: please move the 'creation' folder to: $cpath"
    exit 1
fi

[ -z "$testrun" ] && testrun=$2
[ $# -ne 4 -a $# -ne 5 ] && echo -e "Usage:\n\t$0 <full-set> <module> <training-set-sizes:'# # #'> <max-reps> [path]\n" && exit 0
[ ! -r "$1" ] && echo -e "$SELF ERROR: file '$1' not found." && exit 1
[ ! "$4" -gt "0" ] && echo -e "$SELF ERROR: reps $4 must be > 0." && exit 1

ppath=$(cd "$(dirname "$1")" && pwd -P)
mod=$2
reps=$4

alvl_file="$ppath"/$(basename "$1")
alvl_hmm_file=$alvl_file
if [ -r "$ppath/$(basename "$1" .fasta).hmm.fasta" ]; then
    alvl_hmm_file="$ppath/$(basename "$1" .fasta).hmm.fasta"
    echo -e "Using $alvl_hmm_file for HMMs but $alvl_file for the SVM."
fi

qscript=$ppath/level.tmp.sh
appendix="$ppath"/${testrun}_appendix.txt
cd "$ppath" || die "Bad $ppath"

[ -r "$appendix" -a "$staticAppend" -eq "0" ] && rm "$appendix"
if [ $# -eq 5 ]; then
    linpath=/$mod/$5
    tpath=$tnpath/$mod/$5
    mpath=$tpath
    group=$5
else
    linpath=/$mod
    tpath=$tnpath/$mod
    mpath=$tpath
    group=$mod
fi

# CLUSTERING options
USE_QSUB=0
USE_BSUB=0

if (hash qsub > /dev/null); then
    USE_QSUB=1
    USE_BSUB=0
    QINDEX=SGE_TASK_ID
elif (hash bsub > /dev/null); then
    USE_BSUB=1
    USE_QSUB=0
    QINDEX=LSB_JOBINDEX
fi
### TO TURN OFF CLUSTER OPTIONS, uncomment below
#USE_BSUB=0
#USE_QSUB=0

function doCleanUp() {
    rm "${taxa[@]/%/.dist}" null.dist 2> /dev/null
    rm "$tpath/"*fasta 2> /dev/null
    rm "$ppath/${mod}_IDs.dat"
    [ "$use_xrev" -eq "1" ] && rm "$tpath/x-rev"/*fasta
}

function sweep() {
    local n=$1
    local r=$2
    local files=(
        "$ppath"/"${testrun}"_result.txt
        "$ppath/${mod}_K${n}-${r}_training.dat"
        "$ppath/${mod}_K${n}-${r}_info.dat"
        "$ppath/${mod}_K${n}-${r}_labels.dat"
        "$ppath/${mod}_K${n}-${r}_classifier.dat"
        "$ppath"/"${testrun}"_false.tmp
        "$ppath/${mod}_${testrun}.tab"
        "$ppath/${mod}_${testrun}.tab.tmp"
        "$ppath/${testrun}_result.txt"
        "$ppath/${testrun}_result.tab"
    )

    for f in "${files[@]}"; do
        [ -r "$f" ] && rm "$f"
    done
}

function checkpoint() {
    if [ ! -d "$tpath" ]; then
        echo -e "$SELF ERROR: '$tpath' does not exist.\n"
        exit 1
    else
        local n=$1
        local r=$2
        mv "$ppath"/"${testrun}"_result.txt "$ppath"/"${mod}"_best_result.txt
        mv "$ppath/${mod}_K${n}-${r}_training.dat" "$tpath/training.dat"
        mv "$ppath/${mod}_K${n}-${r}_info.dat" "$tpath/info.dat"
        mv "$ppath/${mod}_K${n}-${r}_labels.dat" "$tpath/labels.dat"
        #mv "$ppath/${mod}_K${n}-${r}_classifier.dat" "$tpath/classifier.dat"
        mv "$ppath/classifier.dat" "$tpath/classifier.dat"

    fi
}

if [ ! -d "$tpath" ]; then
    echo "$SELF WARNING: cannot find '$tpath'"
    echo "$SELF WARNING: create path [1 or 2]?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes)
                mkdir -p "$tpath"
                break
                ;;
            No) exit ;;
        esac
    done
fi

# Create HMMs
banlist=$ppath/level_banlist.txt
use_xrev=0
if [ "$doHMM" -eq "1" ]; then
    if [ -r "$banlist" ]; then
        "$spath"/fastaExtractor.pl -R -A "$alvl_hmm_file" "$banlist" > "$alvl_file.tmp.fasta" \
            && [ "$rmGAP" -eq "1" ] && "$spath"/removeGapColumns.pl "$alvl_file.tmp.fasta" \
            || die "Extraction and/or gap removal failed."
        "$spath"/partitionTaxa.pl "$alvl_file.tmp.fasta" "$tpath" \
            || die "Partioning by taxa failed."
    else
        [ "$rmGAP" -eq "1" ] && "$spath"/removeGapColumns.pl "$alvl_hmm_file" \
            && "$spath"/partitionTaxa.pl "$alvl_hmm_file" "$tpath" \
            || die "Gap removal and/or partitioning failed."
    fi

    rm "$tpath"/*_hmm.mod 2> /dev/null
    size=$(grep '>' "$alvl_file" -c)
    if [ -r "null.fasta" ]; then
        $modelfromalign null -alignfile "$ppath"/null.fasta -alphabet DNA 2> /dev/null \
            && rm "$ppath"/null.weightoutput \
            && mv "$ppath"/null.mod "$tpath" \
            || die "ModelfromAlign failed for custom null"
        echo "$SELF: using custom null model"
    else
        if [ -r "$tpath/null.mod" ]; then
            rm "$tpath"/null.mod
        fi

        if [ -d "$ppath/x-rev" -o -d "$mpath/x-rev" ]; then
            use_xrev=1
            [ ! -d "$ppath"/x-rev ] && mkdir "$ppath"/x-rev
            [ ! -d "$mpath"/x-rev ] && mkdir "$mpath"/x-rev
            echo "$SELF: using viterbi custom reverse corrected null model."
        else
            echo "$SELF: using reverse corrected null model."
        fi
    fi

    echo "$SELF: generating pHMMs"
    if test -n "$(
        shopt -s nullglob
        echo "$tpath"/*fasta
    )"; then
        for f in "$tpath"/*fasta; do
            m=$(basename "$f" .fasta)_hmm
            taxa=("${taxa[@]}" "$m")
            [ "$rmGAP" -eq "1" ] && "$spath/removeGapColumns.pl" "$f"
            $modelfromalign "$m" -alignfile "$f" -alphabet DNA 2> /dev/null \
                && rm "$m.weightoutput" \
                && mv "$m.mod" "$tpath" \
                || die "ModelfromAlign failed for '$f'"
        done
    else
        ls "$tpath"
        die "A 'level.fasta' is expected but found the above."
    fi

    if [ "$use_xrev" -eq "1" ]; then
        echo "$SELF: generating reverse pHMMs"
        cd x-rev || die "cd failed: $LINENO"
        for f in "$tpath"/*fasta; do
            f2=$tpath/x-rev/$(basename "$f" .fasta).rev.fasta
            "$cpath"/rev.pl -R "$f" > "$f2"
            m=$(basename "$f" .fasta)_hmm
            #taxa=(${taxa[@]} $m)
            [ "$rmGAP" -eq "1" ] && "$spath"/removeGapColumns.pl "$f2"
            $modelfromalign "$m" -alignfile "$f2" -alphabet DNA 2> /dev/null
            rm "$m".weightoutput
            mv "$m".mod "$tpath"/x-rev
        done
        cd - || die "cd failed: $LINENO"
    fi
else
    for f in "$tpath"/*mod; do
        m=$(basename "$f" .mod)
        taxa=("${taxa[@]}" "$m")
    done
fi

# Optimize training set
max_correct=0
bestK=0
bestR=0
takeLog=1

# create a training table if one doesn't already exists (heavy computation)
table="$ppath"/${mod}_fullset.tab
if [ ! -r "$table" ]; then
    N=$(grep '>' "$alvl_file" -c)
    if [ "$N" -gt 5000 ]; then
        g=50
    else
        g=$((N / 100 + 1))
    fi

    M=${#taxa[@]}
    [ "$use_xrev" -eq "1" ] && M=$((M * 2))
    A=$((M * g))
    [ "$A" -gt 1000 ] && g=$((1001 / M + 1))

    "$spath"/interleavedSamples.pl -X tmpp -G "$g" "$alvl_file" leaf > /dev/null 2>&1
    cat > "$qscript" << EOL
#!/bin/bash
LANG=POSIX
shopt -u nocaseglob;shopt -u nocasematch
ID=\$(expr \$$QINDEX - 1)
m=\$(expr \$ID / $g)
i=\$(expr \$ID % $g + 1)
l=\$(printf %04d \$i)
cd $ppath
db=$ppath/leaf_\${l}.tmpp
EOL
    chmod 755 "$qscript"

    # if special null models
    if [ -r "$mpath"/null.mod ]; then
        declare -a mods=("$mpath/null.mod" "$mpath"/*hmm.mod)
        cat >> "$qscript" << EOL
declare -a mods=($mpath/null.mod $mpath/*hmm.mod)
run=\$(basename \${mods[\$m]} .mod)_\$l
$hmmscore \$run -db \$db -modelfile \${mods[\$m]} -subtract_null 0
EOL
    elif [ -d "$mpath"/x-rev ]; then
        [ ! -d "$ppath"/x-rev ] && mkdir "$ppath"/x-rev
        declare -a mods=("$mpath"/*hmm.mod "$mpath/x-rev"/*hmm.mod)
        cat >> "$qscript" << EOL
declare -a mods=($mpath/*hmm.mod $mpath/x-rev/*hmm.mod)
pat=\$(dirname \${mods[\$m]});pat=\$(basename \$pat);[[ "\$pat" == "x-rev" ]] && cd x-rev
run=\$(basename \${mods[\$m]} .mod)_\$l
$hmmscore \$run -db \$db -modelfile \${mods[\$m]} -subtract_null 1 -dpstyle 1
EOL
    else
        declare -a mods=("$mpath"/*hmm.mod)
        cat >> "$qscript" << EOL
declare -a mods=($mpath/*hmm.mod)
run=\$(basename \${mods[\$m]} .mod)_\$l
$hmmscore \$run -db \$db -modelfile \${mods[\$m]}
EOL
    fi

    a=$((g * ${#mods[@]}))
    if [ $USE_QSUB -eq "1" ]; then
        echo "$SELF: scoring data via qsub"
        qsub -t 1-"$a":1 -sync y -j y -o "$qscript".o "$qscript"
    elif [ $USE_BSUB -eq "1" ]; then
        echo "$SELF: scoring data via bsub"
        bsub -K -J TRAINlvl[1-"$a"] -o "$qscript".o "$qscript" > "$ppath/$group.bsub.stdout"
    else
        echo "$SELF: scoring data via sub-processes"
        rm "$qscript"
        cd "$ppath" || die "Cannot cd to $ppath: $LINENO"
        for ID in $($enum "$a"); do
            ID=$((ID - 1))
            m=$((ID / g))
            l=$(printf %04d $((ID % g + 1)))
            db=$ppath/leaf_${l}.tmpp
            run=$(basename "${mods[$m]}" .mod)_$l

            # shellcheck disable=2207
            joblist=($(jobs -p))
            while ((${#joblist[@]} >= P)); do
                sleep 0.5

                # shellcheck disable=2207
                joblist=($(jobs -p))
            done
            $hmmscore "$run" -db "$db" -modelfile "${mods[$m]}" > /dev/null 2>&1 &
        done
        wait
    fi

    for m in "${mods[@]}"; do
        run=$(basename "$m" .mod)
        "$spath"/parseScores.pl "$ppath"/"${run}"_????.dist > "$ppath"/"$run".tab
        [ -d "$ppath"/x-rev ] && "$spath"/parseScores.pl "$ppath"/x-rev/"${run}"_????.dist > "$ppath"/x-rev/"$run".tab
    done

    # clean-up
    rm "$ppath"/*_hmm_????.dist "$ppath"/*.tmpp "$ppath"/null_????.dist > /dev/null 2>&1
    [ -d "$ppath"/x-rev ] && rm "$ppath"/x-rev/*dist

    # build training matrix
    if [ -r "$tpath/null.mod" ]; then
        "$spath"/buildDataMatrix.pl -F 4 "$table" "${taxa[@]/%/.tab}" -N null.tab
        err_test $? $LINENO
    elif [ "$use_xrev" -eq "1" ]; then
        "$spath"/buildDataMatrix.pl -F 3 "$table" "${taxa[@]/%/.tab}" -C "$ppath"/x-rev
        err_test $? $LINENO
    else
        "$spath"/buildDataMatrix.pl -F 4 "$table" "${taxa[@]/%/.tab}"
        err_test $? $LINENO
    fi
else
    size=$(wc -l < "$table")
    size=$((size - 1))
    echo "$SELF: scoring table found"
fi

# start training log
[ "$takeLog" -eq "1" ] && date > "${mod}.log"

# for goodness statistics
totPerfect=0
sumCorrect=0
totExecuted=0

#create GROUP
echo "$SELF: calculating optimal training set"
if [ -r "${table}.test" ]; then
    "$cpath"/randomTrainingSet.pl "${table}".test . -E -I -P "${mod}"
    size=$(wc -l < "${table}".test)
    size=$((size - 1))
    mv "${mod}"_training.dat "${mod}"_test.dat
elif [ ! -r "${mod}_test.dat" ] || [ ! -r "${mod}_IDs.dat" ]; then
    "$cpath"/randomTrainingSet.pl "$table" . -E -I -P "${mod}"
    size=$(wc -l < "${mod}"_IDs.dat)
    mv "${mod}"_training.dat "${mod}"_test.dat
else
    size=$(wc -l < "${mod}"_IDs.dat)
    echo "$SELF: test data already found"
fi

echo -e "ID\tMod\tT-Size\tRep\tTP\tTotal\tLin path" > "$ppath/${mod}_SV.txt"
echo -e "Mod\tT-Size\tRep\tTP\tTotal\tLin path"
for n in $3; do
    for r in $($enum "$reps"); do
        info="$ppath"/${mod}_K${n}-${r}_info.dat
        labels="$ppath"/${mod}_K${n}-${r}_labels.dat
        training="$ppath"/${mod}_K${n}-${r}_training.dat
        myLog="$ppath"/${mod}.log

        "$cpath"/randomTrainingSet.pl "$table" . -S "$n" -D -P "${mod}"_K"${n}"-"${r}" -A "$appendix" \
            && "$cpath"/doSVM.pl "$group" "$ppath"/"${mod}"_test.dat "$ppath"/"${mod}"_IDs.dat "$ppath"/"${mod}"_"${testrun}".tab "$training" "$labels" "$shogun" \
            && "$cpath"/lineageResults.pl "$info" "$group" "$ppath"/"${mod}"_"${testrun}".tab "$ppath"/"$testrun" "$mod" \
            && correct=$("$spath"/evaluateResults.pl -T -H -S "$ppath"/"${testrun}"_result.txt) \
            && "$cpath"/parseInfo.pl "$info" "$mod" "$n" "$r" "$correct" "$size" "$linpath" >> "$ppath"/"${mod}"_SV.txt \
            || die "Failure at $mod-$n-$r"

        echo -e "$mod\t$n\t$r\t$correct\t$size\t$linpath"
        if [ "$takeLog" -eq "1" ]; then
            echo -e "$mod\t$n\t$r\t$correct\t$size\t$linpath" >> "$myLog"
            "$spath"/evaluateResults.pl -H "$ppath"/"${testrun}"_result.txt >> "$myLog"
        fi

        [ -z "$correct" ] && echo "$SELF ERROR: could not train or test module." && exit 1
        "$spath"/evaluateResults.pl -J "$ppath"/"${testrun}"_result.tab >> "$ppath"/"${testrun}"_false.tmp
        modulo=$((r % X))
        if [ $modulo -eq "0" -a $doAppend -eq "1" ]; then
            if [ -s "$appendix" -a "$((max_correct - correct))" -gt "$n" ]; then
                rm "$appendix" "$ppath"/"${testrun}"_false.tmp
            else
                sort "$ppath/${testrun}_false.tmp" | uniq -c | grep -P "^\s+$X\s" >> "$myLog"
                sort "$ppath/${testrun}_false.tmp" | uniq -c | grep -P "^\s+$X\s" | awk -F' ' '{print $(NF)}' >> "$appendix"
                rm "$ppath/${testrun}_false.tmp"
            fi
        fi

        if [ "$correct" -gt "$max_correct" ]; then
            max_correct=$correct
            bestK=$n
            bestR=$r
            checkpoint "$bestK" "$bestR"
            if [ "$correct" -eq "$size" ]; then
                doAppend=0
            fi
        fi

        if [ "$correct" -eq "$size" ]; then
            totPerfect=$((totPerfect + 1))
        fi
        totExecuted=$((totExecuted + 1))
        sumCorrect=$((sumCorrect + correct))

        sweep "$n" "$r"
    done
done
doCleanUp

echo -e "Best:\t$bestK\t$bestR\t$max_correct\t$size"
echo -e "Perfect:\t$totPerfect of $totExecuted"
echo -e "Avg. cor:\t$((sumCorrect / totExecuted)) of $size"

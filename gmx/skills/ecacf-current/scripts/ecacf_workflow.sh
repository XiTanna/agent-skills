#!/bin/bash
# Charge-current (ECACF input) workflow for a bulk electrolyte case:
#   <casedir>/<T>K/{npt.gro,topol.top,index.ndx,FF/}  ->  5 annealed NPT runs -> 10 frames each -> 50 NVT runs that write the
#   current on the fly (onfly_ecacf.dat) -> collected files + box lengths.
#
#   ecacf_workflow.sh manycase        <casedir> <T>              create ecacf/manycase/case1..5 (annealing peaks $PEAKS)
#   ecacf_workflow.sh submit-manycase <casedir>                  sbatch the 5 NPT runs
#   ecacf_workflow.sh frames          <casedir> <T>              extract $NFRAMES frames at <T> from each finished NPT run
#   ecacf_workflow.sh runcase         <casedir> <T> "<groups>"   create ecacf/runcase/case1..N and sbatch them (DRYRUN=1: create only; ONLY="1 2": subset)
#   ecacf_workflow.sh collect         <casedir>                  ecacf/all_ecacf/onfly_ecacf-caseK.dat + ecacf/box_length.txt
#
# <groups> = index group names of the species whose current is wanted, exactly as in index.ndx (case-sensitive), e.g. "Zn otf".
# Environment:
#   ACCOUNT, PARTITION, GMX_SETUP   Slurm account / partition / shell line(s) loading a plain GROMACS (manycase NPT jobs, GPU)
#   ONFLY_SETUP                     shell line(s) putting the on-the-fly gmx first on PATH (runcase jobs)
#   ECACF_PARTITION, ECACF_CONSTRAINT (optional)   partition / node constraint for the runcase jobs (default PARTITION / none)
#   GET_FRAMES                      path of the frame-extraction tool (usage: -i prefix -t T -n num -o outdir; needs prefix.tpr/.trr/.edr)
#   PEAKS (default "320 340 360 380 400"), NFRAMES (default 10)
# Templates come from ../assets; a file of the same name in <casedir>/ecacf/ takes precedence.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd); ASSETS=$HERE/../assets
PEAKS=${PEAKS:-"320 340 360 380 400"}; NFRAMES=${NFRAMES:-10}
cmd=${1:-}; CD=${2:-}
[ -n "$cmd" ] && [ -d "$CD" ] || { sed -n 2,22p "$0"; exit 1; }
CD=$(cd "$CD" && pwd); EC=$CD/ecacf; NAME=$(basename "$CD")
mkdir -p "$EC"
pick() { [ -f "$EC/$1" ] && echo "$EC/$1" || echo "$ASSETS/$1"; }
read -ra peaks <<< "$PEAKS"; NCASE=${#peaks[@]}

# fill a job template: $1 template  $2 output  $3 jobname  $4 partition  $5 constraint-line  $6 env-lines  $7 groups
mkjob() {
  sed "s/^#SBATCH --job-name=.*/#SBATCH --job-name=$3/; s/^#SBATCH -A .*/#SBATCH -A ${ACCOUNT:?set ACCOUNT}/; s/^#SBATCH -p .*/#SBATCH -p $4/; s/#SEL#/$7/" "$1" > "$2.tmp"
  CON="$5" ENVL="$6" awk '{ if ($0=="#CONSTRAINT#") { if (ENVIRON["CON"]!="") print "#SBATCH --constraint=" ENVIRON["CON"] } else if ($0=="#GMX_ENV_SETUP#") print ENVIRON["ENVL"]; else print }' "$2.tmp" > "$2" && rm -f "$2.tmp"
}

case "$cmd" in
manycase)
  T=${3:?temperature}; S=$CD/${T}K
  for f in npt.gro topol.top index.ndx FF; do [ -e "$S/$f" ] || { echo "missing $S/$f"; exit 1; }; done
  for i in $(seq 1 $NCASE); do
    d=$EC/manycase/case$i; [ -e "$d" ] && { echo "case$i exists, skip"; continue; }
    mkdir -p "$d"; cp -r "$S/FF" "$S/topol.top" "$S/index.ndx" "$S/npt.gro" "$d/"
    sed "s/@T@/$T/g; s/@PEAK@/${peaks[$((i-1))]}/g" "$(pick manycase_npt.mdp)" > "$d/grompp.mdp"
    echo "manycase/case$i: anneal $T -> ${peaks[$((i-1))]} -> $T K"
  done ;;
submit-manycase)
  : "${PARTITION:?set PARTITION}" "${GMX_SETUP:?set GMX_SETUP}"
  for i in $(seq 1 $NCASE); do d=$EC/manycase/case$i
    mkjob "$(pick gmx_manycase.job)" "$d/gmx.job" "$NAME-ecacf-manycase$i" "$PARTITION" "" "$GMX_SETUP" ""
    (cd "$d" && sbatch gmx.job)
  done ;;
frames)
  T=${3:?temperature}; : "${GET_FRAMES:?set GET_FRAMES}"
  for i in $(seq 1 $NCASE); do d=$EC/manycase/case$i; o=$EC/initialframes-case$i
    for e in tpr trr edr; do [ -f "$d/npt1.$e" ] || { echo "case$i: npt1.$e missing (run finished?)"; continue 2; }; done
    mkdir -p "$o"; (cd "$d" && "$GET_FRAMES" -i npt1 -o "$o" -t "$T" -n "$NFRAMES" > "$o/get_frames.log" 2>&1)
    echo "case$i: $(ls "$o"/frame*.gro 2>/dev/null | wc -l) frames"
  done ;;
runcase)
  T=${3:?temperature}; SEL=${4:?index groups, e.g. \"Zn otf\"}
  : "${PARTITION:?set PARTITION}" "${ONFLY_SETUP:?set ONFLY_SETUP}"
  for g in $SEL; do grep -q "^\[ *$g *\]" "$EC/manycase/case1/index.ndx" || { echo "group '$g' not in index.ndx (names are case-sensitive):"; grep '^\[' "$EC/manycase/case1/index.ndx" | tr '\n' ' '; echo; exit 1; }; done
  k=0; made=0
  for i in $(seq 1 $NCASE); do for j in $(seq 1 $NFRAMES); do
    k=$((k+1)); [ -n "${ONLY:-}" ] && [[ " $ONLY " != *" $k "* ]] && continue
    fr=$EC/initialframes-case$i/frame$j.gro; [ -f "$fr" ] || { echo "missing $fr, skipped"; continue; }
    d=$EC/runcase/case$k; mkdir -p "$d"
    cp "$fr" "$d/start.gro"; cp "$EC/manycase/case$i/index.ndx" "$EC/manycase/case$i/topol.top" "$d/"; cp -r "$EC/manycase/case$i/FF" "$d/"
    sed "s/@T@/$T/g" "$(pick ecacf_nvt.mdp)" > "$d/grompp.mdp"
    mkjob "$(pick gmx_ecacf.job)" "$d/gmx.job" "$NAME-ecacf-$k" "${ECACF_PARTITION:-$PARTITION}" "${ECACF_CONSTRAINT:-}" "$ONFLY_SETUP" "$(echo $SEL | sed 's/ /,/g; s/,/ /g')"
    [ "${DRYRUN:-0}" = 1 ] || (cd "$d" && sbatch gmx.job)
    made=$((made+1)); sleep 0.2
  done; done
  echo "runcase: $made run folders created in $EC/runcase" ;;
collect)
  mkdir -p "$EC/all_ecacf"; : > "$EC/box_length.txt"
  exp=$(awk '/^ *nsteps/{n=$3} /^ *userint1/{u=$3} END{if(u>0) print int(n/u)}' "$(pick ecacf_nvt.mdp)")
  for d in $(ls -d "$EC"/runcase/case* | sort -V); do k=${d##*case}
    [ -f "$d/onfly_ecacf.dat" ] || { echo "case$k: no onfly_ecacf.dat"; continue; }
    n=$(wc -l < "$d/onfly_ecacf.dat"); [ "$n" = "$exp" ] || echo "case$k: $n lines (expected $exp, unfinished?)"
    cp "$d/onfly_ecacf.dat" "$EC/all_ecacf/onfly_ecacf-case$k.dat"; echo "$k $(tail -n 1 "$d/start.gro" | awk '{print $1}')" >> "$EC/box_length.txt"
  done
  echo "collected $(ls "$EC/all_ecacf" | wc -l) files" ;;
*) sed -n 2,22p "$0"; exit 1 ;;
esac

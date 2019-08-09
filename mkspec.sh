#!/bin/sh

set -eu

temp=`mktemp`

myriad_version=1
minion_version=1
cronos_version=1

get_font_version() {
    otfinfo --info $1 | awk '/^Version/ { split($3,a,";"); print a[1] }'
}

while [ $# -gt 0 ]; do
    key=$1

    case $key in
        --cronos-otf)
            cronos_version="`get_font_version $2`"
            shift;shift
            ;;
        --myriad-otf)
            myriad_version="`get_font_version $2`"
            shift;shift
            ;;
        --minion-otf)
            minion_version="`get_font_version $2`"
            shift;shift
            ;;
    esac
done

cleanup() {
    rm "$temp"
}

trap cleanup EXIT HUP TERM KILL

sed_script() {
    font=$1
    tag=$2
    version=$3
    echo -n "s~\\\$\\\$\\\$${tag}_PROVIDES\\\$\\\$\\\$~" >> $temp
    for f in `find ${font} -type f`; do
        echo -n "Provides: tex(`basename $f`) = %{tl_version}\\n"
    done >> $temp
    echo "~g;" >> $temp
    echo -n "s~\\\$\\\$\\\$${tag}_VERSION\\\$\\\$\\\$~${version}~g;" >> $temp

}

sed_script cronos CRONOS $cronos_version
sed_script myriad MYRIAD $myriad_version
sed_script minion MINION $minion_version
sed -f $temp texlive-fontpro.spec.template > texlive-fontpro.spec

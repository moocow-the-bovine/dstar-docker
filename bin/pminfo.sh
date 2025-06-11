#!/bin/bash

pminfo() {
    mod="$1";
    echo "## MODULE: $mod"

    file=`echo "$mod" | perl -pe 's{::}{/}g;'`.pm;
    pkgs=`apt-file search "$file"`;

    perlwhich.perl "$mod";
    perlmodversion.perl "$mod";

    if test -n "$pkgs" -a $(echo "$pkgs" | wc -l) = 1  ; then
	    echo "Versions: "
	    apt-show-versions -a $pkgs ;
    else
	    echo "Packages:" `echo "$pkgs" | cut -d':' -f1`
    fi
    echo ""
}

for m in "$@" ; do
    pminfo "$m"
done

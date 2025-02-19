#!/usr/bin/env sh

rm -rf ./dict.new
mkdir -p ./dict.new

for l in BR DA EN ES FR PL SV CZ DE EN FI NO RU UK; do
    [ "$l" = "EN" ] && l=EN.footer || l=$l.dict
    find "./n56u_ribbon_fixed" -type f -name "*" \
        | xargs grep -Eho "<#.+#>" \
        | sed "s/#>/#>\n/g; s/<#/\n<#/g" \
        | grep "^<#" \
        | tr -d "[#<]" | tr ">" "=" \
        | cat - ./dict/$l \
        | sed '/^\[/d; /^"/d; s/^#//g' \
        | sort -V | uniq \
        | awk ' NR > 1 { if ( index($0, prev) == 1 ) { prev = $0; next } }
            { print prev; prev = $0 }
            END { if (NR>0) print prev } ' \
        | sed -E 's/(^.*=$)/#\1/' \
        | sort -V \
        > ./dict.new/$l
done

echo "LANG_EN=English" > ./dict.new/EN.header

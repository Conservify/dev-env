#!/bin/bash

main_only=1
folder=""
if [ ! -z $1 ]; then
    cd $1
    folder=`basename $1`
fi

temp_file=$(mktemp)

git for-each-ref --format="%(refname) %(refname:short) %(upstream:short)" refs/ | \
while read name local remote
do
    if [[ $name == refs/tags* ]]; then
        continue
    fi

    if [[ $local == origin* ]]; then
        continue
    fi

    if [ -x $remote ]; then
        branches=("$local")
    else
        branches=("$local" "$remote")
    fi

    git update-index -q --refresh
    CHANGED=$(git diff-index --name-only HEAD --)

    mods=""
    if ! git diff-index --quiet HEAD --; then
        mods=" MODIFICATIONS"
    fi

    for branch in ${branches[@]}; do
        main="origin/main"
        if [ $branch == $main ]; then
            continue
        fi
        if [ $main_only == 1 ]; then
            if [ $branch != "main" ]; then
                continue
            fi
        fi
        git rev-list --left-right ${branch}...${main} -- 2>/dev/null >${temp_file} || continue
        LEFT_AHEAD=$(grep -c '^<' ${temp_file})
        RIGHT_AHEAD=$(grep -c '^>' ${temp_file})
        printf "%s (ahead %s) | (behind %s) %s %-16s%s\n" $branch $LEFT_AHEAD $RIGHT_AHEAD $main $folder $mods
    done
done

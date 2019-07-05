#!/usr/bin/env bash

set -e

REPOS=$1

if [[ -z "$1" ]]; then
    REPOS=$(ls src/)
fi

TARGET_BRANCH=master

echo "Update code to latest"
echo "> git pull --no-edit"
git pull --no-edit

echo "Will pushed projects:"
echo ${REPOS}

# git subtree push --prefix=src/annotation git@github.com:swoft-cloud/swoft-annotation.git master --squash
# git subtree push --prefix=src/stdlib stdlib master
for lbName in ${REPOS} ; do
    echo ""
    echo "======> Push the project:【${lbName}】"
    echo "> git subtree push --prefix=src/${lbName} ${lbName} ${TARGET_BRANCH} --squash"
    git subtree push --prefix=src/${lbName} ${lbName} ${TARGET_BRANCH} --squash
done

echo ""
echo "Push Completed!"

#!/bin/sh
yarn stdver

yarn build

git remote add github https://$GITHUB_TOKEN@github.com/quixoter/dialog-tree-checkbox.git > /dev/null 2>&1
git push github HEAD:master --follow-tags


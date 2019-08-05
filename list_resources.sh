#!/bin/sh

cd `dirname $0`
git branch
echo $target_branch
echo $source_branch
git branch -a
echo "+++++++++++++++++++++++"
for file in `ls ./specs`; do
	work_dir=./specs/$file
	if [ -d $work_dir ]; then
		if [ -n "$(git diff --name-only $target_branch $source_branch -- $work_dir)" ];
		then
			# remove the directory prefix './specs/'
			expr substr "$work_dir" 9 "${#work_dir}"
		fi
	fi
done

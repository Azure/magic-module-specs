#!/bin/sh

cd `dirname $0`
for file in `ls ./specs`; do
	work_dir=./specs/$file
	if [ -d $work_dir ]; then
		if [ -n "$(git status -s $work_dir)" ];
		then
			# remove the directory prefix './specs/'
			expr substr "$work_dir" 9 "${#work_dir}"
		fi
	fi
done

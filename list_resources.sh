#!/bin/sh

findResourceDir(){
	for file in `ls $1`
	do
		work_dir=$1"/"$file
		if [ -d $work_dir ]
		then
			if [ -n "$(git status -s $work_dir)" ] && [ -f $work_dir"/api.yaml" ] \
				&& ([ -f $work_dir"/ansible.yaml" ] || [ -f $work_dir"/terraform.yaml" ]);
			then
				# remove the directory prefix './specs'
				expr substr "$work_dir" 9 "${#work_dir}"
			fi
			# find resource directory recursively
			findResourceDir $work_dir
		fi
	done
}

cd `dirname $0`
specs_dir='./specs'
findResourceDir $specs_dir
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
				# remove the directory prefix
				expr substr "$work_dir" `expr $prefix_len + $slash_len` "${#work_dir}"
			fi
			# find resource directory recursively
			findResourceDir $work_dir
		fi
	done
}

prefix_len=${#1}
slash_len=2
findResourceDir $1
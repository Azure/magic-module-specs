#!/bin/bash
specs_dir="./specs"

function findResourceDir(){
    for file in `ls $1`
    do
    	work_dir=$1"/"$file
        if [ -d $work_dir ]
        then
        	if [ -n "$(git status -s $work_dir)" ] && [ -f $work_dir"/api.yaml" ] \
        		&& ([ -f $work_dir"/ansible.yaml" ] || [ -f $work_dir"/terraform.yaml" ]); then
				echo ${work_dir:8}		# remove the directory prefix './specs/'
			fi
            findResourceDir $work_dir	# find resource directory recursively
        fi
    done
}

findResourceDir $specs_dir
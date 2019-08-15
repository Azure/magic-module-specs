#!/bin/sh

cd $(dirname $0)

# If Running Locally
source_branch=$1
target_branch=master
if [ -z "$source_branch" ]; then
	current_branch=$(git branch | grep '*')
	source_branch="$(expr substr "$current_branch" 3 "${#current_branch}")"
fi

# If Running in Pipeline
if [ -z "$(git branch | grep -E '[^/]'$source_branch)" ] || [ -z "$(git branch | grep -E '[^/]'$target_branch)" ]; then
	source_branch=remotes/origin/$source_branch
	target_branch=remotes/origin/$target_branch
fi

# List Resource Directories
for file in $(ls ./specs); do
	work_dir=./specs/$file
	if [ -d $work_dir ]; then
		if [ -f $work_dir"/api.yaml" ] && ([ -f $work_dir"/ansible.yaml" ] || [ -f $work_dir"/terraform.yaml" ]); then
			if [ -n "$(git diff --name-only $target_branch $source_branch -- $work_dir)" ]; then
				# remove the directory prefix './specs/'
				expr substr "$work_dir" 9 "${#work_dir}"
			fi
		fi
	fi
done

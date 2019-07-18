#!/bin/bash
specs_dir="./specs/"
for resource in $(ls $specs_dir); do
	if [ -d $specs_dir/$resource ] && [ -n "$(git status -s $specs_dir/$resource)" ]; then
		echo $resource
	fi
done
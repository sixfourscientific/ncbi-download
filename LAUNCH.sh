#!/usr/bin/env bash

REPO_DIR=$(dirname $(realpath "$0"))

$REPO_DIR/LaunchWorkflow.sh \
	-s local \
	-p defaults \
	-x all \
	-i $REPO_DIR/pipeline/inputs/test/SampleInfoTest.tsv $@



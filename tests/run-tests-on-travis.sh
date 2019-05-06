#!/bin/bash
set -e

cd ./tests

test_name=$1
echo "# Running ${test_name}"
bash "./${test_name}.sh"

cd ..

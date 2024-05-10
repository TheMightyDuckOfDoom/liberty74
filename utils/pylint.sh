# !/bin/bash

# Copyright 2024 Tobias Senti
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

set +e
pylint $1

exitcode=$?
if [ $exitcode -eq 0 ]; then
    echo "Pylint passed successfully"
elif [ $exitcode -eq 4 ]; then
    echo "Pylint produced a warning"
else
    echo "Pylint failed"
    exit 1
fi

exit 0

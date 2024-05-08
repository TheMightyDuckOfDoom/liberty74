# !/bin/bash

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

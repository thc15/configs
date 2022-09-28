#!/bin/bash
#
# Note: this script is for CI only.
#       Use pytest directly if you want to run your test case manually.
#
set -xe

# ====== Global variables ===== #
TESTSUITE_DEFAULT_SPEED=100000
TESTSUITE_DEFAULT_AUTONEG=off
TESTSUITE_DEFAULT_FEC=rs
# ============================= #

DIR=`dirname $0`
DIR=`realpath $DIR`

usage() { echo "Usage: $0 [-m <markers>] [-j <path to junit xml directory>] [-r <report path>] [-i <nb iterations>] [-e] [-l] [-s]" 1>&2; exit 1; }

match_marker() { [[ "$marker" =~ .*"$1".* ]] && [[ ! "$marker" =~ .*"not $1".* ]]; }

declare -a markers=()
email=""
iterations="1"
loopback=""
no_ssh=""
serial=""
serial_baudrate=""
skip_itf_search=""
unstable=false
while getopts "m:j:i:r:v:d:b:elsfu" o; do
    case "${o}" in
        m) # pytest markers to select or not select
            markers+=("${OPTARG}")
            ;;
        j) # junit xml path
            junitxml="--junitxml=${OPTARG}"
            ;;
        i) # number of iterations (for the acceptance only)
            iterations="${OPTARG}"
            ;;
        e) # send email
            email="--email"
            ;;
        r) # report path
            report_path="${OPTARG}"
            ;;
        v) # vmlinux path
            vmlinux="${OPTARG}"
            ;;
        l) # loopback mode
            loopback="--loopback"
            ;;
        s) # send commands through serial port instead of ssh
            no_ssh="--no-ssh"
            ;;
        f) # skip interface searching
            skip_itf_search="--skip-itf-search"
            ;;
        d) # specification of the serial port
            serial="--serial=${OPTARG}"
            ;;
        b) # specification of the baudrate to apply on serial port
            serial_baudrate="--serial-baudrate=${OPTARG}"
            ;;
	u) # mark test as UNSTABLE if one fails
	    unstable=true
	    ;;
        *)
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${junitxml+x}" ] || [ -z "${report_path+x}" ] || [ -z "${vmlinux+x}" ] || [ ${#array[@]} -gt 0 ]
then
    echo "The arguments -j, -r and -v are mandatory !"
    usage
fi

echo "Checking for missing dependencies..."
cd "$DIR/"
pipenv sync

declare -a pytest_ret=() # return code of each pytest run
i=0

# start pytest with each marker given as argument
for marker in "${markers[@]}"
do
    pytest_args="--config=$DIR/config.yml $junitxml/ethernet_pytest_$i.xml $loopback $no_ssh $skip_itf_search $serial $serial_baudrate"
    i=$((i+1))

    # we must have either 'acceptance' or 'testsuite' word in our marker string
    if ! match_marker "acceptance" && ! match_marker "testsuite"
    then
        echo "The marker string must contain the word acceptance or testsuite"
        exit 1
    fi

    # init yaml config file
    {
        echo "version: 0.1"
        echo "vmlinux: $vmlinux"
        echo "report-path: $report_path"
        echo "no-interaction: True"
    } > $DIR/config.yml

    if match_marker "acceptance"
    then
        pytest_args="$pytest_args $email"
        {
            echo "acceptance-db: $report_path/acceptance.db" # used to test the database-related code
            echo "release: 4.8" # release does not matter in CI, it is only for testing database
            echo "iterations: $iterations"
        } >> $DIR/config.yml
    fi
    if match_marker "testsuite"
    then
        # by default (if the marker is absent), the link is required
        if match_marker "link_required" || [[ ! "$marker" =~ .*link_required.* ]]
        then
            {
                echo "test-parameters:"
                echo "  - autoneg: '$TESTSUITE_DEFAULT_AUTONEG'"
                echo "    speed:"
                echo "      host: $TESTSUITE_DEFAULT_SPEED"
                echo "      mppa: $TESTSUITE_DEFAULT_SPEED"
                echo "    fec: '$TESTSUITE_DEFAULT_FEC'"
            } >> $DIR/config.yml
        else
            echo "test-parameters: []" >> $DIR/config.yml
        fi
    fi

    cd "$DIR/"
    pipenv run pytest -m "$marker" $pytest_args `realpath $DIR`/ && pytest_ret+=(0) || pytest_ret+=($?)
done

# exit code = max of all exit codes collected
#
# For information, pytest exit codes:
# 0: All tests were collected and passed successfully
# 1: Tests were collected and run but some of the tests failed
# 2: Test execution was interrupted by the user
# 3: Internal error happened while executing tests
# 4: pytest command line usage error
# 5: No tests were collected

# by exiting with 0, tests that failed will be marked as unstable in Jenkins
[ $unstable = true ] && exit 0

max=0
for ret in "${pytest_ret[@]}"
do
    (( ret > max )) && max=$ret
done
exit $max

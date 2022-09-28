Final Report Generation
=======================

Once the acceptance is finished, the final report can be generated using the :command:`gen_final_report.py` script.
This script will generate a temporary file containing the report in `Remarkup` format.

Ethernet acceptance reports are usually stored on Phabricator: https://phab.kalray.eu/w/ethernet/acceptance-results/

The report is composed of 4 sections :
  1. test many k200 with the same configuration
  2. test one single k200 with various configurations
  3. a color-coded summary of the previous section
  4. comparison of the results between enmppa0 and enmppa4
  5. comparison of the results between different k200 types
  6. comparison of the results with the previous release


Usage
~~~~~

.. code-block:: bash

  ➜ python3 gen_final_report.py --help
  usage: gen_final_report.py [-h] -d ACCEPTANCE_DB -f DATA -r RELEASE
                             [-p PREVIOUS_RELEASE]

  optional arguments:
    -h, --help            show this help message and exit
    -d ACCEPTANCE_DB, --acceptance-db ACCEPTANCE_DB
                          Path to the acceptance Sqlite database
    -f DATA, --data DATA  Path of the root where all the data, logs etc is
                          stored
    -r RELEASE, --release RELEASE
                          Linux release. e.g. 4.6
    -p PREVIOUS_RELEASE, --previous-release PREVIOUS_RELEASE
                          previous Linux release to compare with. e.g. 4.5

The argument :command:`-d` is the path to the Sqlite database of the acceptance. The argument :command:`-f` is used to generate 
the paths to the logs. :command:`-r` refers to the release being tested and :command:`-r` is the previous release to compare with.

Example
~~~~~~~

.. code-block:: bash

  source venv/bin/activate
  python gen_final_report.py -d /work2/common/valid_ethernet/acceptance_data/acceptance_data.db -f /work2/common/valid_ethernet/acceptance_data/ -r 4.6 -p 4.5
  [+] Done.
  [+] Final report was generated successfully : /tmp/tmp4en88oeb

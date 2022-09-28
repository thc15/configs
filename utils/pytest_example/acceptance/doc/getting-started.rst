Getting Started
===============

Before starting the acceptance, we must ensure the following prerequisites are met:

1. the Linux binary image of the release for the board
2. all the hardware is available : k200 boards, link partners and cables


The Linux image
----------------

The Linux image can be retrieved from the linux coolidge repository. 
The first step, if not already done, is to clone the repository. Instructions can be found on the Linux wiki:

https://phab.kalray.eu/w/coolidge/linux_buildroot/

in the section "I don't have anything ! Where do I start ?".

The vmlinux image that has to be used for the acceptance is located in the workspace directory:

  workspace/kEnv/kvxtools/opt/kalray/linux/kv3-1/share/linux_bin/conf_mppa/vmlinux


Installation
-------------
If not already done, some packages need to be installed in order to access the TTY of the board.
The following commands must be executed inside `linux_toolchain_coolidge` directory.

.. code-block:: bash

  find workspace/packages/ -name "*rules*" -exec cp {} /tmp \;
  sudo dpkg -i /tmp/*rules*.deb


Network Setups
--------------

The acceptance has to be performed with two different network setups:

  1. the two ethernet interfaces of the k200 are directly connected to the network interface card (NIC) using two cables
  2. a switch serves as an intermediary between the k200 and the workstation. At least 2 cables are necessary
     in this case (one between the workstation and the switch, and the other one between the switch and the k200).


Hardware
--------

The minimum hardware needed is:

  1. ethernet cables from different vendors (Mellanox, Cisco, Finisar, etc.). There must be at least one copper and one fiber 
     cable for each vendor. Having different product numbers for each vendor is nice to have. 
  2. NICs from different vendors (Mellanox, Intel, Broadcom, Chelsio). 
  3. ethernet switches from different vendors (Mellanox and Cisco).
  4. at least two k200, but it is nice to have each model and version (k200lp, k200 rev2...).


The Acceptance Script
---------------------

The acceptance scripts are located in the `linux_valid` submodule:

  ./linux_valid/ethernet_pytest/

Make sure to have the latest version by pulling the latest commits from coolidge branch (`git pull -r origin coolidge`).


Python Dependencies
-------------------

Run the following commands to install Python dependencies for pytest.

.. code-block:: bash

  # create a virtual environment
  export VENV_PATH=venv # to change
  python3 -m venv $VENV_PATH # it creates a folder venv/ in the current directory
  # optional but useful : add the source of kvx env to activate both at the same time
  sed -i "1s|^|source <path to linux_toolchain_coolidge>/workspace/kEnv/kvxtool/.switch_env\n|" $VENV_PATH/bin/activate
  # source the venv
  source $VENV_PATH/bin/activate
  # update pip (mandatory otherwise it will fail)
  pip install --upgrade pip
  # install dependencies with pip
  pip install -r requirements.txt

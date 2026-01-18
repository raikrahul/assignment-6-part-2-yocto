#!/bin/bash
# Script to build image for qemu.
# Author: Siddhant Jajoo.

git submodule init
git submodule sync
git submodule update

# local.conf won't exist until this step on first execution
source poky/oe-init-build-env

CONFLINE="MACHINE = \"qemuarm64\""

cat conf/local.conf | grep "${CONFLINE}" > /dev/null
local_conf_info=$?

if [ $local_conf_info -ne 0 ];then
	echo "Append ${CONFLINE} in the local.conf file"
	echo ${CONFLINE} >> conf/local.conf
	
else
	echo "${CONFLINE} already exists in the local.conf file"
fi

bitbake-layers show-layers | grep "meta-aesd" > /dev/null
layer_info=$?

if [ $layer_info -ne 0 ];then
	echo "Adding meta-aesd layer"
	bitbake-layers add-layer ../meta-aesd
else
	echo "meta-aesd layer already exists"
fi



# Force update if exists, append if not
if [ -f conf/local.conf ]; then
    sed -i 's/BB_NUMBER_THREADS = .*/BB_NUMBER_THREADS = "6"/' conf/local.conf
    sed -i 's/PARALLEL_MAKE = .*/PARALLEL_MAKE = "-j 6"/' conf/local.conf
    if ! grep -q "rm_work" conf/local.conf; then
        echo 'INHERIT += "rm_work"' >> conf/local.conf
    fi
fi

set -e

# Cleanup any stale bitbake server or locks from previous hard crash
if [ -f bitbake.lock ]; then
    echo "Found stale lock, cleaning up..."
    rm -f bitbake.lock
fi

# Surgical clean of corrupted OpenSSL state from previous crash
# We do this to ensure No 'undefined reference' errors in linking
bitbake -c cleansstate openssl

# Final build
bitbake core-image-aesd

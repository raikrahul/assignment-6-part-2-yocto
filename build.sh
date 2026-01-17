#!/bin/bash
# Script to build image for qemu.
# Author: Siddhant Jajoo.

git submodule init
git submodule sync
git submodule update

# local.conf won't exist until this step on first execution
source poky/oe-init-build-env /home/r/Desktop/linux-sysprog-buildroot/assignment6/part2/build

CONFLINE="MACHINE = \"qemuarm64\""

cat conf/local.conf | grep "${CONFLINE}" > /dev/null
local_conf_info=$?

if [ $local_conf_info -ne 0 ];then
        echo "Append ${CONFLINE} in the local.conf file"
        echo ${CONFLINE} >> conf/local.conf
else
        echo "${CONFLINE} already exists in the local.conf file"
fi

# Performance Optimization: Auto-detect cores
NPROC=$(nproc)
echo "Configuring build for $NPROC cores..."

# Add BB_NUMBER_THREADS
CONFLINE="BB_NUMBER_THREADS = \"$NPROC\""
if ! grep -q "BB_NUMBER_THREADS" conf/local.conf; then
        echo "Append ${CONFLINE} in the local.conf file"
        echo ${CONFLINE} >> conf/local.conf
fi

# Add PARALLEL_MAKE
CONFLINE="PARALLEL_MAKE = \"-j $NPROC\""
if ! grep -q "PARALLEL_MAKE" conf/local.conf; then
        echo "Append ${CONFLINE} in the local.conf file"
        echo ${CONFLINE} >> conf/local.conf
fi

# Add rm_work (Disk Space Optimization)
CONFLINE="INHERIT += \"rm_work\""
if ! grep -q "rm_work" conf/local.conf; then
        echo "Append ${CONFLINE} in the local.conf file"
        echo ${CONFLINE} >> conf/local.conf
fi

# Enable Yocto Project Shared State Cache (CRITICAL for fast builds)
CONFLINE="BB_HASHSERVE_UPSTREAM = \"hashserv.yoctoproject.org:8686\""
if ! grep -q "BB_HASHSERVE_UPSTREAM" conf/local.conf; then
        echo "Append ${CONFLINE} in the local.conf file"
        echo ${CONFLINE} >> conf/local.conf
fi

CONFLINE='SSTATE_MIRRORS ?= "file://.* http://sstate.yoctoproject.org/all/PATH;downloadfilename=PATH"'
if ! grep -q "sstate.yoctoproject.org" conf/local.conf; then
        echo "Append ${CONFLINE} in the local.conf file"
        echo ${CONFLINE} >> conf/local.conf
fi

# Enable hash equivalence for better cache reuse
CONFLINE="BB_HASHSERVE = \"auto\""
if ! grep -q "BB_HASHSERVE = " conf/local.conf; then
        echo "Append ${CONFLINE} in the local.conf file"
        echo ${CONFLINE} >> conf/local.conf
fi

CONFLINE="BB_SIGNATURE_HANDLER = \"OEEquivHash\""
if ! grep -q "BB_SIGNATURE_HANDLER" conf/local.conf; then
        echo "Append ${CONFLINE} in the local.conf file"
        echo ${CONFLINE} >> conf/local.conf
fi

bitbake-layers show-layers | grep "meta-aesd" > /dev/null
layer_info=$?

if [ $layer_info -ne 0 ];then
        echo "Adding meta-aesd layer"
        bitbake-layers add-layer ../meta-aesd
else
        echo "meta-aesd layer already exists"
fi

set -e
bitbake core-image-aesd

# Disable network isolation to avoid permission errors
CONFLINE="BB_NO_NETWORK = \"0\""
if ! grep -q "BB_NO_NETWORK" conf/local.conf; then
        echo "Append ${CONFLINE} in the local.conf file"
        echo ${CONFLINE} >> conf/local.conf
fi

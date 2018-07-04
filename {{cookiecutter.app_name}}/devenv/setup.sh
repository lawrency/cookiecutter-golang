#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


set -e
set -x

# Install WARNING before we start provisioning so that it
# will remain active.  We will remove the warning after
# success
SCRIPT_DIR="$(readlink -f "$(dirname "$0")")"
cat "$SCRIPT_DIR/failure-motd.in" >> /etc/motd

# finally, remove our warning so the user knows this was successful
rm /etc/motd

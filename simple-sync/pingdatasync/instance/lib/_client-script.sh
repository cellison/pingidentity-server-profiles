#!/bin/sh
#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License, Version 1.0 only
# (the "License").  You may not use this file except in compliance
# with the License.
#
# You can obtain a copy of the license at
# trunk/ds/resource/legal-notices/cddl.txt
# or http://www.opensource.org/licenses/cddl1.php.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at
# trunk/ds/resource/legal-notices/cddl.txt.  If applicable,
# add the following below this CDDL HEADER, with the fields enclosed
# by brackets "[]" replaced with your own identifying information:
#      Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
#
#      Portions Copyright 2007-2023 Ping Identity Corporation
#      Portions Copyright 2006-2008 Sun Microsystems, Inc.


# This script is used to invoke various client-side processes.  It should not
# be invoked directly by end users.
if test -z "${UNBOUNDID_INVOKE_CLASS}"
then
  echo "ERROR:  UNBOUNDID_INVOKE_CLASS environment variable is not set."
  exit 1
fi


# Capture the current working directory so that we can change to it later.
# Then capture the location of this script and the server instance
# root so that we can use them to create appropriate paths.
WORKING_DIR=$(pwd)

cd "$(dirname "${0}")" || exit
# shellcheck disable=SC2034
SCRIPT_DIR=$(pwd)

cd ..
INSTANCE_ROOT=$(pwd)
export INSTANCE_ROOT

UNBOUNDID_TOOL_PROPERTIES_FILE_PATH="${INSTANCE_ROOT}/config/tools.properties"
export UNBOUNDID_TOOL_PROPERTIES_FILE_PATH

cd "${WORKING_DIR}" || exit


# Set environment variables
SCRIPT_UTIL_CMD=set-full-environment
export SCRIPT_UTIL_CMD
# shellcheck disable=SC1090
.  "${INSTANCE_ROOT}/lib/_script-util.sh"
RETURN_CODE=$?
if test ${RETURN_CODE} -ne 0
then
  exit ${RETURN_CODE}
fi

# Launch the appropriate client utility.
if test -z "${PRIVATE_UNBOUNDID_LOGGC_ARG}"
then
  # shellcheck disable=SC2086
  "${PRIVATE_UNBOUNDID_JAVA_BIN}" ${PRIVATE_UNBOUNDID_JAVA_ARGS} ${SCRIPT_NAME_ARG} "${UNBOUNDID_INVOKE_CLASS}" "${@}"
else
  # shellcheck disable=SC2086
  "${PRIVATE_UNBOUNDID_JAVA_BIN}" ${PRIVATE_UNBOUNDID_JAVA_ARGS} "${PRIVATE_UNBOUNDID_LOGGC_ARG}" ${SCRIPT_NAME_ARG} "${UNBOUNDID_INVOKE_CLASS}" "${@}"
fi

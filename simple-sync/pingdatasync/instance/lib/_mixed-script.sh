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
#      Portions Copyright 2008-2023 Ping Identity Corporation
#      Portions Copyright 2008 Sun Microsystems, Inc.


# This script is used to invoke processes that might be run on server or
# in client mode (depending on the state of the server and the arguments
# passed).  It should not be invoked directly by end users.
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

cd "${WORKING_DIR}" || exit

OLD_SCRIPT_NAME=${SCRIPT_NAME}
SCRIPT_NAME=${OLD_SCRIPT_NAME}.online
export SCRIPT_NAME

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

MUST_CALL_AGAIN="false"

SCRIPT_NAME_ARG=-Dcom.unboundid.directory.server.scriptName=${OLD_SCRIPT_NAME}
export SCRIPT_NAME_ARG

# Check whether is local or remote
# shellcheck disable=SC2086
"${PRIVATE_UNBOUNDID_JAVA_BIN}" ${PRIVATE_UNBOUNDID_JAVA_ARGS} ${SCRIPT_NAME_ARG} "${UNBOUNDID_INVOKE_CLASS}" \
     --configClass com.unboundid.directory.server.extensions.ConfigFileHandler \
     --configFile "${INSTANCE_ROOT}/config/config.ldif" --quiet --testIfOffline "${@}"
EC=${?}
if test ${EC} -eq 51
then
  # Set the environment to use the offline properties
  SCRIPT_NAME=${OLD_SCRIPT_NAME}.offline
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  .  "${INSTANCE_ROOT}/lib/_script-util.sh"
  RETURN_CODE=$?
  if test ${RETURN_CODE} -ne 0
  then
    exit ${RETURN_CODE}
  fi
  MUST_CALL_AGAIN="true"
else
  if test ${EC} -eq 52
  then
    MUST_CALL_AGAIN="true"
  else
    # This is likely a problem with the provided arguments.
    exit ${EC}
  fi
fi

if test ${MUST_CALL_AGAIN} = "true"
then
  SCRIPT_NAME_ARG=-Dcom.unboundid.directory.server.scriptName=${OLD_SCRIPT_NAME}
  export SCRIPT_NAME_ARG

  # Launch the server utility.
  if test -z "${PRIVATE_UNBOUNDID_LOGGC_ARG}"
  then
    # shellcheck disable=SC2086
    "${PRIVATE_UNBOUNDID_JAVA_BIN}" ${PRIVATE_UNBOUNDID_JAVA_ARGS} \
         ${SCRIPT_NAME_ARG} "${UNBOUNDID_INVOKE_CLASS}" \
         --configClass com.unboundid.directory.server.extensions.ConfigFileHandler \
         --configFile "${INSTANCE_ROOT}/config/config.ldif" "${@}"
  else
    # shellcheck disable=SC2086
    "${PRIVATE_UNBOUNDID_JAVA_BIN}" ${PRIVATE_UNBOUNDID_JAVA_ARGS} \
         "${PRIVATE_UNBOUNDID_LOGGC_ARG}" ${SCRIPT_NAME_ARG} "${UNBOUNDID_INVOKE_CLASS}" \
         --configClass com.unboundid.directory.server.extensions.ConfigFileHandler \
         --configFile "${INSTANCE_ROOT}/config/config.ldif" "${@}"
  fi
fi

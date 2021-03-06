#!/bin/sh
# Copyright (c) 2008-2018 LG Electronics, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

PUB_SERVICES=
PRV_SERVICES=

find_names() {
    NEEDS_LOOKUP=
    MATCH=
    SERVICES="$1"
    
    #echo "SERVICES: ${SERVICES}"

    for i in $SERVICES ; do
        #echo "Checking ${i}"
        echo ${i} | grep -q "com.*"

        if [ $? -eq 0 ] ; then
            #echo "match: ${i}"
            MATCH="${MATCH} ${i}"
        else
            #echo "no: ${i}"
            NEEDS_LOOKUP="${NEEDS_LOOKUP} ${i}"
        fi
    done

    for i in $NEEDS_LOOKUP ; do
        #echo "Lookup: ${i}"
        TMP=`grep -r "#define.*${i}" * --exclude-dir=.svn | sed "s/.*#define.*${i} *\(.*\)/\1/"`
        MATCH="${MATCH} ${TMP}"
    done

    for i in $MATCH ; do
        echo ${i} | sed 's/"\(.*\)"/\1/'
    done
}

create_service_file() {
    TYPE="$1"
    CUR_SERVICES="$2"
    EXTENSION="prv"
    CONCAT=
    PERMS=

    if [ "x${CUR_SERVICES}" = "x" ] ; then
        return
    fi

    if [ "x${TYPE}" = "xpub" ] ; then
        EXTENSION="pub"
    fi

    FILE="your-service.json.${EXTENSION}"

    for i in ${CUR_SERVICES} ; do
        if [ "x${CONCAT}" = "x" ] ; then
        CONCAT="\"${i}\""
PERMS="{
            \"service\":\"${i}\",
            \"inbound\":[\"*\"],
            \"outbound\":[\"*\"]
        }"
        else
        CONCAT="${CONCAT}, \"${i}\""
PERMS="${PERMS},
        {
            \"service\":\"${i}\",
            \"inbound\":[\"*\"],
            \"outbound\":[\"*\"]
        }"
        fi
    done

    RESULT="{
    \"role\": {
        \"exeName\":\"/path/to/my/binary\",
        \"type\": \"regular\",
        \"allowedNames\": [${CONCAT}]
    },
    \"permissions\": [
        ${PERMS}
    ]
}"

    echo "$RESULT" > ${FILE}
}

PUB_TMP=`grep -rn "LSRegisterPubPriv *([^,]*,[^,]*, *true *,\|LSRegisterPalmService *(" * --exclude-dir=.svn | sed 's/.*LSRegister.*(\([^,]*\).*/\1/' | grep "[A-Za-z.].*" | sort | uniq | grep -v NULL`

PRV_TMP=`grep -rn "LSRegister *(\|LSRegisterPubPriv *([^,]*,[^,]*, *false *,\|LSRegisterPalmService *(" * --exclude-dir=.svn | sed 's/.*LSRegister.*(\([^,]*\).*/\1/' | grep "[A-Za-z.].*" | sort | uniq | grep -v NULL`

PUB_SERVICES=$(find_names "${PUB_TMP}")
PRV_SERVICES=$(find_names "${PRV_TMP}")

echo "PRV_SERVICES:"
echo "${PRV_SERVICES}"

echo "PUB_SERVICES:"
echo "${PUB_SERVICES}"

create_service_file "pub" "${PUB_SERVICES}"
create_service_file "prv" "${PRV_SERVICES}"

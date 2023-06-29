#! /bin/bash
#
# Copyright (C) 2023 Xiaomi Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

REPO_ROOT=$(realpath $(dirname $(realpath $0))/../../../)
readonly KEY_PATH=$REPO_ROOT/frameworks/ota/tools/keys
readonly TOOL_PATH=$REPO_ROOT/external/avb/avb
readonly AVBTOOL=$TOOL_PATH/avbtool
readonly DEFAULT_KEY=$KEY_PATH/key.pem
readonly DEFAULT_ALG=SHA256_RSA2048
readonly SUPPORTED_ALG=(SHA256_RSA2048 SHA256_RSA4096 SHA256_RSA8192 \
                        SHA512_RSA2048 SHA512_RSA4096 SHA512_RSA8192)

readonly KSIZE=1024
readonly PF_FLAG="_"
readonly PF_STR="vela"
readonly PREFIX=${PF_STR}${PF_FLAG}
readonly SF_FLAG="."
readonly SF_STR="bin"
readonly SURFIX=${SF_FLAG}${SF_STR}

_help(){
  printf "  %-16s   %s\n" "${1}" "${2}"
}
__help(){
  printf "      %-12s   %s\n" "${1}" "${2}"
}
help(){
  echo -e "Usage: $0 <image2sign> <partition_size>" \
          "[options]\n"
  _help "<image2sign>" "Image path, eg: ./${PREFIX}ota${SURFIX}"
  __help "Prefix" $PREFIX
  __help "Surfix" $SURFIX
  _help "<partition_size>" "Partition size (*$KSIZE)"
  echo -e "\nOptions:"
  _help "[-a algorithm]" "Algorithm of sign, ${DEFAULT_ALG} by default"
  printf "      %-12s   %s" "Supported" && echo "${SUPPORTED_ALG[@]}"
  _help "[-k key_path]" "Path of private key, ${DEFAULT_KEY} by default"
  _help "[-o options]" "Option(s) append to avbtool"
  __help "--padding_ff" "Padding 0xff for DO_NOT_CARE area"
  exit 1
}
check_e(){
  if [ ! -e $1 ] ; then echo "($1) not exists" ; help ; fi
}

fatal(){
  echo -e "FATAL: $@"
  exit 2
}
printvar(){
  [[ $# -lt 2 ]] \
    && printf "%-16s : %s\n" $1 ${!1} \
    || printf "%-$((16 - ${#2}))s (%s) : %s\n" $1 $2 ${!1}
}

# Check Tool
if ! $AVBTOOL --help >/dev/null ; then
  fatal "Tool ($AVBTOOL) check failed"
fi

# Parse & Check ARGs
[[ $# -lt 2 ]] && help
IMAGE2SIGN=$1
PARTITION_SIZE=$(($2 * $KSIZE)) # KB -> B # TODO : Get from partition table
shift; shift
while getopts "k:a:o:" opt ; do
  case $opt in
    k)
      IN_PRIVKEY=$OPTARG
      ;;
    a)
      ALGORITHM=$OPTARG
      ;;
    o)
      OPTIONS=(${OPTIONS[@]} $OPTARG)
      ;;
    ?)
      help
      ;;
    esac
done
IN_PRIVKEY=${IN_PRIVKEY:-$DEFAULT_KEY}
ALGORITHM=${ALGORITHM:-$DEFAULT_ALG}

check_e $IMAGE2SIGN
check_e $IN_PRIVKEY
if ! echo ${SUPPORTED_ALG[@]} | grep $ALGORITHM > /dev/null ; then
  fatal "Algorithm Supported: ${SUPPORTED_ALG[@]}"
fi

# Parse & Check Partition Name
NAME_PARTITION=$(basename $IMAGE2SIGN)
[[ "${NAME_PARTITION%%${PF_FLAG}*}x" == "${PF_STR}x" ]] \
  && NAME_PARTITION=${NAME_PARTITION##${PREFIX}} \
  || fatal "prefix ($NAME_PARTITION)"
[[ "${NAME_PARTITION##*${SF_FLAG}}x" == "${SF_STR}x" ]] \
  && NAME_PARTITION=${NAME_PARTITION%%${SURFIX}} \
  || fatal "surfix ($NAME_PARTITION)"
readonly DEV_PATH=/dev/$NAME_PARTITION

# Info
printvar IMAGE2SIGN
printvar PARTITION_SIZE "bytes"
printvar DEV_PATH
printvar IN_PRIVKEY
printvar ALGORITHM
[[ ${#OPTIONS[@]} -gt 0 ]] && printf "%-16s : " OPTIONS && echo "${OPTIONS[@]}"

# Sign
$AVBTOOL add_hash_footer --image $IMAGE2SIGN \
        --partition_size $PARTITION_SIZE \
        --partition_name $DEV_PATH \
        --key $IN_PRIVKEY --algorithm $ALGORITHM ${OPTIONS[@]}

echo -e "Result: \e[1;37mSUCC\e[0m"
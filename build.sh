#! /bin/bash

export SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function usage()
{
   printf "\tUsage: %s \n\t[Build Option -o <Debug|Release|RelWithDebInfo|MinSizeRel>] \n\t[CoreSymbolName -s <1-7 characters>] \n\t[Avoid Compiling -a]\n\n" "$0" 1>&2
   exit 1
}

RED='\033[0;31m'
NC='\033[0m'

export DISK_MIN=10
export TEMP_DIR="/tmp"

if [ "${SOURCE_DIR}" == "${PWD}" ]; then
   BUILD_DIR="${PWD}/build"
else
   BUILD_DIR="${PWD}"
fi
CMAKE_BUILD_TYPE=Release
CORE_SYMBOL_NAME="SYS"
START_MAKE=true

if [ $# -ne 0 ]; then
   while getopts ":o:s:ah" opt; do
      case "${opt}" in
         o )
            options=( "Debug" "Release" "RelWithDebInfo" "MinSizeRel" )
            if [[ "${options[*]}" =~ "${OPTARG}" ]]; then
               CMAKE_BUILD_TYPE="${OPTARG}"
            else
               printf "\n\tInvalid argument: %s\n" "${OPTARG}" 1>&2
               usage
               exit 1
            fi
         ;;
         s)
            if [ "${#OPTARG}" -gt 6 ] || [ -z "${#OPTARG}" ]; then
               printf "\n\tInvalid argument: %s\n" "${OPTARG}" 1>&2
               usage
               exit 1
            else
               CORE_SYMBOL_NAME="${OPTARG}"
            fi
         ;;
         a)
            START_MAKE=false
         ;;
         h)
            usage
            exit 1
         ;;
         \? )
            printf "\n\tInvalid Option: %s\n" "-${OPTARG}" 1>&2
            usage
            exit 1
         ;;
         : )
            printf "\n\tInvalid Option: %s requires an argument.\n" "-${OPTARG}" 1>&2
            usage
            exit 1
         ;;
         * )
            usage
            exit 1
         ;;
      esac
   done
fi

printf "\t=========== Building eosio.wasmsdk ===========\n\n"

unamestr=`uname`
if [[ "${unamestr}" == 'Darwin' ]]; then
   BOOST=/usr/local
   CXX_COMPILER=g++
   export ARCH="Darwin"
   export BOOST_ROOT=${BOOST}
   bash "${SOURCE_DIR}/scripts/eosio_build_darwin.sh"
else
   BOOST=~/opt/boost
   OS_NAME=$( cat /etc/os-release | grep ^NAME | cut -d'=' -f2 | sed 's/\"//gI' )

   export BOOST_ROOT=${BOOST}
   case "$OS_NAME" in
      "Amazon Linux AMI")
         export ARCH="Amazon Linux AMI"
         bash "${SOURCE_DIR}/scripts/eosio_build_amazon.sh"
         ;;
      "CentOS Linux")
         export ARCH="Centos"
         bash "${SOURCE_DIR}/scripts/eosio_build_centos.sh"
         ;;
      "elementary OS")
         export ARCH="elementary OS"
         bash "${SOURCE_DIR}/scripts/eosio_build_ubuntu.sh"
         ;;
      "Fedora")
         export ARCH="Fedora"
         bash "${SOURCE_DIR}/scripts/eosio_build_fedora.sh"
         ;;
      "Linux Mint")
         export ARCH="Linux Mint"
         bash "${SOURCE_DIR}/scripts/eosio_build_ubuntu.sh"
         ;;
      "Ubuntu")
         export ARCH="Ubuntu"
         bash "${SOURCE_DIR}/scripts/eosio_build_ubuntu.sh"
         ;;
      *)
         printf "\n\tUnsupported Linux Distribution. Exiting now.\n\n"
         exit 1
   esac
fi

printf "\n\n>>>>>>>> ALL dependencies successfully found or installed. Installing eosio.wasmsdk\n\n"
printf ">>>>>>>> CMAKE_BUILD_TYPE=%s\n" "${CMAKE_BUILD_TYPE}"

CORES=`getconf _NPROCESSORS_ONLN`

if [ ! -d "${BUILD_DIR}" ]; then
   if ! mkdir -p "${BUILD_DIR}"
   then
      printf "Unable to create build directory %s.\\n Exiting now.\\n" "${BUILD_DIR}"
      exit 1;
   fi
fi

if ! pushd "${BUILD_DIR}" &> /dev/null
then
   printf "Unable to enter build directory %s.\\n Exiting now.\\n" "${BUILD_DIR}"
   exit 1;
fi

cmake -DBOOST_ROOT="${BOOST}" -DCORE_SYMBOL_NAME="${CORE_SYMBOL_NAME}" "${SOURCE_DIR}"

if [ "${START_MAKE}" == "false" ]; then
   printf "\n>>>>>>>> eosio.wasmsdk has been successfully configured but not yet built.\n\n"
   popd &> /dev/null
   exit 0
fi

make -j${CORES}

printf "\n>>>>>>>> eosio.wasmsdk has been successfully built.\n\n"
popd &> /dev/null

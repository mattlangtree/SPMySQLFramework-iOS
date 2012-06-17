#! /bin/ksh

#
#  $Id$
#
#  build-mysql-client.sh
#  sequel-pro
#
#  Created by Stuart Connolly (stuconnolly.com)
#  Copyright (c) 2009 Stuart Connolly. All rights reserved.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#  More info at <http://code.google.com/p/sequel-pro/>

#  Builds the MySQL client libraries for distrubution in Sequel Pro's MySQL framework.
#
#  Parameters: -s -- The path to the MySQL source directory.
#              -q -- Quiet. Don't output any compiler messages.
#              -c -- Clean the source instead of building it.
#              -d -- Debug. Output the build statements.

QUIET='NO'
DEBUG='NO'
CLEAN='NO'

# C/C++ compiler flags
export CFLAGS='-isysroot /Developer/SDKs/MacOSX10.5.sdk -arch ppc -arch i386 -arch x86_64 -O3 -fno-omit-frame-pointer -fno-exceptions -mmacosx-version-min=10.5'
export CXXFLAGS='-isysroot /Developer/SDKs/MacOSX10.5.sdk -arch ppc -arch i386 -arch x86_64 -O3 -fno-omit-frame-pointer -felide-constructors -fno-exceptions -fno-rtti -mmacosx-version-min=10.5'

CONFIGURE_OPTIONS='-DBUILD_CONFIG=mysql_release -DENABLED_LOCAL_INFILE=1 -DWITH_SSL=bundled -DWITH_MYSQLD_LDFLAGS="-all-static --disable-shared"'
OUTPUT_DIR='SPMySQLFiles.build'

set -A INCLUDE_HEADERS 'my_alloc.h' 'my_list.h' 'mysql_com.h' 'mysql_time.h' 'mysql_version.h' 'mysql.h' 'typelib.h'
ESC=`printf '\033'`

usage() 
{	
	cat <<!EOF
Usage: $(basename $0): -s <mysql_source_path> [-q -c -d]

Where: -s -- Path to the MySQL source directory
       -q -- Be quiet during the build. Suppress all compiler messages
       -c -- Clean the source directory instead of building
       -d -- Debug. Output all the build commands
!EOF
}

# Test for cmake
cmake --version > /dev/null 2>&1
if [ ! $? -eq 0 ]
then
	echo "$ESC[1;31mIn addition to the standard OS X build tools, '$ESC[0;1mcmake$ESC[1;31m' is required to compile the MySQL source.   $ESC[0;1mcmake$ESC[1;31m is found at $ESC[0mcmake.org$ESC[1;31m, and a binary distribution is available from $ESC[0mhttp://www.cmake.org/cmake/resources/software.mhtml$ESC[1;31m ."
	echo "Exiting...$ESC[0m"
	exit 1
fi

if [ $# -eq 0 ]
then
	echo "$ESC[1;31mInvalid number of arguments. I need the path to the MySQL source directory.$ESC[0m"
	echo ''
	usage
	exit 1
fi


while getopts ':s:qcd' OPTION
do
    case "$OPTION" in
        s) MYSQL_SOURCE_DIR="$OPTARG";;
		q) QUIET='YES';;
		c) CLEAN='YES';;
        d) DEBUG='YES';;
        *) echo "$ESC[1;31mUnrecognised option$ESC[0m"; usage; exit 1;;
    esac
done

if [ ! -d "$MYSQL_SOURCE_DIR" ]
then
	echo "$ESC[1;31mMySQL source directory does not exist at path '${MYSQL_SOURCE_DIR}'.$ESC[0m"
	echo "$ESC[1;31mExiting...$ESC[0m"
	exit 1
fi

# Change to source directory
if [ "x${DEBUG}" == 'xYES' ]
then
	echo "cd ${MYSQL_SOURCE_DIR}"
fi
cd "$MYSQL_SOURCE_DIR"

# Perform a clean if requested
if [ "x${CLEAN}" == 'xYES' ]
then
	echo "$ESC[1mCleaning MySQL source and builds...$ESC[0m"
	
	if [ "x${QUIET}" == 'xYES' ]
	then
		make clean > /dev/null
		if [ -f 'CMakeCache.txt' ]; then rm 'CMakeCache.txt' > /dev/null; fi
		if [ -d "$OUTPUT_DIR" ]; then rm -rf "$OUTPUT_DIR" > /dev/null; fi
	else
		make clean
		if [ -f 'CMakeCache.txt' ]; then rm 'CMakeCache.txt'; fi
		if [ -d "$OUTPUT_DIR" ]; then rm -rf "$OUTPUT_DIR" > /dev/null; fi
	fi

	echo "$ESC[1mCleaning MySQL completed.$ESC[0m"

	exit 0
fi 

echo ''
echo "This script builds the MySQL client libraries for distribution in Sequel Pro's MySQL framework."
echo 'They are all built as 3-way binaries (32 bit PPC, 32/64 bit i386).'
echo ''
echo -n "$ESC[1mThis may take a while, are you sure you want to continue [y | n]: $ESC[0m"

read CONTINUE

if [ "x${CONTINUE}" == 'xn' ]
then
	echo "$ESC[31mAborting...$ESC[0m"
	exit 0
fi


echo "$ESC[1mConfiguring MySQL source...$ESC[0m"

if [ "x${DEBUG}" == 'xYES' ]
then
	echo "cmake ${CONFIGURE_OPTIONS} ."
fi

if [ "x${QUIET}" == 'xYES' ]
then
	cmake $CONFIGURE_OPTIONS . > /dev/null
else
	cmake $CONFIGURE_OPTIONS .
fi

if [ $? -eq 0 ]
then
	echo "$ESC[1mConfigure successfully completed$ESC[0m"
else
	echo "$ESC[1;31mConfigure failed. Exiting...$ESC[0m"
	exit 1
fi

if [ "x${DEBUG}" == 'xYES' ]
then
	echo "make mysqlclient"
fi

echo "$ESC[1mBuilding client libraries...$ESC[0m"

if [ "x${QUIET}" == 'xYES' ]
then
	make mysqlclient > /dev/null
else
	make mysqlclient
fi

if [ $? -eq 0 ]
then
	echo "$ESC[1mBuilding libraries successfully completed$ESC[0m"
else
	echo "$ESC[1;31mBuilding libraries failed. Exiting...$ESC[0m"
	exit 1
fi

echo "$ESC[1mPutting together files for distribution...$ESC[0m"

# Create the appropriate directories
if [ ! -d "$OUTPUT_DIR" ]
then
	mkdir "$OUTPUT_DIR"
	if [ ! $? -eq 0 ]
	then
		echo "$ESC[1;31mCould not create $OUTPUT_DIR output directory!$ESC[0m"
		exit 1
	fi
fi
if [ ! -d "${OUTPUT_DIR}/lib" ]
then
	mkdir "${OUTPUT_DIR}/lib"
	if [ ! $? -eq 0 ]
	then
		echo "$ESC[1;31mCould not create ${OUTPUT_DIR}/lib output directory!$ESC[0m"
		exit 1
	fi
fi
if [ ! -d "${OUTPUT_DIR}/include" ]
then
	mkdir "${OUTPUT_DIR}/include"
	if [ ! $? -eq 0 ]
	then
		echo "$ESC[1;31mCould not create ${OUTPUT_DIR}/include output directory!$ESC[0m"
		exit 1
	fi
fi

# Copy the library
cp 'libmysql/libmysqlclient.a' "${OUTPUT_DIR}/lib/"
if [ ! $? -eq 0 ]
then
	echo "$ESC[1;31mCould not copy libmysqlclient.a to output directory! (${MYSQL_SOURCE_DIR}/${OUTPUT_DIR}/lib)$ESC[0m"
	exit 1
fi

# Copy in the required headers
for eachheader in ${INCLUDE_HEADERS[@]}
do
	cp "include/${eachheader}" "${OUTPUT_DIR}/include/"
	if [ ! $? -eq 0 ]
	then
		echo "$ESC[1;31mCould not copy ${eachheader} to output directory! (${MYSQL_SOURCE_DIR}/${OUTPUT_DIR}/include)$ESC[0m"
		exit 1
	fi
done
	

echo "$ESC[1mBuilding MySQL client libraries successfully completed.$ESC[0m"
echo "$ESC[1mSee ${MYSQL_SOURCE_DIR}/${OUTPUT_DIR}/ for the product.$ESC[0m"

exit 0

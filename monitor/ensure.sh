#!/bin/bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    monitor.sh -f [options ...] [fast5_dir] [fastq_dir] | ${SCRIPT_NAME} -f [format]
#%
#% DESCRIPTION
#%    Ensures corresponding fast5 and fastq files are created
#%    before printing fast5 filename.
#%
#% OPTIONS
#%    -f [format], --format=[format]                Follows a specified format of fast5 and fastq files
#%                                          
#%    available formats
#%        --778           [directory]               Old format that's not too bad
#%                        |-- fast5/
#%                            |-- [prefix].fast5.tar
#%                        |-- fastq/
#%                            |-- fastq_*.[prefix].fastq.gz
#%        
#%        --NA            [directory]               Newer format with terrible folders
#%                        |-- fast5/
#%                            |-- [prefix].fast5
#%                        |-- fastq/
#%                            |-- [prefix]/
#%                                |-- [prefix].fastq
#%
#%        --zebra         [directory]               Newest format
#%                        |-- fast5/
#%                            |-- [prefix].fast5
#%                        |-- fastq/
#%                            |-- [prefix].fastq 
#%                                                             
#%    -h, --help                                    Print help message
#%    -i, --info                                    Print script information
#%    -r, --resume                                  Check if dev files already contain any of the filenames
#%    --results-dir=[directory]                     Specify directory where results are from previous run.
#%                                                  Only used when resume option set.                           
#%
#================================================================
#- IMPLEMENTATION
#-    authors         Sasha JENNER (jenner.sasha@gmail.com)
#-    license         MIT
#-         
#-    Copyright (c) 2020 Sasha Jenner
#-
#-    Permission is hereby granted, free of charge, to any person obtaining a copy
#-    of this software and associated documentation files (the "Software"), to deal
#-    in the Software without restriction, including without limitation the rights
#-    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#-    copies of the Software, and to permit persons to whom the Software is
#-    furnished to do so, subject to the following conditions:
#-
#-    The above copyright notice and this permission notice shall be included in all
#-    copies or substantial portions of the Software.
#-
#-    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#-    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#-    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#-    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#-    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#-    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#-    SOFTWARE.
#-
#================================================================
# END_OF_HEADER
#================================================================

    #== Necessary variables ==#
SCRIPT_HEADSIZE=$(head -200 ${0} | grep -n "^# END_OF_HEADER" | cut -f1 -d:)
SCRIPT_NAME="$(basename ${0})"

    #== Usage functions ==#
usage() { printf "Usage: "; head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#+" | sed -e "s/^#+[ ]*//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }
usagefull() { head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#[%+-]" | sed -e "s/^#[%+-]//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }
scriptinfo() { head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#-" | sed -e "s/^#-//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }



    #== Default variables ==#

RESUME=false # Set resume option to false by default
format_specified=false # Assume no format specified
RESULTS_DIR="./" # Default current directory as the results directory

## Handle flags
while [ ! $# -eq 0 ]; do # While there are arguments
    case "$1" in

        -f)
			format_specified=true

			case "$2" in
				--778 | --NA | --zebra)
					FORMAT=$2
					;;

				*)
					echo "Incorrect or no format specified"
					usagefull
					exit 1
					;;
            esac
			shift
			;;

        --format=*)
            format_specified=true
            format="${1#*=}"

            case "$format" in
                --778 | --NA | --zebra)
                    FORMAT=$format
                    ;;

                *)
                    echo "Incorrect or no format specified"
                    usagefull
                    exit 1
                    ;;
            esac
            shift
            ;;

        --help | -h)
            usagefull
            exit 0
            ;;

        --info | -i)
            scriptinfo
            exit 0
            ;;

        --results-dir=*)
            RESULTS_DIR="${1#*=}"
            ;;

        --resume | -r)
            RESUME=true
            ;;

    esac
    shift
done

if ! $format_specified; then # Exit if no format specified
	echo "No format specified!"
	usagefull
	exit 1
fi



    #== Begin ==#

file_list=() # Declare file list

# Initialise counters
i_new=0
i_old=0

# Colour codes for printing
YELLOW="\e[33m"
RED="\e[31m"
NORMAL="\033[0;39m"

if [ "$FORMAT" = "--778" ]; then

    while read filename; do

        if [ "$filename" = "-1" ]; then # Exit if -1 flag sent
            >&2 echo "[ensure.sh] exiting"
            exit 0
        fi

        parent_dir=${filename%/*} # Strip filename from .fast5.tar filepath
        grandparent_dir=${parent_dir%/*} # Strip parent directory from filepath
        pathless=$(basename $filename) # Strip path
        temp_prefix=${pathless%.*} # Remove one extension
        prefix=${temp_prefix%.*} # Extract the filename without the path or extension (remove 2nd extension)

        if echo $filename | grep -q \\.fast5\\.tar; then # If it is a fast5 file

            if $RESUME; then # If resume option set
                grep -q /$prefix\\.fast5\\.tar$ "$RESULTS_DIR"/dev*.cfg # Check if filename exists in config files
                
                if [ $? -eq "0" ]; then # If the file has been processed
                    ((i_old ++))
                    >&2 echo -e $RED"old file ($i_old): $filename"$NORMAL
                    continue # Wait for next input
                    
                else # Else it is new
                    ((i_new ++))
                    >&2 echo -e $YELLOW"new file ($i_new): $filename"$NORMAL
                fi

            fi

            fastq_filename_regex=$grandparent_dir/fastq/fastq_.*\\.$prefix\\.fastq\\.gz
            fastq_filename_glob=$grandparent_dir/fastq/fastq_*.$prefix.fastq.gz
            
            if echo ${file_list[@]} | grep -wq $fastq_filename_regex; then # If the fastq file exists as well
                echo $filename # Output fast5 filename
                file_list=( "${file_list[@]/$fastq_filename_glob}" ) # Remove fastq filename from array

            else # Else append the fast5 filename to the list
                file_list+=( $filename )
            fi

        elif echo $filename | grep -q \\.fastq\\.gz; then # If it a fastq file

            if $RESUME; then # If resume option set
                grep -q /${prefix##*.}\\.fast5\\.tar$ "$RESULTS_DIR"/dev*.cfg # Check if filename exists in config files
                
                if [ $? -eq "0" ]; then # If the file has been processed
                    ((i_old ++))
                    >&2 echo -e $RED"old file ($i_old): $filename"$NORMAL
                    continue # Wait for next input
                    
                else # Else it is new
                    ((i_new ++))
                    >&2 echo -e $YELLOW"new file ($i_new): $filename"$NORMAL
                fi

            fi

            fast5_filename_regex=$grandparent_dir/fast5/${prefix##*.}\\.fast5\\.tar
            fast5_filename_glob=$grandparent_dir/fast5/${prefix##*.}.fast5.tar
            
            if echo ${file_list[@]} | grep -wq $fast5_filename_regex; then # If the fast5 file exists as well
                echo $fast5_filename_glob # Output the fast5 filename
                file_list=( "${file_list[@]/$fast5_filename_glob}" ) # remove fast5 filename from array
            
            else # Else append the fastq filename to the list
                file_list+=( $filename )
            fi
        fi
        
    done

elif [ "$FORMAT" = "--NA" ]; then

    while read filename; do

        if [ "$filename" = "-1" ]; then # Exit if -1 flag sent
            >&2 echo "[ensure.sh] exiting"
            exit 0
        fi

        parent_dir=${filename%/*} # Strip filename from .fast5 filepath
        grandparent_dir=${parent_dir%/*} # Strip parent directory from filepath

        if echo $filename | grep -q \\.fast5; then # If it is a fast5 file

            pathless=$(basename $filename) # Strip path
            prefix=${pathless%.*} # Remove extension

            if $RESUME; then # If resume option set
                grep -q /$prefix\\.fast5$ "$RESULTS_DIR"/dev*.cfg # Check if filename exists in config files
                
                if [ $? -eq "0" ]; then # If the file has been processed
                    ((i_old ++))
                    >&2 echo -e $RED"old file ($i_old): $filename"$NORMAL
                    continue # Wait for next input
                    
                else # Else it is new
                    ((i_new ++))
                    >&2 echo -e $YELLOW"new file ($i_new): $filename"$NORMAL
                fi

            fi

            fastq_filename_regex=$grandparent_dir/fastq/$prefix/$prefix\\.fastq
            fastq_filename_glob=$grandparent_dir/fastq/$prefix/$prefix.fastq
            
            if echo ${file_list[@]} | grep -wq $fastq_filename_regex; then # If the fastq file exists as well
                echo $filename # Output fast5 filename
                file_list=( "${file_list[@]/$fastq_filename_glob}" ) # Remove fastq filename from array

            else # Else append the fast5 filename to the list
                file_list+=( $filename )
            fi

        elif echo $filename | grep -q \\.fastq; then # If it a fastq file
            greatgrandparent_dir=${grandparent_dir%/*} # Strip grandparent directory from filepath
            prefix=$(basename $parent_dir) # Strip path from directory

            if $RESUME; then # If resume option set
                grep -q /$prefix/$prefix\\.fastq$ "$RESULTS_DIR"/dev*.cfg # Check if filename exists in config files
                
                if [ $? -eq "0" ]; then # If the file has been processed
                    ((i_old ++))
                    >&2 echo -e $RED"old file ($i_old): $filename"$NORMAL
                    continue # Wait for next input
                    
                else # Else it is new
                    ((i_new ++))
                    >&2 echo -e $YELLOW"new file ($i_new): $filename"$NORMAL
                fi

            fi

            fast5_filename_regex=$greatgrandparent_dir/fast5/$prefix\\.fast5
            fast5_filename_glob=$greatgrandparent_dir/fast5/$prefix.fast5
            
            if echo ${file_list[@]} | grep -wq $fast5_filename_regex; then # If the fast5 file exists
                echo $fast5_filename_glob # Output fast5 filename
                file_list=( "${file_list[@]/$fast5_filename_glob}" ) # Remove fast5 filename from array

            else # Else append the filename to the list
                file_list+=( $filename )
            fi
        fi
        
    done

elif [ "$FORMAT" = "--zebra" ]; then

    while read filename; do

        if [ "$filename" = "-1" ]; then # Exit if -1 flag sent
            >&2 echo "[ensure.sh] exiting"
            exit 0
        fi

        parent_dir=${filename%/*} # Strip filename from .fast5 filepath
        grandparent_dir=${parent_dir%/*} # Strip parent directory from filepath
        
        pathless=$(basename $filename) # Strip path
        prefix=${pathless%.*} # Remove extension

        if echo $filename | grep -q \\.fast5; then # If it is a fast5 file

            if $RESUME; then # If resume option set
                grep -q /$prefix\\.fast5$ "$RESULTS_DIR"/dev*.cfg # Check if filename exists in config files
                
                if [ $? -eq "0" ]; then # If the file has been processed
                    ((i_old ++))
                    >&2 echo -e $RED"old file ($i_old): $filename"$NORMAL
                    continue # Wait for next input
                    
                else # Else it is new
                    ((i_new ++))
                    >&2 echo -e $YELLOW"new file ($i_new): $filename"$NORMAL
                fi

            fi

            fastq_filename_regex=$grandparent_dir/fastq/$prefix\\.fastq
            fastq_filename_glob=$grandparent_dir/fastq/$prefix.fastq
            
            if echo ${file_list[@]} | grep -wq $fastq_filename_regex; then # If the fastq file exists as well
                echo $filename # Output fast5 filename
                file_list=( "${file_list[@]/$fastq_filename_glob}" ) # Remove fastq filename from array

            else # Else append the fast5 filename to the list
                file_list+=( $filename )
            fi

        elif echo $filename | grep -q \\.fastq; then # If it a fastq file

            if $RESUME; then # If resume option set
                grep -q /$prefix\\.fastq$ "$RESULTS_DIR"/dev*.cfg # Check if filename exists in config files
                
                if [ $? -eq "0" ]; then # If the file has been processed
                    ((i_old ++))
                    >&2 echo -e $RED"old file ($i_old): $filename"$NORMAL
                    continue # Wait for next input
                    
                else # Else it is new
                    ((i_new ++))
                    >&2 echo -e $YELLOW"new file ($i_new): $filename"$NORMAL
                fi

            fi

            fast5_filename_regex=$grandparent_dir/fast5/$prefix\\.fast5
            fast5_filename_glob=$grandparent_dir/fast5/$prefix.fast5
            
            if echo ${file_list[@]} | grep -wq $fast5_filename_regex; then # If the fast5 file exists
                echo $fast5_filename_glob # Output fast5 filename
                file_list=( "${file_list[@]/$fast5_filename_glob}" ) # Remove fast5 filename from array

            else # Else append the filename to the list
                file_list+=( $filename )
            fi
        fi
        
    done

fi

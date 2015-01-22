#!/bin/bash

#f_diff="--unified=30" # Damn you SPARC diff

shopt -s nullglob

display_error()
{
    if [ $1 -eq $ERR_USAGE ]; then
        if [ "$2" != "" ]; then
            echo "Error: $2"
        fi
        echo "Usage: test.sh [-dh] dir"
        echo "\t-d\tuse RCdbg instead of RC"
        echo "\t-h\tprint this message"
        echo "\tdir\tgive the directory to correct"
    elif [ $1 -eq $ERR_TEST ]; then
      echo "Cannot find directory with tests : $tests"
    elif [ $1 -eq $ERR_DIRECTORY ]; then
      echo "Cannot find directory to correct : $bindir"
    elif [ $1 -eq $ERR_BINARY ]; then
      echo "Cannot find binary to correct : $bin"
    elif [ $1 -eq $ERR_NOTEST ]; then
      echo "Cannot find any test in directory to correct : $tests"
    fi
    exit 1
}

launch()
{
  if [ $h -eq 1 ]; then
     display_error $ERR_USAGE
  fi

  bindir="$d"
  if [ ! -d "$bindir" ]; then
      display_error $ERR_DIRECTORY
  fi

  old_path="`pwd`"
  cd "$bindir"
  bindir=.

  if [ "${t:0:1}" != "/" ]; then
      t="$old_path"
  fi

  binname='RC'
  if [ $dg -eq 1 ]; then
      binname='RCdbg'
  fi

  bin="$bindir/$binname"
  if [ ! -f "$bin" ]; then
      display_error $ERR_BINARY
  fi

  tests="$t/tests"
  if [ ! -d "$tests" ]; then
      display_error $ERR_TEST
  fi

  files=""

  good=2
  list=("$tests/*.output")
  for lit in $list; do
    if [ $good -eq 2 ]; then
      good=1
    fi
    blit=$(basename "$lit")
    blit="${blit%.*}"
    if [ ! -f "$tests/$blit.rc" ]; then
      good=0
      echo "Missing file : $tests/$blit.rc"
    fi
    files="$files $tests/$blit"
  done

  if [ $good -eq 2 ]; then
      display_error $ERR_NOTEST
  elif [ $good -ne 1 ]; then
      display_error $ERR_EXIT
  fi

  count_good=0
  count_total=0

  for fle in $files; do
    count_total=$((count_total + 1))

    src="$fle.rc"
    output="$fle.output"

    echo "--- Testing $src ---"

    "$bin" "$src" | grep -v "^Error" | diff $f_diff /dev/stdin "$output"
    result=$?
    if [ $result -eq 0 ]; then
        echo "$m_good"
        count_good=$((count_good + 1))
    else
        echo "$m_bad"
    fi

    echo ""
  done

  echo "RESULT: $count_good / $count_total"

  cd "$old_path"

  if [ $count_good -ne $count_total ]; then
      exit 1
  fi
}

ERR_EXIT=0
ERR_USAGE=1
ERR_TEST=2
ERR_DIRECTORY=3
ERR_NOTEST=4
ERR_BINARY=5

m_begin="--- "
m_end=" ---"
m_good="${m_begin}GOOD${m_end}"
m_bad="\n< Yours\n> Correction\n${m_begin}BAD${m_end}"

h=0
dg=0
d=""
t="${0%/*}"

while [ "$1" ]; do
    if [ "${1:0:1}" == "-" -a \( "${1#*h}" != "$1" -o "${1#*d}" != "$1" \) ]; then
        if [ "${1#*h}" != "$1" ]; then
            h=1
        fi
        if [ "${1#*d}" != "$1" ]; then
            dg=1
        fi
        shift
    else
        if [ "$d" != "" ]; then
            display_error $ERR_USAGE "Too much arguments"
        fi
        d="$1"
        shift
    fi
done

if [ "$d" == "" ]; then
    display_error $ERR_USAGE "Missing argument for: dir"
fi

launch

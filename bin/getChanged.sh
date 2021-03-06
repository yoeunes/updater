#!/bin/bash
# Yorick Terweijden <yorick.terweijden@sourcefabric.org>
# Rafał Muszyński <rafal.muszynski@sourcefabric.org>
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.
AUTHOR="Yorick Terweijden"
PATHPREFIX="packages/"
VERSION="2"

USAGE="\n$BASH_SOURCE v$VERSION HELP\n \
\n\
This script allows you to create an update package in the target (-t) directory\n\
based on the differences in a git repository between the current state and a\n\
specific git tree-ish.\n\
The script requires to be called with the current working directory set to be the\n\
appropriate git repostitory.\n\
\n \
REQUIRED\n \
\t-c\ta git-treeish (e.g. a COMMIT or TAG)\n\n \
\t-n\ta package name (e.g. 4.3.1-RC)\n\n \
\t-d\ta path to be compared (e.g. sample_app/src)\n\n \
OPTIONAL\n \
\t-s\tthe source directory, defaults to current directory\n \
\t-t\tthe target directory, defaults to '$PATHPREFIX'\n \
\t-e\texclude directories or/and files from package\n \
\t-h\tthis usage description\
\n \
\n\
Copyright 2014 Sourcefabric z.ú. written by $AUTHOR"

while getopts ":hc:d:n:t:s:e:" opt; do
  case $opt in
    n)
      PACKAGENAME=$OPTARG
      ;;
    s)
      SOURCEPATH=$OPTARG
      ;;
    c)
      COMMIT=$OPTARG
      SLUG="_commits"
      FILE=$PATHPREFIX$PACKAGENAME.txt
      COMMITSFILE=$PATHPREFIX$PACKAGENAME$SLUG.txt
      [[ -f "$FILE" ]] && rm -f "$FILE"
      [[ -f "$COMMITSFILE" ]] && rm -f "$COMMITSFILE"
      if [ ! -d "$SOURCEPATH" ]; then
          echo "The specified source does not exist: $SOURCEPATH"
          exit 1
      fi
      cd $SOURCEPATH
      if ! git rev-parse  2> /dev/null
      then
          echo "Current directory is a not a git repository: $SOURCEPATH"
          exit 1
      fi
      if ! git cat-file -e $COMMIT 2> /dev/null
      then
          echo "The specified git tree-ish does not exist: $COMMIT"
          exit 1
      fi
      ;;
    t)
      PATHPREFIX=$OPTARG
      ;;
    e)
      EXCLUDE=$OPTARG
      ;;
    d)
      COMPAREPATH=$OPTARG
      ;;
    h)
      echo -e "$USAGE"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo -e "$USAGE"
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      echo -e "$USAGE"
      exit 1
      ;;
  esac
done

if [ ! -d "$PATHPREFIX" ]; then
    echo "The specified target does not exist: $PATHPREFIX"
    exit 1
fi

if [ -n "$COMMIT" ]; then
echo -e "\nCreating $PACKAGENAME.zip, $PACKAGENAME.txt and $PACKAGENAME$SLUG.txt in $PATHPREFIX\n"
cd $SOURCEPATH
  if [ -z "$EXCLUDE" ]
    then
      git archive --format zip -o $PATHPREFIX$PACKAGENAME.zip HEAD -- $(git diff-tree --diff-filter=ACMR --no-commit-id --name-only -r $COMMIT^1.. -- $COMPAREPATH)
      git diff-tree --no-commit-id --name-status -r $COMMIT^1.. -- $COMPAREPATH >> $PATHPREFIX$PACKAGENAME.txt
    else
      git archive --format zip -o $PATHPREFIX$PACKAGENAME.zip HEAD -- $(git diff-tree --diff-filter=ACMR --no-commit-id --name-only -r $COMMIT^1.. -- $COMPAREPATH |grep -Ev "$EXCLUDE")
      git diff-tree --no-commit-id --name-status -r $COMMIT^1.. -- $COMPAREPATH |grep -Ev "$EXCLUDE" >> $PATHPREFIX$PACKAGENAME.txt
  fi
  git log --oneline $COMMIT..HEAD --no-merges $COMPAREPATH >> $PATHPREFIX$PACKAGENAME$SLUG.txt
else
    echo -e "$USAGE"
fi

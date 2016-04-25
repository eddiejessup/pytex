SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPTPATH
python pytex.py -ini test.tex
dvipdf test.dvi

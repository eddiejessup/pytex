SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPTPATH
python test_cy_test.py -ini test.tex
dvipdf test.dvi

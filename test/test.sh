SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPTPATH
python test_cy_test.py test.tex
dvipdf test.dvi

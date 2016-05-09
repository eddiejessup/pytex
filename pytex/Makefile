all:
	python setup.py build_ext --inplace
	install_name_tool -change libcpdfetex.so ../cpdfetex/libcpdfetex.so pytex_main.so
	install_name_tool -change /usr/local/lib/libkpathsea.4.dylib ../texk/kpathsea/.libs/libkpathsea.4.dylib pytex_main.so
clean:
	rm -f pytex_main.so pytex_main.cpp

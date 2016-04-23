from distutils.core import setup
from distutils.extension import Extension

from Cython.Distutils import build_ext

ext_modules = [
    Extension("cy_test",
              ["cy_test.pyx"],
              library_dirs=['../cpdfetex'],
              libraries=["cpdfetex"],
              )
]
setup(
    name="cy_test",
    cmdclass={"build_ext": build_ext},
    include_dirs=['../cpdfetex', '../texk'],
    ext_modules=ext_modules
)

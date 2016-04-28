from distutils.core import setup
from distutils.extension import Extension

from Cython.Distutils import build_ext
from Cython.Build import cythonize

ext_modules = [
    Extension("pytex_main",
              ["pytex_main.pyx"],
              library_dirs=['../cpdfetex', '../texk/kpathsea/.libs'],
              libraries=["cpdfetex", "kpathsea"],
              language="c++",
              )
]
setup(
    name="pytex_main",
    cmdclass={"build_ext": build_ext},
    include_dirs=['../cpdfetex', '../texk'],
    ext_modules=cythonize(ext_modules, language="c++")
)

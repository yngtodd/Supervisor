R_HOME=/global/homes/w/wozniak/Public/sfw/R-3.4.0/lib64/R
R_INCLUDE=$R_HOME/include
R_LIB=$R_HOME/lib
R_INSIDE=$R_HOME/library/RInside
RCPP=$R_HOME/library/Rcpp

#system-wide tcl
TCL_INCLUDE=/global/u1/w/wozniak/Public/sfw/tcl-8.6.6/include
TCL_LIB=/global/u1/w/wozniak/Public/sfw/tcl-8.6.6/lib
TCL_LIBRARY=tcl8.6

CPPFLAGS=""
CPPFLAGS+="-I$TCL_INCLUDE "
CPPFLAGS+="-I$R_INCLUDE "
CPPFLAGS+="-I$RCPP/include "
CPPFLAGS+="-I$R_INSIDE/include "
CXXFLAGS=$CPPFLAGS

LDFLAGS=""
LDFLAGS+="-L$R_INSIDE/lib -lRInside "
LDFLAGS+="-L$R_LIB -lR -lRblas "
LDFLAGS+="-L$TCL_LIB -l$TCL_LIBRARY "
LDFLAGS+="-Wl,-rpath -Wl,$TCL_LIB "
LDFLAGS+="-Wl,-rpath -Wl,$R_LIB "
LDFLAGS+="-Wl,-rpath -Wl,$R_INSIDE/lib"

export CPPFLAGS CXXFLAGS LDFLAGS

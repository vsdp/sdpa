#
# SDPA-M: $Revision: 7.3 $

# This file is a component of SDPA
# Copyright (C) 2004-2012 SDPA Project

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

#MAKE_INCLUDE_DIR=..
#-include ${MAKE_INCLUDE_DIR}/make.inc
# after "make install", you can find
# 'make.inc' in 'share/sdpa' sub-directory under the installed directory
# For example
# make MAKE_INCLUDE_DIR=/usr/share/sdpa
#  or 
# make MAKE_INCLUDE_DIR=/usr/local/share/sdpa

ALL_INCLUDE = '-I/usr/local/include -I../mumps/build/include';
ALL_LIBS = ['../libsdpa.a ', ...
  '-L../mumps/build/lib -ldmumps -lmumps_common -lpord ', ...
  '-L../mumps/build/libseq -lmpiseq'];

mex_compile = @(f) eval (['mex -D''PRINTF_INT_STYLE=\\\"%d\\\"'' ', ...
  ALL_INCLUDE, ' ', f, ' ', ALL_LIBS]);

mex_compile ("mexsdpa.cpp mexFprintf.c");
mex_compile ("mexSedumiWrap.cpp mexFprintf.c");
mex_compile ("mexAggSDPcones.cpp mexFprintf.c");
mex_compile ("mexDisAggSDPsol.cpp mexFprintf.c");
mex_compile ("mexWriteSedumiToSDPA.cpp");
mex_compile ("mexReadSDPAToSedumi.cpp");
mex_compile ("mexReadOutput.cpp");

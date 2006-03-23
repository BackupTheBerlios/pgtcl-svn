# $Id$

#
# Include the TEA standard macro set
#

builtin(include,tclconfig/tcl.m4)

#
# Add here whatever m4 macros you want to define for your package
#

#--------------------------------------------------------------------
# POSTGRESQL_CONFIG
#
#       Get the paths to the PostgreSQL includes and libraries.
#
#	Try to determine the proper flags to pass to the compiler
#	for building shared libraries and other such nonsense.
#
# Arguments:
#	none
#
# Results:
#
#	Defines and substitutes the following vars:
#
#       LIBPG -        description not available
#       PG_INC_DIR -   n/a
#       PG_INCLUDES -  n/a
#       PG_LIBS -      n/a
#       PG_LIB_DIR -   n/a
#
#--------------------------------------------------------------------

AC_DEFUN(POSTGRESQL_CONFIG, [
    AC_ARG_WITH(postgres-include,
	AC_HELP_STRING([--with-postgres-include], [directory containing PostgreSQL include files]))
    AC_ARG_WITH(postgres-lib,
	AC_HELP_STRING([--with-postgres-lib], [directory containing PostgreSQL library files]))
    AC_ARG_WITH(pgconfig-path,
	AC_HELP_STRING([--with-pgconfig-path], [directory containing PostgreSQL pg_config]))

    need_pg_config=""

    if test "${with_postgres_include+set}" = "set"; then
	PG_INC_DIR="${with_postgres_include}"
	AC_MSG_RESULT([using PostgreSQL include dir of... $PG_INC_DIR])
    else
	need_pg_config="1"
    fi

    if test "${with_postgres_lib+set}" = "set"; then
	PG_LIB_DIR="${with_postgres_lib}"
	AC_MSG_RESULT([using PostgreSQL lib dir of... $PG_LIB_DIR])
    else
	need_pg_config="1"
    fi

    if test "${with_pgconfig_path+set}" = "set"; then
	PG_CONFIG_PATH="${with_pgconfig_path}"
	AC_MSG_RESULT([using PostgreSQL pg_config path... $PG_CONFIG_PATH])
    fi

    if test x"$need_pg_config" = x"1"; then

        # Use different names for different OSes
        PG_CONFIG_NAMES="pg_config"
        if test "${TEA_PLATFORM}" = "windows"; then
            PG_CONFIG_NAMES="$PG_CONFIG_NAMES pg_config.exe pg_config.bat pg_config.cmd"
        else
            PG_CONFIG_NAMES="$PG_CONFIG_NAMES pg_config.sh"
        fi

        if test "${with_pgconfig_path+set}" = "set"; then
            PG_CONFIG_SEARCH_PATH=$PG_CONFIG_PATH
        else
            # Alternative paths for autodiscovery mode
            PG_CONFIG_PATH_ALT=""

            # on Windows, check in common installation locations (autodiscovery mode)
            if test "${TEA_PLATFORM}" = "windows"; then
                for i in 8.2 8.1 8.0; do
                    PG_CONFIG_PATH_ALT="$PG_CONFIG_PATH_ALT C:/PROGRA~1/POSTGR~1/$i/bin"
                done
            fi
            PG_CONFIG_SEARCH_PATH=$PG_CONFIG_PATH_ALT
        fi

        if test x"$PG_CONFIG_SEARCH_PATH" != x""; then
            AC_MSG_CHECKING([for specific pg_config])
            for j in $PG_CONFIG_SEARCH_PATH; do
                for i in $PG_CONFIG_NAMES; do
                    if test -f $j/$i; then
                        if test "${TEA_PLATFORM}" = "windows"; then
                            # Strange pg_config behaviour in 'BIN' dir instead of 'bin'
                            # Info: win32 is case insensitive
                            j=`(cd $j; pwd) | tr A-Z a-z`
                        fi
                        PG_CONFIG="`(cd $j; pwd)`/$i"
                        PG_VERSION="`$PG_CONFIG --version`"
                        AC_MSG_RESULT([yes])
                        AC_MSG_RESULT([using pg_config from... $PG_VERSION])
                        break
                    fi
                done
                if test x"$PG_CONFIG" != x""; then break; fi
            done
            if test x"$PG_CONFIG" = x""; then
                AC_MSG_RESULT([no])
            fi
        fi

	if test x"$PG_CONFIG" = x"" -a "${with_pgconfig_path+set}" != "set"; then
            AC_PATH_PROGS(PG_CONFIG, pg_config)
        fi

	if test x"$PG_CONFIG" = x""; then
	    AC_MSG_ERROR([Cannot locate program pg_config to determine PostgreSQL paths.  Make sure pg_config is in PATH or set PG_CONFIG env var to path to pg_config.])
	fi

	if test "${with_postgres_include+set}" != "set"; then
	    PG_INC_DIR="`$PG_CONFIG --includedir`"
	    AC_MSG_RESULT([using reported PostgreSQL include dir of... $PG_INC_DIR])
	fi
	if test "${with_postgres_lib+set}" != "set"; then
    	    PG_LIB_DIR="`$PG_CONFIG --libdir`"
    	    AC_MSG_RESULT([using reported PostgreSQL lib dir of... $PG_LIB_DIR])
	fi
    fi

    LIBPG=""
    PG_INCLUDES="-I$PG_INC_DIR"
    PKG_INCLUDES="-I$PG_INC_DIR"
    PG_LIBS="-L$PG_LIB_DIR -lpq"
    PKG_LIBS="$PKG_LIBS -L$PG_LIB_DIR -lpq"
    if test ! "$PG_LIB_DIR" = ""; then
	LIBPG="libpq${SHLIB_SUFFIX}"
    fi

    #-------------------------------------------------------------------
    # Determine if certain PostgreSQL functions are defined 
    # (Postgres 7.4 and above)
    #-------------------------------------------------------------------

    SAVE_LIBS=$LIBS
    LIBS="$PG_LIBS $LIBS"
    AC_CHECK_FUNCS([PQexecParams PQexecPrepared PQsendQueryParams PQsendQueryPrepared])
    LIBS=$SAVE_LIBS

    AC_SUBST(LIBPG)
    AC_SUBST(PG_INC_DIR)
    AC_SUBST(PG_INCLUDES)
    AC_SUBST(PG_LIBS)
    AC_SUBST(PG_LIB_DIR)
])

#--------------------------------------------------------------------
# PGTCL_CONFIG_CFLAGS
#
#	a modified copy of TEA_CONFIG_CFLAGS
#
#	The reason is that we have to set up search paths to the Tcl shared
#	lib AND the postgres libpq shared lib.
#
#	Unfortunately this is a big routine and our changes are small.
#	This is a maintenance problem as changes to TEA_CONFIG_CFLAGS in
#	tcl.m4 need to be propagated.
#
#	Try to determine the proper flags to pass to the compiler
#	for building shared libraries and other such nonsense.
#
# Arguments:
#	none
#
# Results:
#
#	Defines and substitutes the following vars:
#
#       DL_OBJS -       Name of the object file that implements dynamic
#                       loading for Tcl on this system.
#       DL_LIBS -       Library file(s) to include in tclsh and other base
#                       applications in order for the "load" command to work.
#       LDFLAGS -      Flags to pass to the compiler when linking object
#                       files into an executable application binary such
#                       as tclsh.
#       LD_SEARCH_FLAGS-Flags to pass to ld, such as "-R /usr/local/tcl/lib",
#                       that tell the run-time dynamic linker where to look
#                       for shared libraries such as libtcl.so.  Depends on
#                       the variable LIB_RUNTIME_DIR in the Makefile. Could
#                       be the same as CC_SEARCH_FLAGS if ${CC} is used to link.
#       CC_SEARCH_FLAGS-Flags to pass to ${CC}, such as "-Wl,-rpath,/usr/local/tcl/lib",
#                       that tell the run-time dynamic linker where to look
#                       for shared libraries such as libtcl.so.  Depends on
#                       the variable LIB_RUNTIME_DIR in the Makefile.
#       SHLIB_CFLAGS -  Flags to pass to cc when compiling the components
#                       of a shared library (may request position-independent
#                       code, among other things).
#       SHLIB_LD -      Base command to use for combining object files
#                       into a shared library.
#       SHLIB_LD_LIBS - Dependent libraries for the linker to scan when
#                       creating shared libraries.  This symbol typically
#                       goes at the end of the "ld" commands that build
#                       shared libraries. The value of the symbol is
#                       "${LIBS}" if all of the dependent libraries should
#                       be specified when creating a shared library.  If
#                       dependent libraries should not be specified (as on
#                       SunOS 4.x, where they cause the link to fail, or in
#                       general if Tcl and Tk aren't themselves shared
#                       libraries), then this symbol has an empty string
#                       as its value.
#       SHLIB_SUFFIX -  Suffix to use for the names of dynamically loadable
#                       extensions.  An empty string means we don't know how
#                       to use shared libraries on this platform.
#       LIB_SUFFIX -    Specifies everything that comes after the "libfoo"
#                       in a static or shared library name, using the $VERSION variable
#                       to put the version in the right place.  This is used
#                       by platforms that need non-standard library names.
#                       Examples:  ${VERSION}.so.1.1 on NetBSD, since it needs
#                       to have a version after the .so, and ${VERSION}.a
#                       on AIX, since a shared library needs to have
#                       a .a extension whereas shared objects for loadable
#                       extensions have a .so extension.  Defaults to
#                       ${VERSION}${SHLIB_SUFFIX}.
#       TCL_NEEDS_EXP_FILE -
#                       1 means that an export file is needed to link to a
#                       shared library.
#       TCL_EXP_FILE -  The name of the installed export / import file which
#                       should be used to link to the Tcl shared library.
#                       Empty if Tcl is unshared.
#       TCL_BUILD_EXP_FILE -
#                       The name of the built export / import file which
#                       should be used to link to the Tcl shared library.
#                       Empty if Tcl is unshared.
#	CFLAGS_DEBUG -
#			Flags used when running the compiler in debug mode
#	CFLAGS_OPTIMIZE -
#			Flags used when running the compiler in optimize mode
#	CFLAGS -	Additional CFLAGS added as necessary (usually 64-bit)
#
#--------------------------------------------------------------------

AC_DEFUN(PGTCL_CONFIG_CFLAGS, [
    dnl Make sure we are initialized
    AC_REQUIRE([TEA_INIT])

    # Step 0.a: Enable 64 bit support?

    AC_MSG_CHECKING([if 64bit support is requested])
    AC_ARG_ENABLE(64bit,
	AC_HELP_STRING([--enable-64bit],
	    [enable 64bit support (default: off)]),
	[do64bit=$enableval], [do64bit=no])
    AC_MSG_RESULT([$do64bit])

    # Step 0.b: Enable Solaris 64 bit VIS support?

    AC_MSG_CHECKING([if 64bit Sparc VIS support is requested])
    AC_ARG_ENABLE(64bit-vis,
	AC_HELP_STRING([--enable-64bit-vis],
	    [enable 64bit Sparc VIS support (default: off)]),
	[do64bitVIS=$enableval], [do64bitVIS=no])
    AC_MSG_RESULT([$do64bitVIS])

    if test "$do64bitVIS" = "yes"; then
	# Force 64bit on with VIS
	do64bit=yes
    fi

    # Step 0.c: Cross-compiling options for Windows/CE builds?

    if test "${TEA_PLATFORM}" = "windows" ; then
	AC_MSG_CHECKING([if Windows/CE build is requested])
	AC_ARG_ENABLE(wince,[  --enable-wince          enable Win/CE support (where applicable)], [doWince=$enableval], [doWince=no])
	AC_MSG_RESULT([$doWince])
    fi

    # Step 1: set the variable "system" to hold the name and version number
    # for the system.

    TEA_CONFIG_SYSTEM

    # Step 2: check for existence of -ldl library.  This is needed because
    # Linux can use either -ldl or -ldld for dynamic loading.

    AC_CHECK_LIB(dl, dlopen, have_dl=yes, have_dl=no)

    # Require ranlib early so we can override it in special cases below.

    AC_REQUIRE([AC_PROG_RANLIB])

    # Step 3: set configuration options based on system name and version.
    # This is similar to Tcl's unix/tcl.m4 except that we've added a
    # "windows" case.

    do64bit_ok=no
    LDFLAGS_ORIG="$LDFLAGS"
    # When ld needs options to work in 64-bit mode, put them in
    # LDFLAGS_ARCH so they eventually end up in LDFLAGS even if [load]
    # is disabled by the user. [Bug 1016796]
    LDFLAGS_ARCH=""
    TCL_EXPORT_FILE_SUFFIX=""
    UNSHARED_LIB_SUFFIX=""
    TCL_TRIM_DOTS='`echo ${PACKAGE_VERSION} | tr -d .`'
    ECHO_VERSION='`echo ${PACKAGE_VERSION}`'
    TCL_LIB_VERSIONS_OK=ok
    CFLAGS_DEBUG=-g
    CFLAGS_OPTIMIZE=-O
    if test "$GCC" = "yes" ; then
	CFLAGS_OPTIMIZE=-O2
	CFLAGS_WARNING="-Wall -Wno-implicit-int"
    else
	CFLAGS_WARNING=""
    fi
    TCL_NEEDS_EXP_FILE=0
    TCL_BUILD_EXP_FILE=""
    TCL_EXP_FILE=""
dnl FIXME: Replace AC_CHECK_PROG with AC_CHECK_TOOL once cross compiling is fixed.
dnl AC_CHECK_TOOL(AR, ar)
    AC_CHECK_PROG(AR, ar, ar)
    STLIB_LD='${AR} cr'
    LD_LIBRARY_PATH_VAR="LD_LIBRARY_PATH"
    case $system in
	windows)
	    # This is a 2-stage check to make sure we have the 64-bit SDK
	    # We have to know where the SDK is installed.
	    # This magic is based on MS Platform SDK for Win2003 SP1 - hobbs
	    # MACHINE is IX86 for LINK, but this is used by the manifest,
	    # which requires x86|amd64|ia64.
	    MACHINE="X86"
	    if test "$do64bit" != "no" ; then
		if test "x${MSSDK}x" = "xx" ; then
		    MSSDK="C:/Progra~1/Microsoft Platform SDK"
		fi
		MSSDK=`echo "$MSSDK" | sed -e  's!\\\!/!g'`
		PATH64=""
		case "$do64bit" in
		    amd64|x64|yes)
			MACHINE="AMD64" ; # default to AMD64 64-bit build
			PATH64="${MSSDK}/Bin/Win64/x86/AMD64"
			;;
		    ia64)
			MACHINE="IA64"
			PATH64="${MSSDK}/Bin/Win64"
			;;
		esac
		if test ! -d "${PATH64}" ; then
		    AC_MSG_WARN([Could not find 64-bit $MACHINE SDK to enable 64bit mode])
		    AC_MSG_WARN([Ensure latest Platform SDK is installed])
		    do64bit="no"
		else
		    AC_MSG_RESULT([   Using 64-bit $MACHINE mode])
		    do64bit_ok="yes"
		fi
	    fi

	    if test "$doWince" != "no" ; then
		if test "$do64bit" != "no" ; then
		    AC_MSG_ERROR([Windows/CE and 64-bit builds incompatible])
		fi
		if test "$GCC" = "yes" ; then
		    AC_MSG_ERROR([Windows/CE and GCC builds incompatible])
		fi
		TEA_PATH_CELIB
		# Set defaults for common evc4/PPC2003 setup
		# Currently Tcl requires 300+, possibly 420+ for sockets
		CEVERSION=420; 		# could be 211 300 301 400 420 ...
		TARGETCPU=ARMV4;	# could be ARMV4 ARM MIPS SH3 X86 ...
		ARCH=ARM;		# could be ARM MIPS X86EM ...
		PLATFORM="Pocket PC 2003"; # or "Pocket PC 2002"
		if test "$doWince" != "yes"; then
		    # If !yes then the user specified something
		    # Reset ARCH to allow user to skip specifying it
		    ARCH=
		    eval `echo $doWince | awk -F, '{ \
	    if (length([$]1)) { printf "CEVERSION=\"%s\"\n", [$]1; \
	    if ([$]1 < 400)   { printf "PLATFORM=\"Pocket PC 2002\"\n" } }; \
	    if (length([$]2)) { printf "TARGETCPU=\"%s\"\n", toupper([$]2) }; \
	    if (length([$]3)) { printf "ARCH=\"%s\"\n", toupper([$]3) }; \
	    if (length([$]4)) { printf "PLATFORM=\"%s\"\n", [$]4 }; \
		    }'`
		    if test "x${ARCH}" = "x" ; then
			ARCH=$TARGETCPU;
		    fi
		fi
		OSVERSION=WCE$CEVERSION;
	    	if test "x${WCEROOT}" = "x" ; then
			WCEROOT="C:/Program Files/Microsoft eMbedded C++ 4.0"
		    if test ! -d "${WCEROOT}" ; then
			WCEROOT="C:/Program Files/Microsoft eMbedded Tools"
		    fi
		fi
		if test "x${SDKROOT}" = "x" ; then
		    SDKROOT="C:/Program Files/Windows CE Tools"
		    if test ! -d "${SDKROOT}" ; then
			SDKROOT="C:/Windows CE Tools"
		    fi
		fi
		WCEROOT=`echo "$WCEROOT" | sed -e 's!\\\!/!g'`
		SDKROOT=`echo "$SDKROOT" | sed -e 's!\\\!/!g'`
		if test ! -d "${SDKROOT}/${OSVERSION}/${PLATFORM}/Lib/${TARGETCPU}" \
		    -o ! -d "${WCEROOT}/EVC/${OSVERSION}/bin"; then
		    AC_MSG_ERROR([could not find PocketPC SDK or target compiler to enable WinCE mode [$CEVERSION,$TARGETCPU,$ARCH,$PLATFORM]])
		    doWince="no"
		else
		    # We could PATH_NOSPACE these, but that's not important,
		    # as long as we quote them when used.
		    CEINCLUDE="${SDKROOT}/${OSVERSION}/${PLATFORM}/include"
		    if test -d "${CEINCLUDE}/${TARGETCPU}" ; then
			CEINCLUDE="${CEINCLUDE}/${TARGETCPU}"
		    fi
		    CELIBPATH="${SDKROOT}/${OSVERSION}/${PLATFORM}/Lib/${TARGETCPU}"
    		fi
	    fi

	    if test "$GCC" != "yes" ; then
	        if test "${SHARED_BUILD}" = "0" ; then
		    runtime=-MT
	        else
		    runtime=-MD
	        fi

                if test "$do64bit" != "no" ; then
		    # All this magic is necessary for the Win64 SDK RC1 - hobbs
		    CC="\"${PATH64}/cl.exe\""
		    CFLAGS="${CFLAGS} -I\"${MSSDK}/Include\" -I\"${MSSDK}/Include/crt\" -I\"${MSSDK}/Include/crt/sys\""
		    RC="\"${MSSDK}/bin/rc.exe\""
		    lflags="-nologo -MACHINE:${MACHINE} -LIBPATH:\"${MSSDK}/Lib/${MACHINE}\""
		    LINKBIN="\"${PATH64}/link.exe\""
		    CFLAGS_DEBUG="-nologo -Zi -Od -W3 ${runtime}d"
		    CFLAGS_OPTIMIZE="-nologo -O2 -W2 ${runtime}"
		    # Avoid 'unresolved external symbol __security_cookie'
		    # errors, c.f. http://support.microsoft.com/?id=894573
		    TEA_ADD_LIBS([bufferoverflowU.lib])
		elif test "$doWince" != "no" ; then
		    CEBINROOT="${WCEROOT}/EVC/${OSVERSION}/bin"
		    if test "${TARGETCPU}" = "X86"; then
			CC="\"${CEBINROOT}/cl.exe\""
		    else
			CC="\"${CEBINROOT}/cl${ARCH}.exe\""
		    fi
		    CFLAGS="$CFLAGS -I\"${CELIB_DIR}/inc\" -I\"${CEINCLUDE}\""
		    RC="\"${WCEROOT}/Common/EVC/bin/rc.exe\""
		    arch=`echo ${ARCH} | awk '{print tolower([$]0)}'`
		    defs="${ARCH} _${ARCH}_ ${arch} PALM_SIZE _MT _WINDOWS"
		    if test "${SHARED_BUILD}" = "1" ; then
			# Static CE builds require static celib as well
		    	defs="${defs} _DLL"
		    fi
		    for i in $defs ; do
			AC_DEFINE_UNQUOTED($i, 1, [WinCE def ]$i)
		    done
		    AC_DEFINE_UNQUOTED(_WIN32_WCE, $CEVERSION, [_WIN32_WCE version])
		    AC_DEFINE_UNQUOTED(UNDER_CE, $CEVERSION, [UNDER_CE version])
		    CFLAGS_DEBUG="-nologo -Zi -Od"
		    CFLAGS_OPTIMIZE="-nologo -Ox"
		    lversion=`echo ${CEVERSION} | sed -e 's/\(.\)\(..\)/\1\.\2/'`
		    lflags="-MACHINE:${ARCH} -LIBPATH:\"${CELIBPATH}\" -subsystem:windowsce,${lversion} -nologo"
		    LINKBIN="\"${CEBINROOT}/link.exe\""
		    AC_SUBST(CELIB_DIR)
		else
		    RC="rc"
		    lflags="-nologo"
    		    LINKBIN="link"
		    CFLAGS_DEBUG="-nologo -Z7 -Od -W3 -WX ${runtime}d"
		    CFLAGS_OPTIMIZE="-nologo -O2 -W2 ${runtime}"
		fi
	    fi

	    if test "$GCC" = "yes"; then
		# mingw gcc mode
		RC="windres"
		CFLAGS_DEBUG="-g"
		CFLAGS_OPTIMIZE="-O2 -fomit-frame-pointer"
		SHLIB_LD="$CC -shared"
		UNSHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.a'
		LDFLAGS_CONSOLE="-wl,--subsystem,console ${lflags}"
		LDFLAGS_WINDOW="-wl,--subsystem,windows ${lflags}"
	    else
		SHLIB_LD="${LINKBIN} -dll ${lflags}"
		# link -lib only works when -lib is the first arg
		STLIB_LD="${LINKBIN} -lib ${lflags}"
		UNSHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.lib'
		PATHTYPE=-w
		# For information on what debugtype is most useful, see:
		# http://msdn.microsoft.com/library/en-us/dnvc60/html/gendepdebug.asp
		# This essentially turns it all on.
		LDFLAGS_DEBUG="-debug:full -debugtype:both -warn:2"
		LDFLAGS_OPTIMIZE="-release"
		if test "$doWince" != "no" ; then
		    LDFLAGS_CONSOLE="-link ${lflags}"
		    LDFLAGS_WINDOW=${LDFLAGS_CONSOLE}
		else
		    LDFLAGS_CONSOLE="-link -subsystem:console ${lflags}"
		    LDFLAGS_WINDOW="-link -subsystem:windows ${lflags}"
		fi
	    fi

	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".dll"
	    SHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.dll'

	    TCL_LIB_VERSIONS_OK=nodots
	    # Bogus to avoid getting this turned off
	    DL_OBJS="tclLoadNone.obj"
    	    ;;
	AIX-*)
	    if test "${TCL_THREADS}" = "1" -a "$GCC" != "yes" ; then
		# AIX requires the _r compiler when gcc isn't being used
		case "${CC}" in
		    *_r)
			# ok ...
			;;
		    *)
			CC=${CC}_r
			;;
		esac
		AC_MSG_RESULT([Using $CC for compiling with threads])
	    fi
	    LIBS="$LIBS -lc"
	    SHLIB_CFLAGS=""
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"

	    DL_OBJS="tclLoadDl.o"
	    LD_LIBRARY_PATH_VAR="LIBPATH"

	    # Check to enable 64-bit flags for compiler/linker on AIX 4+
	    if test "$do64bit" = "yes" -a "`uname -v`" -gt "3" ; then
		if test "$GCC" = "yes" ; then
		    AC_MSG_WARN([64bit mode not supported with GCC on $system])
		else 
		    do64bit_ok=yes
		    CFLAGS="$CFLAGS -q64"
		    LDFLAGS_ARCH="-q64"
		    RANLIB="${RANLIB} -X64"
		    AR="${AR} -X64"
		    SHLIB_LD_FLAGS="-b64"
		fi
	    fi

	    if test "`uname -m`" = "ia64" ; then
		# AIX-5 uses ELF style dynamic libraries on IA-64, but not PPC
		SHLIB_LD="/usr/ccs/bin/ld -G -z text"
		# AIX-5 has dl* in libc.so
		DL_LIBS=""
		if test "$GCC" = "yes" ; then
		    CC_SEARCH_FLAGS='-Wl,-R,${LIB_RUNTIME_DIR},-R,${LIB_PGTCL_RUNTIME_DIR}'
		else
		    # XXX: probably '-R${LIB_RUNTIME_DIR},-R${LIB_PGTCL_RUNTIME_DIR}'
		    #            or '-R${LIB_RUNTIME_DIR} -R${LIB_PGTCL_RUNTIME_DIR}'
		    CC_SEARCH_FLAGS='-R${LIB_RUNTIME_DIR},-R,${LIB_PGTCL_RUNTIME_DIR}'
		fi
		LD_SEARCH_FLAGS='-R ${LIB_RUNTIME_DIR} -R ${LIB_PGTCL_RUNTIME_DIR}'
	    else
		if test "$GCC" = "yes" ; then
		    SHLIB_LD="gcc -shared"
		else
		    SHLIB_LD="/bin/ld -bhalt:4 -bM:SRE -bE:lib.exp -H512 -T512 -bnoentry"
		fi
		SHLIB_LD="${TCL_SRC_DIR}/unix/ldAix ${SHLIB_LD} ${SHLIB_LD_FLAGS}"
		DL_LIBS="-ldl"
		CC_SEARCH_FLAGS='-L${LIB_RUNTIME_DIR} -L${LIB_PGTCL_RUNTIME_DIR}'
		LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}
		TCL_NEEDS_EXP_FILE=1
		TCL_EXPORT_FILE_SUFFIX='${PACKAGE_VERSION}.exp'
	    fi

	    # AIX v<=4.1 has some different flags than 4.2+
	    if test "$system" = "AIX-4.1" -o "`uname -v`" -lt "4" ; then
		AC_LIBOBJ([tclLoadAix])
		DL_LIBS="-lld"
	    fi

	    # On AIX <=v4 systems, libbsd.a has to be linked in to support
	    # non-blocking file IO.  This library has to be linked in after
	    # the MATH_LIBS or it breaks the pow() function.  The way to
	    # insure proper sequencing, is to add it to the tail of MATH_LIBS.
	    # This library also supplies gettimeofday.
	    #
	    # AIX does not have a timezone field in struct tm. When the AIX
	    # bsd library is used, the timezone global and the gettimeofday
	    # methods are to be avoided for timezone deduction instead, we
	    # deduce the timezone by comparing the localtime result on a
	    # known GMT value.

	    AC_CHECK_LIB(bsd, gettimeofday, libbsd=yes, libbsd=no)
	    if test $libbsd = yes; then
	    	MATH_LIBS="$MATH_LIBS -lbsd"
	    	AC_DEFINE(USE_DELTA_FOR_TZ, 1, [Do we need a special AIX hack for timezones?])
	    fi
	    ;;
	BeOS*)
	    SHLIB_CFLAGS="-fPIC"
	    SHLIB_LD="${CC} -nostart"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"

	    #-----------------------------------------------------------
	    # Check for inet_ntoa in -lbind, for BeOS (which also needs
	    # -lsocket, even if the network functions are in -lnet which
	    # is always linked to, for compatibility.
	    #-----------------------------------------------------------
	    AC_CHECK_LIB(bind, inet_ntoa, [LIBS="$LIBS -lbind -lsocket"])
	    ;;
	BSD/OS-2.1*|BSD/OS-3*)
	    SHLIB_CFLAGS=""
	    SHLIB_LD="shlicc -r"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	BSD/OS-4.*)
	    SHLIB_CFLAGS="-export-dynamic -fPIC"
	    SHLIB_LD="cc -shared"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    LDFLAGS="$LDFLAGS -export-dynamic"
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	dgux*)
	    SHLIB_CFLAGS="-K PIC"
	    SHLIB_LD="cc -G"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	HP-UX-*.11.*)
	    # Use updated header definitions where possible
	    AC_DEFINE(_XOPEN_SOURCE_EXTENDED, 1, [Do we want to use the XOPEN network library?])
	    # Needed by Tcl, but not most extensions
	    #AC_DEFINE(_XOPEN_SOURCE, 1, [Do we want to use the XOPEN network library?])
	    #LIBS="$LIBS -lxnet"               # Use the XOPEN network library

	    SHLIB_SUFFIX=".sl"
	    AC_CHECK_LIB(dld, shl_load, tcl_ok=yes, tcl_ok=no)
	    if test "$tcl_ok" = yes; then
		SHLIB_CFLAGS="+z"
		SHLIB_LD="ld -b"
		SHLIB_LD_LIBS='${LIBS}'
		DL_OBJS="tclLoadShl.o"
		DL_LIBS="-ldld"
		LDFLAGS="$LDFLAGS -Wl,-E"
		CC_SEARCH_FLAGS='-Wl,+s,+b,${LIB_RUNTIME_DIR}:${LIB_PGTCL_RUNTIME_DIR}:.'
		LD_SEARCH_FLAGS='+s +b ${LIB_RUNTIME_DIR}:${LIB_PGTCL_RUNTIME_DIR}:.'
		LD_LIBRARY_PATH_VAR="SHLIB_PATH"
	    fi
	    if test "$GCC" = "yes" ; then
		SHLIB_LD="gcc -shared"
		SHLIB_LD_LIBS='${LIBS}'
		LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}
	    fi

	    # Users may want PA-RISC 1.1/2.0 portable code - needs HP cc
	    #CFLAGS="$CFLAGS +DAportable"

	    # Check to enable 64-bit flags for compiler/linker
	    if test "$do64bit" = "yes" ; then
		if test "$GCC" = "yes" ; then
		    hpux_arch=`${CC} -dumpmachine`
		    case $hpux_arch in
			hppa64*)
			    # 64-bit gcc in use.  Fix flags for GNU ld.
			    do64bit_ok=yes
			    SHLIB_LD="${CC} -shared"
			    SHLIB_LD_LIBS='${LIBS}'
			    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
			    LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}
			    ;;
			*)
			    AC_MSG_WARN([64bit mode not supported with GCC on $system])
			    ;;
		    esac
		else
		    do64bit_ok=yes
		    CFLAGS="$CFLAGS +DD64"
		    LDFLAGS_ARCH="+DD64"
		fi
	    fi
	    ;;
	HP-UX-*.08.*|HP-UX-*.09.*|HP-UX-*.10.*)
	    SHLIB_SUFFIX=".sl"
	    AC_CHECK_LIB(dld, shl_load, tcl_ok=yes, tcl_ok=no)
	    if test "$tcl_ok" = yes; then
		SHLIB_CFLAGS="+z"
		SHLIB_LD="ld -b"
		SHLIB_LD_LIBS=""
		DL_OBJS="tclLoadShl.o"
		DL_LIBS="-ldld"
		LDFLAGS="$LDFLAGS -Wl,-E"
		CC_SEARCH_FLAGS='-Wl,+s,+b,${LIB_RUNTIME_DIR}:${LIB_PGTCL_RUNTIME_DIR}:.'
		LD_SEARCH_FLAGS='+s +b ${LIB_RUNTIME_DIR}:${LIB_PGTCL_RUNTIME_DIR}:.'
		LD_LIBRARY_PATH_VAR="SHLIB_PATH"
	    fi
	    ;;
	IRIX-5.*)
	    SHLIB_CFLAGS=""
	    SHLIB_LD="ld -shared -rdata_shared"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS='-rpath ${LIB_RUNTIME_DIR} -rpath ${LIB_PGTCL_RUNTIME_DIR}'
	    ;;
	IRIX-6.*)
	    SHLIB_CFLAGS=""
	    SHLIB_LD="ld -n32 -shared -rdata_shared"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS='-rpath ${LIB_RUNTIME_DIR} -rpath ${LIB_PGTCL_RUNTIME_DIR}'
	    if test "$GCC" = "yes" ; then
		CFLAGS="$CFLAGS -mabi=n32"
		LDFLAGS="$LDFLAGS -mabi=n32"
	    else
		case $system in
		    IRIX-6.3)
			# Use to build 6.2 compatible binaries on 6.3.
			CFLAGS="$CFLAGS -n32 -D_OLD_TERMIOS"
			;;
		    *)
			CFLAGS="$CFLAGS -n32"
			;;
		esac
		LDFLAGS="$LDFLAGS -n32"
	    fi
	    ;;
	IRIX64-6.*)
	    SHLIB_CFLAGS=""
	    SHLIB_LD="ld -n32 -shared -rdata_shared"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS='-rpath ${LIB_RUNTIME_DIR} -rpath ${LIB_PGTCL_RUNTIME_DIR}'

	    # Check to enable 64-bit flags for compiler/linker

	    if test "$do64bit" = "yes" ; then
	        if test "$GCC" = "yes" ; then
	            AC_MSG_WARN([64bit mode not supported by gcc])
	        else
	            do64bit_ok=yes
	            SHLIB_LD="ld -64 -shared -rdata_shared"
	            CFLAGS="$CFLAGS -64"
	            LDFLAGS_ARCH="-64"
	        fi
	    fi
	    ;;
	Linux*)
	    SHLIB_CFLAGS="-fPIC"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"

	    CFLAGS_OPTIMIZE="-O2 -fomit-frame-pointer"
	    # egcs-2.91.66 on Redhat Linux 6.0 generates lots of warnings 
	    # when you inline the string and math operations.  Turn this off to
	    # get rid of the warnings.
	    #CFLAGS_OPTIMIZE="${CFLAGS_OPTIMIZE} -D__NO_STRING_INLINES -D__NO_MATH_INLINES"

	    SHLIB_LD="${CC} -shared"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    LDFLAGS="$LDFLAGS -Wl,--export-dynamic"
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}
	    if test "`uname -m`" = "alpha" ; then
		CFLAGS="$CFLAGS -mieee"
	    fi

	    # The combo of gcc + glibc has a bug related
	    # to inlining of functions like strtod(). The
	    # -fno-builtin flag should address this problem
	    # but it does not work. The -fno-inline flag
	    # is kind of overkill but it works.
	    # Disable inlining only when one of the
	    # files in compat/*.c is being linked in.
	    if test x"${USE_COMPAT}" != x ; then
	        CFLAGS="$CFLAGS -fno-inline"
	    fi

	    ;;
	GNU*)
	    SHLIB_CFLAGS="-fPIC"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"

	    SHLIB_LD="${CC} -shared"
	    DL_OBJS=""
	    DL_LIBS="-ldl"
	    LDFLAGS="$LDFLAGS -Wl,--export-dynamic"
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    if test "`uname -m`" = "alpha" ; then
		CFLAGS="$CFLAGS -mieee"
	    fi
	    ;;
	Lynx*)
	    SHLIB_CFLAGS="-fPIC"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    CFLAGS_OPTIMIZE=-02
	    SHLIB_LD="${CC} -shared "
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-mshared -ldl"
	    LD_FLAGS="-Wl,--export-dynamic"
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    ;;
	MP-RAS-02*)
	    SHLIB_CFLAGS="-K PIC"
	    SHLIB_LD="cc -G"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	MP-RAS-*)
	    SHLIB_CFLAGS="-K PIC"
	    SHLIB_LD="cc -G"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    LDFLAGS="$LDFLAGS -Wl,-Bexport"
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	NetBSD-*|FreeBSD-[[1-2]].*)
	    # NetBSD/SPARC needs -fPIC, -fpic will not do.
	    SHLIB_CFLAGS="-fPIC"
	    SHLIB_LD="ld -Bshareable -x"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS='-rpath ${LIB_RUNTIME_DIR} -rpath ${LIB_PGTCL_RUNTIME_DIR}'
	    AC_CACHE_CHECK([for ELF], tcl_cv_ld_elf, [
		AC_EGREP_CPP(yes, [
#ifdef __ELF__
	yes
#endif
		], tcl_cv_ld_elf=yes, tcl_cv_ld_elf=no)])
	    if test $tcl_cv_ld_elf = yes; then
		SHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.so'
	    else
		SHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.so.1.0'
	    fi

	    # Ancient FreeBSD doesn't handle version numbers with dots.

	    UNSHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.a'
	    TCL_LIB_VERSIONS_OK=nodots
	    ;;
	OpenBSD-*)
	    # OpenBSD/SPARC[64] needs -fPIC, -fpic will not do.
	    case `machine` in
	    sparc|sparc64)
		SHLIB_CFLAGS="-fPIC";;
	    *)
		SHLIB_CFLAGS="-fpic";;
	    esac
	    SHLIB_LD="${CC} -shared ${SHLIB_CFLAGS}"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}
	    SHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.so.1.0'
	    AC_CACHE_CHECK([for ELF], tcl_cv_ld_elf, [
		AC_EGREP_CPP(yes, [
#ifdef __ELF__
	yes
#endif
		], tcl_cv_ld_elf=yes, tcl_cv_ld_elf=no)])
	    if test $tcl_cv_ld_elf = yes; then
		LDFLAGS=-Wl,-export-dynamic
	    else
		LDFLAGS=""
	    fi

	    # OpenBSD doesn't do version numbers with dots.
	    UNSHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.a'
	    TCL_LIB_VERSIONS_OK=nodots
	    ;;
	FreeBSD-*)
	    # FreeBSD 3.* and greater have ELF.
	    SHLIB_CFLAGS="-fPIC"
	    SHLIB_LD="ld -Bshareable -x"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    LDFLAGS="$LDFLAGS -export-dynamic"
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS='-rpath ${LIB_RUNTIME_DIR} -rpath ${LIB_PGTCL_RUNTIME_DIR}'
	    if test "${TCL_THREADS}" = "1" ; then
		# The -pthread needs to go in the CFLAGS, not LIBS
		LIBS=`echo $LIBS | sed s/-pthread//`
		CFLAGS="$CFLAGS -pthread"
	    	LDFLAGS="$LDFLAGS -pthread"
	    fi
	    case $system in
	    FreeBSD-3.*)
	    	# FreeBSD-3 doesn't handle version numbers with dots.
	    	UNSHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.a'
	    	SHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.so'
	    	TCL_LIB_VERSIONS_OK=nodots
		;;
	    esac
	    ;;
	Darwin-*)
	    CFLAGS_OPTIMIZE="-Os"
	    SHLIB_CFLAGS="-fno-common"
	    if test $do64bit = yes; then
	        do64bit_ok=yes
	        CFLAGS="$CFLAGS -arch ppc64 -mpowerpc64 -mcpu=G5"
	    fi
	    # TEA specific: use LDFLAGS_DEFAULT instead of LDFLAGS here:
	    SHLIB_LD='${CC} -dynamiclib ${CFLAGS} ${LDFLAGS_DEFAULT}'
	    AC_CACHE_CHECK([if ld accepts -single_module flag], tcl_cv_ld_single_module, [
	        hold_ldflags=$LDFLAGS
	        LDFLAGS="$LDFLAGS -dynamiclib -Wl,-single_module"
	        AC_TRY_LINK(, [int i;], tcl_cv_ld_single_module=yes, tcl_cv_ld_single_module=no)
	        LDFLAGS=$hold_ldflags])
	    if test $tcl_cv_ld_single_module = yes; then
	        SHLIB_LD="${SHLIB_LD} -Wl,-single_module"
	    fi
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".dylib"
	    DL_OBJS="tclLoadDyld.o"
	    DL_LIBS=""
	    # Don't use -prebind when building for Mac OS X 10.4 or later only:
	    test -z "${MACOSX_DEPLOYMENT_TARGET}" || \
		test "`echo "${MACOSX_DEPLOYMENT_TARGET}" | awk -F. '{print [$]2}'`" -lt 4 && \
		LDFLAGS="$LDFLAGS -prebind"
	    LDFLAGS="$LDFLAGS -headerpad_max_install_names"
	    AC_CACHE_CHECK([if ld accepts -search_paths_first flag], tcl_cv_ld_search_paths_first, [
	        hold_ldflags=$LDFLAGS
	        LDFLAGS="$LDFLAGS -Wl,-search_paths_first"
	        AC_TRY_LINK(, [int i;], tcl_cv_ld_search_paths_first=yes, tcl_cv_ld_search_paths_first=no)
	        LDFLAGS=$hold_ldflags])
	    if test $tcl_cv_ld_search_paths_first = yes; then
	        LDFLAGS="$LDFLAGS -Wl,-search_paths_first"
	    fi
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    LD_LIBRARY_PATH_VAR="DYLD_LIBRARY_PATH"

	    # TEA specific: for Tk extensions, remove -arch ppc64 from CFLAGS
	    # for fat builds, as neither TkAqua nor TkX11 can be built for 64bit
	    # at present (no 64bit GUI libraries).
	    test $do64bit_ok = no && test -n "${TK_BIN_DIR}" && \
	        CFLAGS="`echo "$CFLAGS" | sed -e 's/-arch ppc64/-arch ppc/g'`"
	    ;;
	NEXTSTEP-*)
	    SHLIB_CFLAGS=""
	    SHLIB_LD="cc -nostdlib -r"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadNext.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	OS/390-*)
	    CFLAGS_OPTIMIZE=""		# Optimizer is buggy
	    AC_DEFINE(_OE_SOCKETS, 1,	# needed in sys/socket.h
		[Should OS/390 do the right thing with sockets?])
	    ;;      
	OSF1-1.0|OSF1-1.1|OSF1-1.2)
	    # OSF/1 1.[012] from OSF, and derivatives, including Paragon OSF/1
	    SHLIB_CFLAGS=""
	    # Hack: make package name same as library name
	    SHLIB_LD='ld -R -export $@:'
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadOSF.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	OSF1-1.*)
	    # OSF/1 1.3 from OSF using ELF, and derivatives, including AD2
	    SHLIB_CFLAGS="-fPIC"
	    if test "$SHARED_BUILD" = "1" ; then
	        SHLIB_LD="ld -shared"
	    else
	        SHLIB_LD="ld -non_shared"
	    fi
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	OSF1-V*)
	    # Digital OSF/1
	    SHLIB_CFLAGS=""
	    if test "$SHARED_BUILD" = "1" ; then
	        SHLIB_LD='ld -shared -expect_unresolved "*"'
	    else
	        SHLIB_LD='ld -non_shared -expect_unresolved "*"'
	    fi
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS='-rpath ${LIB_RUNTIME_DIR} -rpath ${LIB_PGTCL_RUNTIME_DIR}'
	    if test "$GCC" = "yes" ; then
		CFLAGS="$CFLAGS -mieee"
            else
		CFLAGS="$CFLAGS -DHAVE_TZSET -std1 -ieee"
	    fi
	    # see pthread_intro(3) for pthread support on osf1, k.furukawa
	    if test "${TCL_THREADS}" = "1" ; then
		CFLAGS="$CFLAGS -DHAVE_PTHREAD_ATTR_SETSTACKSIZE"
		CFLAGS="$CFLAGS -DTCL_THREAD_STACK_MIN=PTHREAD_STACK_MIN*64"
		LIBS=`echo $LIBS | sed s/-lpthreads//`
		if test "$GCC" = "yes" ; then
		    LIBS="$LIBS -lpthread -lmach -lexc"
		else
		    CFLAGS="$CFLAGS -pthread"
		    LDFLAGS="$LDFLAGS -pthread"
		fi
	    fi

	    ;;
	QNX-6*)
	    # QNX RTP
	    # This may work for all QNX, but it was only reported for v6.
	    SHLIB_CFLAGS="-fPIC"
	    SHLIB_LD="ld -Bshareable -x"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    # dlopen is in -lc on QNX
	    DL_LIBS=""
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	SCO_SV-3.2*)
	    # Note, dlopen is available only on SCO 3.2.5 and greater. However,
	    # this test works, since "uname -s" was non-standard in 3.2.4 and
	    # below.
	    if test "$GCC" = "yes" ; then
	    	SHLIB_CFLAGS="-fPIC -melf"
	    	LDFLAGS="$LDFLAGS -melf -Wl,-Bexport"
	    else
	    	SHLIB_CFLAGS="-Kpic -belf"
	    	LDFLAGS="$LDFLAGS -belf -Wl,-Bexport"
	    fi
	    SHLIB_LD="ld -G"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	SINIX*5.4*)
	    SHLIB_CFLAGS="-K PIC"
	    SHLIB_LD="cc -G"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	SunOS-4*)
	    SHLIB_CFLAGS="-PIC"
	    SHLIB_LD="ld"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    CC_SEARCH_FLAGS='-L${LIB_RUNTIME_DIR} -L${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}

	    # SunOS can't handle version numbers with dots in them in library
	    # specs, like -ltcl7.5, so use -ltcl75 instead.  Also, it
	    # requires an extra version number at the end of .so file names.
	    # So, the library has to have a name like libtcl75.so.1.0

	    SHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.so.1.0'
	    UNSHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.a'
	    TCL_LIB_VERSIONS_OK=nodots
	    ;;
	SunOS-5.[[0-6]])
	    # Careful to not let 5.10+ fall into this case

	    # Note: If _REENTRANT isn't defined, then Solaris
	    # won't define thread-safe library routines.

	    AC_DEFINE(_REENTRANT, 1, [Do we want the reentrant OS API?])
	    AC_DEFINE(_POSIX_PTHREAD_SEMANTICS, 1,
		[Do we really want to follow the standard? Yes we do!])

	    SHLIB_CFLAGS="-KPIC"

	    # Note: need the LIBS below, otherwise Tk won't find Tcl's
	    # symbols when dynamically loaded into tclsh.

	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    if test "$GCC" = "yes" ; then
		SHLIB_LD="$CC -shared"
		CC_SEARCH_FLAGS='-Wl,-R,${LIB_RUNTIME_DIR},-R,${LIB_PGTCL_RUNTIME_DIR}'
		LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}
	    else
		SHLIB_LD="/usr/ccs/bin/ld -G -z text"
		CC_SEARCH_FLAGS='-R ${LIB_RUNTIME_DIR} -R ${LIB_PGTCL_RUNTIME_DIR}'
		LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}
	    fi
	    ;;
	SunOS-5*)
	    # Note: If _REENTRANT isn't defined, then Solaris
	    # won't define thread-safe library routines.

	    AC_DEFINE(_REENTRANT, 1, [Do we want the reentrant OS API?])
	    AC_DEFINE(_POSIX_PTHREAD_SEMANTICS, 1,
		[Do we really want to follow the standard? Yes we do!])

	    SHLIB_CFLAGS="-KPIC"

	    # Check to enable 64-bit flags for compiler/linker
	    if test "$do64bit" = "yes" ; then
		arch=`isainfo`
		if test "$arch" = "sparcv9 sparc" ; then
			if test "$GCC" = "yes" ; then
			    if test "`gcc -dumpversion | awk -F. '{print [$]1}'`" -lt "3" ; then
				AC_MSG_WARN([64bit mode not supported with GCC < 3.2 on $system])
			    else
				do64bit_ok=yes
				CFLAGS="$CFLAGS -m64 -mcpu=v9"
				LDFLAGS="$LDFLAGS -m64 -mcpu=v9"
				SHLIB_CFLAGS="-fPIC"
			    fi
			else
			    do64bit_ok=yes
			    if test "$do64bitVIS" = "yes" ; then
				CFLAGS="$CFLAGS -xarch=v9a"
			    	LDFLAGS_ARCH="-xarch=v9a"
			    else
				CFLAGS="$CFLAGS -xarch=v9"
			    	LDFLAGS_ARCH="-xarch=v9"
			    fi
			    # Solaris 64 uses this as well
			    #LD_LIBRARY_PATH_VAR="LD_LIBRARY_PATH_64"
			fi
		elif test "$arch" = "amd64 i386" ; then
		    if test "$GCC" = "yes" ; then
			AC_MSG_WARN([64bit mode not supported with GCC on $system])
		    else
			do64bit_ok=yes
			CFLAGS="$CFLAGS -xarch=amd64"
			LDFLAGS="$LDFLAGS -xarch=amd64"
		    fi
		else
		    AC_MSG_WARN([64bit mode not supported for $arch])
		fi
	    fi
	    
	    # Note: need the LIBS below, otherwise Tk won't find Tcl's
	    # symbols when dynamically loaded into tclsh.

	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    if test "$GCC" = "yes" ; then
		SHLIB_LD="$CC -shared"
		CC_SEARCH_FLAGS='-Wl,-R,${LIB_RUNTIME_DIR},-R,${LIB_PGTCL_RUNTIME_DIR}'
		LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}
		if test "$do64bit_ok" = "yes" ; then
		    # We need to specify -static-libgcc or we need to
		    # add the path to the sparv9 libgcc.
		    # JH: static-libgcc is necessary for core Tcl, but may
		    # not be necessary for extensions.
		    SHLIB_LD="$SHLIB_LD -m64 -mcpu=v9 -static-libgcc"
		    # for finding sparcv9 libgcc, get the regular libgcc
		    # path, remove so name and append 'sparcv9'
		    #v9gcclibdir="`gcc -print-file-name=libgcc_s.so` | ..."
		    #CC_SEARCH_FLAGS="${CC_SEARCH_FLAGS},-R,$v9gcclibdir"
		fi
	    else
		SHLIB_LD="/usr/ccs/bin/ld -G -z text"
		CC_SEARCH_FLAGS='-Wl,-R,${LIB_RUNTIME_DIR},-R,${LIB_PGTCL_RUNTIME_DIR}'
		LD_SEARCH_FLAGS='-R ${LIB_RUNTIME_DIR} -R ${LIB_PGTCL_RUNTIME_DIR}'
	    fi
	    ;;
	UNIX_SV* | UnixWare-5*)
	    SHLIB_CFLAGS="-KPIC"
	    SHLIB_LD="cc -G"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    # Some UNIX_SV* systems (unixware 1.1.2 for example) have linkers
	    # that don't grok the -Bexport option.  Test that it does.
	    AC_CACHE_CHECK([for ld accepts -Bexport flag], tcl_cv_ld_Bexport, [
		hold_ldflags=$LDFLAGS
		LDFLAGS="$LDFLAGS -Wl,-Bexport"
		AC_TRY_LINK(, [int i;], tcl_cv_ld_Bexport=yes, tcl_cv_ld_Bexport=no)
	        LDFLAGS=$hold_ldflags])
	    if test $tcl_cv_ld_Bexport = yes; then
		LDFLAGS="$LDFLAGS -Wl,-Bexport"
	    fi
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
    esac

    if test "$do64bit" = "yes" -a "$do64bit_ok" = "no" ; then
	AC_MSG_WARN([64bit support being disabled -- don't know magic for this platform])
    fi

    # Step 4: disable dynamic loading if requested via a command-line switch.

    AC_ARG_ENABLE(load,
	AC_HELP_STRING([--disable-load],
	    [disallow dynamic loading and "load" command (default: enabled)]),
	[tcl_ok=$enableval], [tcl_ok=yes])
    if test "$tcl_ok" = "no"; then
	DL_OBJS=""
    fi

    if test "x$DL_OBJS" != "x" ; then
	BUILD_DLTEST="\$(DLTEST_TARGETS)"
    else
	echo "Can't figure out how to do dynamic loading or shared libraries"
	echo "on this system."
	SHLIB_CFLAGS=""
	SHLIB_LD=""
	SHLIB_SUFFIX=""
	DL_OBJS="tclLoadNone.o"
	DL_LIBS=""
	LDFLAGS="$LDFLAGS_ORIG"
	CC_SEARCH_FLAGS=""
	LD_SEARCH_FLAGS=""
	BUILD_DLTEST=""
    fi
    LDFLAGS="$LDFLAGS $LDFLAGS_ARCH"

    # If we're running gcc, then change the C flags for compiling shared
    # libraries to the right flags for gcc, instead of those for the
    # standard manufacturer compiler.

    if test "$DL_OBJS" != "tclLoadNone.o" ; then
	if test "$GCC" = "yes" ; then
	    case $system in
		AIX-*)
		    ;;
		BSD/OS*)
		    ;;
		IRIX*)
		    ;;
		NetBSD-*|FreeBSD-*)
		    ;;
		Darwin-*)
		    ;;
		SCO_SV-3.2*)
		    ;;
		windows)
		    ;;
		*)
		    SHLIB_CFLAGS="-fPIC"
		    ;;
	    esac
	fi
    fi

    if test "$SHARED_LIB_SUFFIX" = "" ; then
	SHARED_LIB_SUFFIX='${PACKAGE_VERSION}${SHLIB_SUFFIX}'
    fi
    if test "$UNSHARED_LIB_SUFFIX" = "" ; then
	UNSHARED_LIB_SUFFIX='${PACKAGE_VERSION}.a'
    fi

    AC_SUBST(DL_LIBS)

    AC_SUBST(CFLAGS_DEBUG)
    AC_SUBST(CFLAGS_OPTIMIZE)
    AC_SUBST(CFLAGS_WARNING)

    AC_SUBST(STLIB_LD)
    AC_SUBST(SHLIB_LD)

    AC_SUBST(SHLIB_LD_LIBS)
    AC_SUBST(SHLIB_CFLAGS)

    AC_SUBST(LD_LIBRARY_PATH_VAR)

    # These must be called after we do the basic CFLAGS checks and
    # verify any possible 64-bit or similar switches are necessary
    TEA_TCL_EARLY_FLAGS
    TEA_TCL_64BIT_FLAGS
])


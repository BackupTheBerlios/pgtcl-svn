/*-------------------------------------------------------------------------
 *
 * pgtcl-int.h
 *
 *  Internal definitions.
 *
 * Portions Copyright (c) 1996-2006, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 * Portions Copyright (c) 2002-2006, GBorg Pgtcl project
 * Portions Copyright (c) 2002-2006, GBorg PgtclNG project
 * Portions Copyright (c) 2005, TCLUDP project
 *
 * Identification:
 *
 *  $Id: pgtcl-int.h 17 2006-03-12 13:41:12Z andrew $
 *
 *-------------------------------------------------------------------------
 */

#ifndef PGTCL_INT_H
#define PGTCL_INT_H

#if defined(_WIN32) && !defined(WIN32)
#    define WIN32
#endif

#ifdef HAVE_CONFIG_H
#    include "../config.h"
#endif

#include "tcl.h"

/* Tcl 8.4 CONST support */
#ifndef CONST84
#    define CONST84
#endif

#ifdef BUILD_pgtcl
#    undef TCL_STORAGE_CLASS
#    define TCL_STORAGE_CLASS DLLEXPORT
#endif /* BUILD_pgtcl */

#endif /* PGTCL_INT_H */

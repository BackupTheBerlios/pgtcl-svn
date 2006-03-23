/*-------------------------------------------------------------------------
 *
 * pgtcl.h
 *
 *  Pgtcl is a tcl package for front-ends to interface with PostgreSQL.
 *  It's a Tcl wrapper for libpq.
 *
 * Portions Copyright (c) 1996-2006, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 * Portions Copyright (c) 2002-2006, GBorg Pgtcl project
 * Portions Copyright (c) 2002-2006, GBorg PgtclNG project
 * Portions Copyright (c) 2005, TCLUDP project
 *
 * Original code:
 *
 *  $RCS: libpgtcl.h,v 1.3 2004/06/24 05:02:16 schwarzkopf Exp $
 *
 * Identification:
 *
 *  $Id: pgtcl.h 25 2006-03-16 20:25:13Z andrew $
 *
 *-------------------------------------------------------------------------
 */

#ifndef PGTCL_H
#define PGTCL_H

#include "tcl.h"
#include "pgtcl-int.h"

EXTERN int Pgtcl_Init(Tcl_Interp *interp);
EXTERN int Pgtcl_SafeInit(Tcl_Interp *interp);

#endif /* PGTCL_H */

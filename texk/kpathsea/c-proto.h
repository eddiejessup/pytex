/* c-proto.h: macros to include or discard prototypes.

Copyright (C) 1992, 93, 95, 96, 2000 Free Software Foundation, Inc.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.  */

#ifndef KPATHSEA_C_PROTO_H
#define KPATHSEA_C_PROTO_H

#if defined(WIN32)
#ifdef KPSE_DLL
#ifdef MAKE_KPSE_DLL
#define KPSEDLL __declspec( dllexport)
#else
#define KPSEDLL __declspec( dllimport)
#endif
#else
#define KPSEDLL
#endif
#else /* ! WIN32 */
#define KPSEDLL
#endif


/* These macros munge function declarations to make them work in both
   cases.  The P?H macros are used for declarations, the P?C for
   definitions.  Cf. <ansidecl.h> from the GNU C library.  P1H(void)
   also works for definitions of routines which take no args.  */

#define AA(args) args /* For an arbitrary number; ARGS must be in parens.  */

#define P1H(p1) (p1)
#define P2H(p1,p2) (p1, p2)
#define P3H(p1,p2,p3) (p1, p2, p3)
#define P4H(p1,p2,p3,p4) (p1, p2, p3, p4)
#define P5H(p1,p2,p3,p4,p5) (p1, p2, p3, p4, p5)
#define P6H(p1,p2,p3,p4,p5,p6) (p1, p2, p3, p4, p5, p6)
#define P7H(p1,p2,p3,p4,p5,p6,p7) (p1, p2, p3, p4, p5, p6, p7)
#define P8H(p1,p2,p3,p4,p5,p6,p7,p8) (p1, p2, p3, p4, p5, p6, p7, p8)
#define P9H(p1,p2,p3,p4,p5,p6,p7,p8,p9) (p1, p2, p3, p4, p5, p6, p7, p8, p9)
#define P10H(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10) \
  (p1,p2,p3,p4,p5,p6,p7,p8,p9,p10)
#define P11H(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11) \
  (p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11)
#define P12H(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12) \
  (p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12)
#define P13H(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13) \
  (p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13)
#define P14H(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14) \
  (p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14)
#define P15H(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15) \
  (p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15)
#define P16H(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16) \
  (p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16)
#define P17H(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17) \
  (p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17)


#define P1C(t1,n1)(t1 n1)
#define P2C(t1,n1, t2,n2)(t1 n1, t2 n2)
#define P3C(t1,n1, t2,n2, t3,n3)(t1 n1, t2 n2, t3 n3)
#define P4C(t1,n1, t2,n2, t3,n3, t4,n4)(t1 n1, t2 n2, t3 n3, t4 n4)
#define P5C(t1,n1, t2,n2, t3,n3, t4,n4, t5,n5) \
  (t1 n1, t2 n2, t3 n3, t4 n4, t5 n5)
#define P6C(t1,n1, t2,n2, t3,n3, t4,n4, t5,n5, t6,n6) \
  (t1 n1, t2 n2, t3 n3, t4 n4, t5 n5, t6 n6)
#define P7C(t1,n1, t2,n2, t3,n3, t4,n4, t5,n5, t6,n6, t7,n7) \
  (t1 n1, t2 n2, t3 n3, t4 n4, t5 n5, t6 n6, t7 n7)
#define P8C(t1,n1, t2,n2, t3,n3, t4,n4, t5,n5, t6,n6, t7,n7, t8,n8) \
  (t1 n1, t2 n2, t3 n3, t4 n4, t5 n5, t6 n6, t7 n7, t8 n8)
#define P9C(t1,n1, t2,n2, t3,n3, t4,n4, t5,n5, t6,n6, t7,n7, t8,n8, t9,n9) \
  (t1 n1, t2 n2, t3 n3, t4 n4, t5 n5, t6 n6, t7 n7, t8 n8, t9 n9)
#define P10C(t1,n1,t2,n2,t3,n3,t4,n4,t5,n5,t6,n6,t7,n7,t8,n8,t9,n9,t10,n10) \
  (t1 n1, t2 n2, t3 n3, t4 n4, t5 n5, t6 n6, t7 n7, t8 n8, t9 n9, t10 n10)
#define P11C(t1,n1,t2,n2,t3,n3,t4,n4,t5,n5,t6,n6,t7,n7,t8,n8,t9,n9,t10,n10,t11,n11) \
  (t1 n1, t2 n2, t3 n3, t4 n4, t5 n5, t6 n6, t7 n7, t8 n8, t9 n9, t10 n10, \
   t11 n11)
#define P12C(t1,n1,t2,n2,t3,n3,t4,n4,t5,n5,t6,n6,t7,n7,t8,n8,t9,n9,t10,n10,t11,n11,t12,n12) \
  (t1 n1, t2 n2, t3 n3, t4 n4, t5 n5, t6 n6, t7 n7, t8 n8, t9 n9, t10 n10, \
   t11 n11, t12 n12)
#define P13C(t1,n1,t2,n2,t3,n3,t4,n4,t5,n5,t6,n6,t7,n7,t8,n8,t9,n9,t10,n10,t11,n11,t12,n12,t13,n13) \
  (t1 n1, t2 n2, t3 n3, t4 n4, t5 n5, t6 n6, t7 n7, t8 n8, t9 n9, t10 n10, \
   t11 n11, t12 n12, t13 n13)
#define P14C(t1,n1,t2,n2,t3,n3,t4,n4,t5,n5,t6,n6,t7,n7,t8,n8,t9,n9,t10,n10,t11,n11,t12,n12,t13,n13,t14,n14) \
  (t1 n1, t2 n2, t3 n3, t4 n4, t5 n5, t6 n6, t7 n7, t8 n8, t9 n9, t10 n10, \
   t11 n11, t12 n12, t13 n13, t14 n14)
#define P15C(t1,n1,t2,n2,t3,n3,t4,n4,t5,n5,t6,n6,t7,n7,t8,n8,t9,n9,t10,n10,t11,n11,t12,n12,t13,n13,t14,n14,t15,n15) \
  (t1 n1, t2 n2, t3 n3, t4 n4, t5 n5, t6 n6, t7 n7, t8 n8, t9 n9, t10 n10, \
   t11 n11, t12 n12, t13 n13, t14 n14, t15 n15)
#define P16C(t1,n1,t2,n2,t3,n3,t4,n4,t5,n5,t6,n6,t7,n7,t8,n8,t9,n9,t10,n10,t11,n11,t12,n12,t13,n13,t14,n14,t15,n15,t16,n16) \
  (t1 n1, t2 n2, t3 n3, t4 n4, t5 n5, t6 n6, t7 n7, t8 n8, t9 n9, t10 n10, \
   t11 n11, t12 n12, t13 n13, t14 n14, t15 n15, t16 n16)
#define P17C(t1,n1,t2,n2,t3,n3,t4,n4,t5,n5,t6,n6,t7,n7,t8,n8,t9,n9,t10,n10,t11,n11,t12,n12,t13,n13,t14,n14,t15,n15,t16,n16,t17,n17) \
  (t1 n1, t2 n2, t3 n3, t4 n4, t5 n5, t6 n6, t7 n7, t8 n8, t9 n9, t10 n10, \
   t11 n11, t12 n12, t13 n13, t14 n14, t15 n15, t16 n16, t17 n17)

#endif /* not KPATHSEA_C_PROTO_H */

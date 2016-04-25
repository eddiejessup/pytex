#ifndef TEX_MAIN_H
#define TEX_MAIN_H

#include "globals.h"
#include "types.h"

EXTERN void         main_init (int ac, string * av);
EXTERN int          main (int ac,  string *av);
EXTERN void         get_date_and_time (integer *,integer *,integer *, integer *);
EXTERN integer      getrandomseed(void);
EXTERN void         setup_bound_variable (integer * var,  const_string var_name,  integer dflt);
int main_body (void);

#endif /* not TEX_MAIN_H */

#ifndef TEX_MAIN_H
#define TEX_MAIN_H

#include "globals.h"
#include "types.h"

EXTERN integer      getrandomseed(void);
EXTERN void         setup_bound_variable (integer * var,  const_string var_name,  integer dflt);
void allocate_memory_for_arrays(void);
void parse_options(int, string *);
void initialize(void);
void init_prim(int noninit);
void init_etex_prim(void);
void final_cleanup(void);

extern int argc;
extern char **argv;
extern char *user_progname;
extern long mem_top;
extern long mem_min;
extern long mem_max;

/* lib defines these*/
void usage(const_string str);
void usagehelp(const_string *message);
// Do not make the banner dummy argument `banner`, because this is a macro
void printversionandexit(const_string the_banner,
                         const_string copyright_holder,
                         const_string author);

#endif /* not TEX_MAIN_H */

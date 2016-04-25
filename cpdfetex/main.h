#ifndef TEX_MAIN_H
#define TEX_MAIN_H

#include "globals.h"
#include "types.h"

EXTERN void         main_init (int ac, string * av);
EXTERN int          main (int ac,  string *av);
EXTERN void         get_date_and_time (integer *,integer *,integer *, integer *);
EXTERN integer      getrandomseed(void);
EXTERN void         setup_bound_variable (integer * var,  const_string var_name,  integer dflt);
void set_up_bound_variables(void);
int main_body (void);
void parse_options(int, string *);

extern int argc;
extern char **argv;
extern char *user_progname;

/* lib defines these*/
void usage(const_string str);
void usagehelp(const_string *message);
// Do not make the banner dummy argument `banner`, because this is a macro
void printversionandexit(const_string the_banner,
                         const_string copyright_holder,
                         const_string author);

#endif /* not TEX_MAIN_H */

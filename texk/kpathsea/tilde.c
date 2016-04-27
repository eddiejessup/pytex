/* tilde.c: Expand user's home directories.

Copyright (C) 1993, 95, 96, 97 Karl Berry.

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

#include <kpathsea/config.h>

#include <kpathsea/c-pathch.h>
#include <kpathsea/tilde.h>

#include <pwd.h>
#include <unistd.h>


/* If NAME has a leading ~ or ~user, Unix-style, expand it to the user's
   home directory, and return a new malloced string.  If no ~, or no
   <pwd.h>, just return NAME.  */

string
kpse_tilde_expand P1C(const_string, name)
{
  const_string expansion;
  const_string home;
  
  assert (name);
  
  /* If no leading tilde, do nothing.  */
  if (*name != '~') {
    expansion = name;
  
  /* If a bare tilde, return the home directory or `.'.  (Very unlikely
     that the directory name will do anyone any good, but ...  */
  } else if (name[1] == 0) {
    home = getenv ("HOME");
    if (!home) {
      home = ".";
    }
    expansion = xstrdup (home);
  
  /* If `~/', remove any trailing / or replace leading // in $HOME.
     Should really check for doubled intermediate slashes, too.  */
  } else if (IS_DIR_SEP (name[1])) {
    unsigned c = 1;
    home = getenv ("HOME");
    if (!home) {
      home = ".";
    }
    if (IS_DIR_SEP (*home) && IS_DIR_SEP (home[1])) {  /* handle leading // */
      home++;
    }
    if (IS_DIR_SEP (home[strlen (home) - 1])) {        /* omit / after ~ */
      c++;
    }
    expansion = concat (home, name + c);
  
  /* If `~user' or `~user/', look up user in the passwd database (but
     OS/2 doesn't have this concept.  */
  } else {
    expansion = name;
  }
  /* We may return the same thing as the original, and then we might not
     be returning a malloc-ed string.  Callers beware.  Sorry.  */
  return (string) expansion;
}

#ifdef TEST

void
test_expand_tilde (const_string filename)
{
  string answer;
  
  printf ("Tilde expansion of `%s':\t", filename ? filename : "(nil)");
  answer = kpse_tilde_expand (filename);
  puts (answer);
}

int
main ()
{
  string tilde_path = "tilde";

  test_expand_tilde ("");
  test_expand_tilde ("none");
  test_expand_tilde ("~root");
  test_expand_tilde ("~");
  test_expand_tilde ("foo~bar");
  
  return 0;
}

#endif /* TEST */


/*
Local variables:
standalone-compile-command: "gcc -g -I. -I.. -DTEST tilde.c kpathsea.a"
End:
*/

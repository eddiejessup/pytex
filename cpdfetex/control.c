
#include "types.h"
#include "c-compat.h"

#include "globals.h"
#include "control.h"

/* forwards */
static boolean privileged (void);
static void issue_message (void);
static void shift_case (void);

/* module 1177 */
internal_font_number main_f; /* the current font */
four_quarters main_i; /* character information bytes for |cur_l| */
four_quarters main_j; /* ligature/kern command */
font_index main_k; /* index into |font_info| */
pointer main_p; /* temporary register for list manipulation */
int main_s; /* space factor value */
halfword bchar; /* right boundary character of current font, or |non_char| */
halfword false_bchar; /* nonexistent character matching |bchar|,  or |non_char| */
boolean cancel_boundary; /* should the left boundary be ignored? */
boolean ins_disc; /* should we INSERT_CODE a discretionary node? */


/* module comment 1174 */

/* 
 * We come now to the |main_control| routine, which contains the master
 * switch that causes all the various pieces of \TeX\ to do their things,
 * in the right order.
 * 
 * In a sense, this is the grand climax of the program: It applies all the
 * tools that we have worked so hard to construct. In another sense, this is
 * the messiest part of the program: It necessarily refers to other pieces
 * of code all over the place, so that a person can't fully understand what is
 * going on without paging back and forth to be reminded of conventions that
 * are defined elsewhere. We are now at the hub of the web, the central nervous
 * system that touches most of the other parts and ties them together.
 * 
 * The structure of |main_control| itself is quite simple. There's a label
 * called |BIG_SWITCH|, at which point the next token of input is fetched
 * using |get_x_token|. Then the program branches at high speed into one of
 * about 100 possible directions, based on the value of the current
 * MODE_FIELD and the newly fetched command code; the sum |abs(MODE_FIELD)+cur_cmd|
 * indicates what to do next. For example, the case `|vmode+letter|' arises
 * when a letter occurs in vertical MODE_FIELD (or internal vertical MODE_FIELD); this
 * case leads to instructions that initialize a new paragraph and enter
 * horizontal MODE_FIELD.
 * 
 * The big |case| statement that contains this multiway switch has been labeled
 * |reswitch|, so that the program can |goto reswitch| when the next token
 * has already been fetched. Most of the cases are quite short; they call
 * an ``action procedure'' that does the work for that case, and then they
 * either |goto reswitch| or they ``fall through'' to the end of the |case|
 * statement, which returns control back to |BIG_SWITCH|. Thus, |main_control|
 * is not an extremely large procedure, in spite of the multiplicity of things
 * it must do; it is small enough to be handled by \PASCAL\ compilers that put
 * severe restrictions on procedure size.
 * 
 * One case is singled out for special treatment, because it accounts for most
 * of \TeX's activities in typical applications. The process of reading simple
 * text and converting it into |char_node| records, while looking for ligatures
 * and kerns, is part of \TeX's ``inner loop''; the whole program runs
 * efficiently when its inner loop is fast, so this part has been written
 * with particular care.
 */

/* module 1179 */
#define adjust_space_factor  main_s   =  sf_code ( cur_chr );        \
    if (  main_s  == 1000  )   { space_factor   = 1000;              \
    } else  if (  main_s  < 1000  )  {                               \
      if (  main_s  > 0  )   space_factor   =  main_s ;}             \
      else if (  space_factor  < 1000  )  { space_factor   = 1000; } \
      else   space_factor   =  main_s

/* module 1180 */
/* If the current horizontal list is EMPTY_CODE, the reference to |character(tail)|
 * here is not strictly legal, since |tail| will be a node freshly returned by
 * |get_avail|. But this should cause no problem on most implementations, and we
 * do want the inner loop to be fast.
 * 
 * A discretionary break is not inserted for an explicit hyphen when we are in
 * restricted horizontal MODE_FIELD. In particular, this avoids putting discretionary
 * nodes inside of other discretionaries.
 */
/* Make a ligature node, if |ligature_present|; INSERT_CODE a null discretionary, if appropriate */
#define pack_lig( arg ) {                                                    \
   main_p   =  new_ligature ( main_f , cur_l , link ( cur_q ));              \
   if (  lft_hit  )  { subtype ( main_p )  = 2 ; lft_hit   =  false ;};      \
   if (  arg  ) { if (  lig_stack  ==  null  )  {                            \
      incr ( subtype ( main_p ));                                            \
      rt_hit   =  false ;};};                                                \
   link ( cur_q )  =  main_p ;                                               \
   tail   =  main_p ;                                                        \
   ligature_present   =  false ;}

#define wrapup( arg )   if (  cur_l  <  non_char  )  {                       \
        if (  character ( tail ) ==  qi ( hyphen_char [ main_f ]) )  {       \
          if (  link ( cur_q ) >  null  )  { ins_disc   =  true ; }}         \
        if (  ligature_present  )   pack_lig ( arg );                        \
        if (  ins_disc  )  { ins_disc   =  false ;                           \
          if (  MODE_FIELD  > 0  )   tail_append ( new_disc ());};}


/* module 1177 */

/* The following part of the program was first written in a structured
 * manner, according to the philosophy that ``premature optimization is
 * the root of all evil.'' Then it was rearranged into pieces of
 * spaghetti so that the most common actions could proceed with little or
 * no redundancy.
 * 
 * The original unoptimized form of this algorithm resembles the
 * |reconstitute| procedure, which was described earlier in connection with
 * hyphenation. Again we have an implied ``cursor'' between characters
 * |cur_l| and |cur_r|. The main difference is that the |lig_stack| can now
 * contain a charnode as well as pseudo-ligatures; that stack is now
 * usually nonempty, because the next character of input (if any) has been
 * appended to it. In |main_control| we have
 * $$|cur_r|=\cases{|character(lig_stack)|,&if |lig_stack>null|;\cr
 * 
 * |font_bchar[cur_font]|,&otherwise;\cr}$$
 * except when |character(lig_stack)=font_false_bchar[cur_font]|.
 * Several additional global variables are needed.
 */

#define ANY_MODE( arg )           vmode  +  arg: case hmode  +  arg: case mmode  +  arg
#define NON_MATH( arg )           vmode  +  arg: case hmode  +  arg


void append_normal_space(void) {
  /* begin expansion of Append a normal inter-word space to the current list, then |goto BIG_SWITCH| */
  /* module 1186 */
  /* The occurrence of blank spaces is almost part of \TeX's inner loop,
   * 
   * since we usually encounter about one space for every five non-blank characters.
   * Therefore |main_control| gives second-highest priority to ordinary spaces.
   * 
   * When a glue parameter like \.{\\spaceskip} is set to `\.{0pt}', we will
   * see to it later that the corresponding glue specification is precisely
   * |zero_glue|, not merely a pointer to some specification that happens
   * to be full of zeroes. Therefore it is simple to test whether a glue parameter
   * is zero or~not.
   */
  if (space_skip == zero_glue) {
	/* Find the glue specification, |main_p|, for text spaces in the current font */
	find_glue_spec;
	temp_ptr = new_glue (main_p);
  } else {
	temp_ptr = new_param_glue (space_skip_code);
  }
  link (tail) = temp_ptr;
  tail = temp_ptr;
  /* end expansion of Append a normal inter-word space to the current list, then |goto BIG_SWITCH| */
}


void handle_easy_cases(void) {
  switch (abs (MODE_FIELD) + cur_cmd) {
	/* module 1312 */
  case mmode + vcenter:
	scan_spec (vcenter_group, false);
	normal_paragraph();
	push_nest();
	MODE_FIELD = -vmode;
	prev_depth = ignore_depth;
	if (every_vbox != null)
	  begin_token_list (every_vbox, every_vbox_text);
	break;
	/* module 1316 */
  case mmode + math_style:
	tail_append (new_style (cur_chr));
	break;
  case mmode + non_script:
	tail_append (new_glue (zero_glue));
	subtype (tail) = cond_math_glue;
	break;
  case mmode + math_choice:
	append_choices();
	break;
	/* module 1320 */
	/* Subscripts and superscripts are attached to the previous nucleus by the
	 * 
	 * action procedure called |sub_sup|. We use the facts that |sub_mark=sup_mark+1|
	 * and |subscr(p)=supscr(p)+1|.
	 */
  case mmode + sub_mark:
  case mmode + sup_mark:
	sub_sup();
	break;
	/* module 1325 */
  case mmode + above:
	math_fraction();
	break;
	/* module 1335 */
  case mmode + left_right:
	math_left_right();
	break;
	/* module 1338 */
	/* Here is the only way out of math MODE_FIELD. */
  case mmode + math_shift:
	if (cur_group == math_shift_group) {
	  after_math();
	} else {
	  off_save();
	}
	break;
	/* end expansion of Cases of |main_control| that build boxes and lists */
	/* begin expansion of Cases of |main_control| that don't depend on |MODE_FIELD| */
	/* module 1355 */
	/* Every prefix, and every command code that might or might not be prefixed,
	 * calls the action procedure |prefixed_command|. This routine accumulates
	 * a sequence of prefixes until coming to a non-prefix, then it carries out
	 * the command.
	 */
  case ANY_MODE (toks_register):
  case ANY_MODE (assign_toks):
  case ANY_MODE (assign_int):
  case ANY_MODE (assign_dimen):
  case ANY_MODE (assign_glue):
  case ANY_MODE (assign_mu_glue):
  case ANY_MODE (assign_font_dimen):
  case ANY_MODE (assign_font_int):
  case ANY_MODE (set_aux):
  case ANY_MODE (set_prev_graf):
  case ANY_MODE (set_page_dimen):
  case ANY_MODE (set_page_int):
  case ANY_MODE (set_box_dimen):
  case ANY_MODE (set_shape):
  case ANY_MODE (def_code):
  case ANY_MODE (def_family):
  case ANY_MODE (set_font):
  case ANY_MODE (def_font):
  case ANY_MODE (register_cmd):
  case ANY_MODE (ADVANCE_CODE):
  case ANY_MODE (multiply):
  case ANY_MODE (divide):
  case ANY_MODE (PREFIX_CODE):
  case ANY_MODE (let):
  case ANY_MODE (shorthand_def):
  case ANY_MODE (read_to_cs):
  case ANY_MODE (def):
  case ANY_MODE (set_box):
  case ANY_MODE (hyph_data):
  case ANY_MODE (set_interaction):
	prefixed_command();
	break;
	/* module 1413 */
  case ANY_MODE (after_assignment):
	get_token();
	after_token = cur_tok;
	break;
	/* module 1416 */
  case  ANY_MODE (after_group):
	get_token();
	save_for_after (cur_tok);
	break;
	/* module 1419 */
  case ANY_MODE (in_stream):
	open_or_close_in();
	break;
	/* module 1421 */
	/* The user can issue messages to the terminal, regardless of the
	 * current MODE_FIELD.
	 */
  case ANY_MODE (MESSAGE_CODE):
	issue_message();
	break;
	/* module 1430 */
	/* The \.{\\uppercase} and \.{\\lowercase} commands are implemented by
	 * building a token list and then changing the cases of the letters in it.
	 */
  case ANY_MODE (case_shift):
	shift_case();
	break;
	/* module 1435 */
	/* We come finally to the last pieces missing from |main_control|, namely the
	 * `\.{\\show}' commands that are useful when debugging.
	 */
  case ANY_MODE (xray):
	show_whatever();
	break;
	/* end expansion of Cases of |main_control| that don't depend on |MODE_FIELD| */
	/* begin expansion of Cases of |main_control| that are for extensions to \TeX */
	/* module 1492 */
	/* When an |extension| command occurs in |main_control|, in any MODE_FIELD,
	 * the |do_extension| routine is called.
	 */
  case ANY_MODE (extension):
	do_extension();
	/* end expansion of Cases of |main_control| that are for extensions to \TeX */
	/* end expansion of Cases of |main_control| that are not part of the inner loop */
  }
}


void handle_main_loop(void) {
  /* begin expansion of Append character |cur_chr| and the following characters (if~any)
     to the current hlist in the current font; |goto reswitch| when a non-character has been fetched */
  /* module 1179 */
  /* We leave the |space_factor| unchanged if |sf_code(cur_chr)=0|; otherwise we
   * set it equal to |sf_code(cur_chr)|, except that it should never change
   * from a value less than 1000 to a value exceeding 1000. The most common
   * case is |sf_code(cur_chr)=1000|, so we want that case to be fast.
   * 
   * The overall structure of the main loop is presented here. Some program labels
   * are inside the individual sections.
   */  
  adjust_space_factor;
  main_f = cur_font;
  bchar = font_bchar[main_f];
  false_bchar = font_false_bchar[main_f];
  if (MODE_FIELD > 0)
    if (language != clang)
      fix_language();
  fast_get_avail (lig_stack);
  font (lig_stack) = main_f;
  cur_l = qi (cur_chr);
  character (lig_stack) = cur_l;
  cur_q = tail;
  if (cancel_boundary) {
    cancel_boundary = false;
    main_k = non_address;
  } else {
    main_k = bchar_label[main_f];
  }
  if (main_k == non_address)
    goto MAIN_LOOP_MOVE2;  /* no left boundary processing */ 
  cur_r = cur_l;
  cur_l = non_char;
  main_j = font_info[main_k].qqqq;
  goto MAIN_LIG_LOOP2;
  /* Make a ligature node, if |ligature_present|; INSERT_CODE a  null discretionary, if appropriate */
  wrapup (rt_hit);
 MAIN_LOOP_MOVE:
  /* begin expansion of If the cursor is immediately followed by the right boundary, |goto reswitch|;
     if it's followed by an invalid character, |goto BIG_SWITCH|; otherwise move the cursor one step to 
     the right and |goto MAIN_LIG_LOOP| */
  /* module 1181 */
  if (lig_stack == null)
    return;
  cur_q = tail;
  cur_l = character (lig_stack);
 MAIN_LOOP_MOVE1:
  if (!is_char_node(lig_stack))
    goto MAIN_LOOP_MOVE_LIG;
 MAIN_LOOP_MOVE2:
  if ( (effective_char (false, main_f, cur_chr) > font_ec[main_f])
       || 
       (effective_char (false, main_f, cur_chr) < font_bc[main_f])) {
    char_warning (main_f, cur_chr);
    free_avail (lig_stack);
    get_x_token();
    return;
  };
  main_i = effective_char_info (main_f, cur_l);
  if (!char_exists (main_i)) {
    char_warning (main_f, cur_chr);
    free_avail (lig_stack);
    get_x_token();
    return;
  };
  tail_append (lig_stack);  /* |MAIN_LOOP_LOOKAHEAD| is next */
  /* end expansion of If the cursor is immediately followed by the right boundary, ...*/
 MAIN_LOOP_LOOKAHEAD:
  /* begin expansion of Look ahead for another character, or leave |lig_stack| empty if there's none there */
  /* module 1183 */
  /* The result of \.{\\char} can participate in a ligature or kern, so we must
   * look ahead for it.
   */
  get_next(); /* set only |cur_cmd| and |cur_chr|, for speed */
  if (cur_cmd == letter)
    goto MAIN_LOOP_LOOKAHEAD1;
  if (cur_cmd == other_char)
    goto MAIN_LOOP_LOOKAHEAD1;
  if (cur_cmd == char_given)
    goto MAIN_LOOP_LOOKAHEAD1;
  x_token(); /* now expand and set |cur_cmd|, |cur_chr|, |cur_tok| */
  if (cur_cmd == letter)
    goto MAIN_LOOP_LOOKAHEAD1;
  if (cur_cmd == other_char)
    goto MAIN_LOOP_LOOKAHEAD1;
  if (cur_cmd == char_given)
    goto MAIN_LOOP_LOOKAHEAD1;
  if (cur_cmd == char_num) {
    scan_char_num();
    cur_chr = cur_val;
    goto MAIN_LOOP_LOOKAHEAD1;
  };
  if (cur_cmd == no_boundary)
    bchar = non_char;
  cur_r = bchar;
  lig_stack = null;
  goto MAIN_LIG_LOOP;
 MAIN_LOOP_LOOKAHEAD1:
  adjust_space_factor;
  fast_get_avail (lig_stack);
  font (lig_stack) = main_f;
  cur_r = qi (cur_chr);
  character (lig_stack) = cur_r;
  if (cur_r == false_bchar)
    cur_r = non_char;   /* this prevents spurious ligatures */
  /* end expansion of Look ahead for another character, or leave |lig_stack| EMPTY_CODE if there's none there */
 MAIN_LIG_LOOP:
  /* begin expansion of If there's a ligature/kern command relevant to |cur_l| and |cur_r|,
     adjust the text appropriately; exit to |MAIN_LOOP_WRAPUP| */
  /* module 1184 */
  /* Even though comparatively few characters have a lig/kern program, several
   * of the instructions here count as part of \TeX's inner loop, since a
   * 
   * potentially long sequential search must be performed. For example, tests with
   * Computer Modern Roman showed that about 40 per cent of all characters
   * actually encountered in practice had a lig/kern program, and that about four
   * lig/kern commands were investigated for every such character.
   * 
   * At the beginning of this code we have |main_i=char_info(main_f,cur_l)|.
   */
  if (char_tag (main_i) != lig_tag) {
    wrapup (rt_hit);
    goto MAIN_LOOP_MOVE;
  }
  main_k = lig_kern_start (main_f,main_i);
  main_j = font_info[main_k].qqqq;
  if (skip_byte (main_j) <= stop_flag)
    goto MAIN_LIG_LOOP2;
  main_k = lig_kern_restart (main_f,main_j);
  while (true) {
  main_j = font_info[main_k].qqqq;
 MAIN_LIG_LOOP2:
  if (next_char (main_j) == cur_r)
    if (skip_byte (main_j) <= stop_flag) {
      /* begin expansion of Do ligature or kern command, returning to |MAIN_LIG_LOOP| or 
         |MAIN_LOOP_WRAPUP| or |MAIN_LOOP_MOVE| */
      /* module 1185 */
      /* When a ligature or kern instruction matches a character, we know from
       * |read_font_info| that the character exists in the font, even though we
       * haven't verified its existence in the normal way.
       * 
       * This section could be made into a subroutine, if the code inside
       * |main_control| needs to be shortened.
       * 
       * \chardef\?='174 % vertical line to indicate character retention
       */
      if (op_byte (main_j) >= kern_flag) {
        wrapup (rt_hit);
        tail_append (new_kern (char_kern (main_f, main_j)));
        goto MAIN_LOOP_MOVE;
      };
      if (cur_l == non_char) {
        lft_hit = true;
      } else if (lig_stack == null) {
        rt_hit = true;
      };
      check_interrupt;  /* allow a way out in case there's an infinite ligature loop */
      switch (op_byte (main_j)) {
      case qi (1):
      case qi (5):
        cur_l = rem_byte (main_j); /* \.{=:\?}, \.{=:\?>} */ 
        main_i = char_info (main_f,cur_l);
        ligature_present = true;
        break;
      case qi (2):
      case qi (6):
        cur_r = rem_byte (main_j); /* \.{\?=:}, \.{\?=:>} */ 
        if (lig_stack == null) { /* right boundary character is being consumed */
          lig_stack = new_lig_item (cur_r);
          bchar = non_char;
        } else if (is_char_node (lig_stack)) {  /* |link(lig_stack)=null| */
          main_p = lig_stack;
          lig_stack = new_lig_item (cur_r);
          lig_ptr (lig_stack) = main_p;
        } else {
          character (lig_stack) = cur_r;
        }
        break;
      case qi (3):
        cur_r = rem_byte (main_j); /* \.{\?=:\?} */ 
        main_p = lig_stack;
        lig_stack = new_lig_item (cur_r);
        link (lig_stack) = main_p;
        break;
      case qi (7):
      case qi (11):
        wrapup (false); /* \.{\?=:\?>}, \.{\?=:\?>>} */ 
        cur_q = tail;
        cur_l = rem_byte (main_j);
        main_i = char_info (main_f,cur_l);
        ligature_present = true;
        break;
      default:
        cur_l = rem_byte (main_j);
        ligature_present = true; /* \.{=:} */ 
        if (lig_stack == null) {
          wrapup (rt_hit);
          goto MAIN_LOOP_MOVE;
        } else {
          goto MAIN_LOOP_MOVE1;
        };
      };
      if (op_byte (main_j) > qi (4))
        if (op_byte (main_j) != qi (7)) {
          wrapup (rt_hit);
          goto MAIN_LOOP_MOVE;
        }
      if (cur_l < non_char)
        goto MAIN_LIG_LOOP;
      main_k = bchar_label[main_f];
      continue;
    };
  /* end expansion of Do ligature or kern command, returning to |main_lig_loop| or ... */
  if (skip_byte (main_j) == qi (0)) {
    incr (main_k);
  } else {
    if (skip_byte (main_j) >= stop_flag) {
      wrapup (rt_hit);
      goto MAIN_LOOP_MOVE;
    }
    main_k = main_k + qo (skip_byte (main_j)) + 1;
  };
  }
  /* end expansion of If there's a ligature/kern command relevant to |cur_l| and |cur_r|, ... */
 MAIN_LOOP_MOVE_LIG:
  /* begin expansion of Move the cursor past a pseudo-ligature, then 
     |goto MAIN_LOOP_LOOKAHEAD| or |MAIN_LIG_LOOP| */
  /* module 1182 */
  /* Here we are at |MAIN_LOOP_move_lig|.
   * When we begin this code we have |cur_q=tail| and |cur_l=character(lig_stack)|.
   */
  main_p = lig_ptr (lig_stack);
  if (main_p > null)
    tail_append (main_p);
  temp_ptr = lig_stack;
  lig_stack = link (temp_ptr);
  free_node (temp_ptr, small_node_size);
  main_i = char_info (main_f,cur_l);
  ligature_present = true;
  if (lig_stack == null) {
    if (main_p > null) {
      goto MAIN_LOOP_LOOKAHEAD;
    } else {
      cur_r = bchar;
    } 
  } else {
    cur_r = character (lig_stack);
  }
  goto MAIN_LIG_LOOP;
  /* end expansion of Move the cursor past a pseudo-ligature, then ...*/
  /* end expansion of Append character |cur_chr| and the following characters .... */
}



/* module 1426 */

/* If \.{\\errmessage} occurs often in |scroll_mode|, without user-defined
 * \.{\\errhelp}, we don't want to give a long help message each time. So we
 * give a verbose explanation only once.
 */

boolean long_help_seen; /* has the long \.{\\errmessage} help been used? */


/* module 1178 */

/* The boolean variables of the main loop are normally false, and always reset
 * to false before the loop is left. That saves us the extra work of initializing
 * each time.
 */
void
control_initialize (void ) {
  ligature_present = false;
  cancel_boundary = false;
  lft_hit = false;
  rt_hit = false;
  ins_disc = false;
  /* module 1427 */
  long_help_seen = false;
}


/* module  1196 */

/* Some operations are allowed only in privileged modes, i.e., in cases
 * that |MODE_FIELD>0|. The |privileged| function is used to detect violations
 * of this rule; it issues an error message and returns |false| if the
 * current |MODE_FIELD| is negative.
 */
static boolean 
privileged (void) {
  if (MODE_FIELD > 0) {
	return true;
  } else {
	report_illegal_case();
	return false;
  };
};


/* module  1199 */

/* We don't want to leave |main_control| immediately when a |stop| command
 * is sensed, because it may be necessary to invoke an \.{\\output} routine
 * several times before things really grind to a halt. (The output routine
 * might even say `\.{\\gdef\\end\{...\}}', to prolong the life of the job.)
 * Therefore |its_all_over| is |true| only when the current page
 * and contribution list are EMPTY_CODE, and when the last output was not a
 * ``dead cycle.''
 */
boolean
its_all_over (void) { /* do this when \.{\\end} or \.{\\dump} occurs */
  if (privileged()) {
	if ((page_head == page_tail) && (head == tail) && (dead_cycles == 0)) {
	  return true;
	};
	back_input();
	/* we will try to end again after ejecting residual material */
	tail_append (new_null_box());
	width (tail) = hsize;
	tail_append (new_glue (fill_glue));
	tail_append (new_penalty (-1073741824));
	build_page(); /* append \.{\\hbox to \\hsize\{\}\\vfill\\penalty-'10000000000} */
  };
  return false;
};



/* module 1213 */
void
handle_right_brace (void) {
  pointer p, q; /* for short-term use */ 
  scaled d; /* holds |split_max_depth| in |insert_group| */ 
  int f; /* holds |floating_penalty| in |insert_group| */
  switch (cur_group) {
  case simple_group:
	unsave();
	break;
  case bottom_level:
	print_err ("Too many }'s");
	help2 ("You've closed more groups than you opened.",
		   "Such booboos are generally harmless, so keep going.");
	error();
	break;
  case semi_simple_group:
  case math_shift_group:
  case math_left_group:
	extra_right_brace();
	break;
	/* begin expansion of Cases of |handle_right_brace| where a |right_brace| triggers a delayed action */
	/* module 1230 */
	/* When the right brace occurs at the end of an \.{\\hbox} or \.{\\vbox} or
	 * \.{\\vtop} construction, the |package| routine comes into action. We might
	 * also have to finish a paragraph that hasn't ended.
	 */
  case hbox_group:
	package (0);
	break;
  case adjusted_hbox_group:
	adjust_tail = adjust_head;
	pre_adjust_tail = pre_adjust_head;
	package (0);
	break;
  case vbox_group:
	end_graf();
	package (0);
	break;
  case vtop_group:
	end_graf();
	package (vtop_code);
	break;
	/* module 1245 */
  case insert_group:
	end_graf();
	q = split_top_skip;
	add_glue_ref (q);
	d = split_max_depth;
	f = floating_penalty;
	unsave();
	save_ptr = save_ptr - 2;
	/* now |saved(0)| is the insertion number, or 255 for |vadjust| */
	p = VPACK (link (head), 0, additional);
	pop_nest();
	if (saved (0) < 255) {
	  tail_append (get_node (ins_node_size));
	  TYPE_FIELD (tail) = ins_node;
	  subtype (tail) = qi (saved (0));
	  height (tail) = height (p) + depth (p);
	  ins_ptr (tail) = list_ptr (p);
	  split_top_ptr (tail) = q;
	  depth (tail) = d;
	  float_cost (tail) = f;
	} else {
	  tail_append(new_adjust_node(p,saved(1)));
	  delete_glue_ref (q);
	};
	free_node (p, box_node_size);
	if (nest_ptr == 0)
	  build_page();
	break;
  case output_group:
	/* begin expansion of Resume the page builder... */
	/* module 1171 */
	/* When the user's output routine finishes, it has constructed a vlist
	 * in internal vertical MODE_FIELD, and \TeX\ will do the following:
	 */
	if ((loc != null)|| ((token_type != output_text)&& (token_type != backed_up))) {
	  /* begin expansion of Recover from an unbalanced output routine */
	  /* module 1172 */
	  print_err ("Unbalanced output routine");
	  help2 ("Your sneaky output routine has problematic {'s and/or }'s.",
			 "I can't handle that very well; good luck.");
	  error();
	  do {
		get_token();
	  } while (loc != null);
	};	/* loops forever if reading from a file, since |null=min_halfword<=0| */
	/* end expansion of Recover from an unbalanced output routine */
	end_token_list(); /* conserve stack space in case more outputs are triggered */
	end_graf();
	unsave();
	output_active = false;
	insert_penalties = 0;
	/* begin expansion of Ensure that box 255 is EMPTY_CODE after output */
	/* module 1173 */
	if (box (255) != null) {
	  print_err ("Output routine didn't use all of ");
	  print_esc_string ("box");
	  print_int (255);
	  help3 ("Your \\output commands should EMPTY_CODE \\box255,",
			 "e.g., by saying `\\shipout\\box255'.",
			 "Proceed; I'll discard its present contents.");
	  box_error (255);
	};
	/* end expansion of Ensure that box 255 is EMPTY_CODE after output */
	if (tail != head)	{ /* current list goes after heldover insertions */
	  link (page_tail) = link (head);
	  page_tail = tail;
	};
	if (link (page_head) != null)	{ /* and both go before heldover contributions */
	  if (link (contrib_head) == null)
		contrib_tail = page_tail;
	  link (page_tail) = link (contrib_head);
	  link (contrib_head) = link (page_head);
	  link (page_head) = null;
	  page_tail = page_head;
	};
	flush_node_list (page_disc);
	page_disc = null;
	pop_nest();
	build_page();
	/* end expansion of Resume the page builder... */
	break;
	/* module 1263 */
	/* The three discretionary lists are constructed somewhat as if they were
	 * hboxes. A~subroutine called |build_discretionary| handles the transitions.
	 * (This is sort of fun.)
	 */
  case disc_group:
	build_discretionary();
	break;
	/* module 1277 */
  case align_group:
	back_input();
	cur_tok = cs_token_flag + frozen_cr;
	print_err ("Missing ");
	print_esc_string ("cr");
	zprint_string(" inserted");
	help1  ("I'm guessing that you meant to end an alignment here.");
	ins_error();
	break;
	/* module 1278 */
  case  no_align_group:
	end_graf();
	unsave();
	align_peek();
	break;
	/* module 1313 */
  case vcenter_group:
	end_graf();
	unsave();
	save_ptr = save_ptr - 2;
	p = VPACK (link (head), saved (1), saved (0));
	pop_nest();
	tail_append (new_noad());
	TYPE_FIELD (tail) = vcenter_noad;
	math_type (nucleus (tail)) = sub_box;
	info (nucleus (tail)) = p;
	break;
	/* module 1318 */
  case math_choice_group:
	build_choices();
	break;
	/* module 1331 */
	/* Now at last we're ready to see what happens when a right brace occurs
	 * in a math formula. Two special cases are simplified here: Braces are effectively
	 * removed when they surround a single Ord without sub/superscripts, or when they
	 * surround an accent that is the nucleus of an Ord atom.
	 */
  case math_group:
	unsave();
	decr (save_ptr);
	math_type (saved (0)) = sub_mlist;
	p = fin_mlist (null);
	info (saved (0)) = p;
	if (p != null) {
	  if (link (p) == null) {
		if (TYPE_FIELD (p) == ord_noad) {
		  if (math_type (subscr (p)) == EMPTY_CODE)
			if (math_type (supscr (p)) == EMPTY_CODE) {
			  mem[saved (0)].hh = mem[nucleus (p)].hh;
			  free_node (p, noad_size);
			};
		} else if (TYPE_FIELD (p) == accent_noad) {
		  if (saved (0) == nucleus (tail)) {
			if (TYPE_FIELD (tail) == ord_noad) {
			  /* begin expansion of Replace the tail of the list by |p| */
			  /* module 1332 */
			  q = head;
			  while (link (q) != tail)
				q = link (q);
			  link (q) = p;
			  free_node (tail, noad_size);
			  tail = p;
			  /* end expansion of Replace the tail of the list by |p| */
			}			  
		  }
		}
	  }
	};
	break;
  default:
	confusion ("rightbrace");
  };
}


/* module 1250 */
/* When |delete_last| is called, |cur_chr| is the |TYPE_FIELD| of node that
 * will be deleted, if present.
 * A final \.{\\endM} node is temporarily removed.
 */
void delete_last (void) {
  pointer p, q; /* run through the current list */ 
  quarterword m; /* the length of a replacement list */ 
  if ((MODE_FIELD == vmode) && (tail == head)) {
	/* begin expansion of Apologize for inability to do the operation now, 
	   unless \.{\\unskip} follows non-glue */
	/* module 1251 */
	if ((cur_chr != glue_node) || (last_glue != max_halfword)) {
	  you_cant();
	  help2 ("Sorry...I usually can't take things from the current page.",
			 "Try `I\\vskip-\\lastskip' instead.");
	  if (cur_chr == kern_node) {
		help_line[0] = "Try `I\\kern-\\lastkern' instead.";
	  } else if (cur_chr != glue_node)
		help_line[0] = "Perhaps you can make the output routine do it.";
	  error();
	};
	/* end expansion of Apologize for inability to do the operation now, ... */
  } else {
	if (!is_char_node (tail)) {
	  if ((TYPE_FIELD (tail) == math_node)&& (subtype (tail) == end_M_code))
		remove_end_M();
	  if (TYPE_FIELD (tail) == cur_chr) {
		q = head;
		do {
		  p = q;
		  if (!is_char_node (q))
			if (TYPE_FIELD (q) == disc_node) {
			  for (m = 1; m <= replace_count (q); m++)
				p = link (p);
			  if (p == tail)
				return;
			};
		  q = link (p);
		} while (q != tail);
		link (p) = null;
		flush_node_list (tail);
		tail = p;
	  };
	  if (LR_temp != null)
		insert_end_M();
	};
  };
}


/* module 1415 */

/* Here is a procedure that might be called `Get the next non-blank non-relax
 * non-call non-assignment token'.
 */
void 
do_assignments (void) {
  loop {
	/* Get the next non-blank non-relax non-call token */
	get_nblank_nrelax_ncall;
	if (cur_cmd <= max_non_prefixed_command)
	  return;
	set_box_allowed = false;
	prefixed_command();
	set_box_allowed = true;
  };
};

/* module 1424 */
static void 
issue_message (void) {
  unsigned char old_setting; /* holds |selector| setting */ 
  unsigned char c; /* identifies \.{\\message} and \.{\\errmessage} */
  str_number s; /* the message */ 
  c = cur_chr;
  link (garbage) = scan_toks (false, true);
  old_setting = selector;
  selector = new_string;
  token_show (def_ref);
  selector = old_setting;
  flush_list (def_ref);
  str_room (1);
  s = make_string();
  if (c == 0) {
	/* begin expansion of Print string |s| on the terminal */
	/* module 1425 */
	if (term_offset + length (s) > (unsigned)max_print_line - 2) {
	  print_ln();
	} else if ((term_offset > 0) || (file_offset > 0)) {
	  print_char (' ');
	}
	slow_print (s);
	update_terminal;
	/* end expansion of Print string |s| on the terminal */
  } else {
	/* begin expansion of Print string |s| as an error message */
	/* module 1428 */
	print_err ("");
	slow_print (s);
	if (err_help != null) {
	  use_err_help = true;
	} else if (long_help_seen) {
	  help1 ("(That was another \\errmessage.)");
	} else {
	  if (interaction < error_stop_mode)
		long_help_seen = true;
	  help4 ("This error message was generated by an \\errmessage",
			 "command, so I can't give any explicit help.",
			 "Pretend that you're Hercule Poirot: Examine all clues,",
			 "and deduce the truth by order and method.");
	};
	error();
	use_err_help = false;
  };
  /* end expansion of Print string |s| as an error message */
  flush_string;
};

/* module 1433 */
static void 
shift_case (void) {
  pointer b; /* |lc_code_base| or |uc_code_base| */ 
  pointer p; /* runs through the token list */ 
  halfword t; /* token */ 
  eight_bits c; /* character code */ 
  b = cur_chr;
  p = scan_toks (false, false);
  p = link (def_ref);
  while (p != null) {
	/* begin expansion of Change the case of the token in |p|, if a change is appropriate */
	/* module 1434 */
	/* When the case of a |chr_code| changes, we don't change the |cmd|.
	 * We also change active characters, using the fact that
	 * |cs_token_flag+active_base| is a multiple of~256.
	 */
	t = info (p);
	if (t < cs_token_flag + single_base) {
	  c = t % 256;
	  if (equiv (b + c) != 0)
		info (p) = t - c + equiv (b + c);
	};
	/* end expansion of Change the case of the token in |p|, if a change is appropriate */
	p = link (p);
  };
  back_list (link (def_ref));
  free_avail (def_ref); /* omit reference count */ 
};


int
main_body (void) {   /* |start_here| */
  /* Bounds that may be set from the configuration file. We want the user to be able to specify 
     the names with underscores, but \.{TANGLE} removes underscores, so we're stuck giving the
     names twice, once as a string, once as the identifier. How ugly. */
  /* then, someone writes a version of  \.{TANGLE} that retains underscores. Goody, the code
   just got even uglier, because now the \.{WEB2C} library is the limiting factor. Cool. */
  setup_bound_var (250000,"main_memory",main_memory); /* |memory_word|s for |mem| in \.{INITEX} */
  setup_bound_var (0,"extra_mem_top",extra_mem_top); /* increase high mem in \.{VIRTEX} */
  setup_bound_var (0,"extra_mem_bot",extra_mem_bot); /* increase low mem in \.{VIRTEX} */
  setup_bound_var (50000,"pool_size",pool_size);
  setup_bound_var (750,"string_vacancies",string_vacancies);
  setup_bound_var (500,"pool_free",pool_free); /* min pool avail after fmt */
  setup_bound_var (300,"max_strings",max_strings);
  setup_bound_var (100,"strings_free",strings_free);
  setup_bound_var (100000,"font_mem_size",font_mem_size);
  setup_bound_var (500,"font_max",font_max);
  setup_bound_var (20000,"trie_size",trie_size);   /* if |ssup_trie_size| increases, recompile */
  setup_bound_var (659,"hyph_size",hyph_size);
  setup_bound_var (3000,"buf_size",buf_size);
  setup_bound_var (50,"nest_size",nest_size);
  setup_bound_var (15,"max_in_open",max_in_open);
  setup_bound_var (60,"param_size",param_size);
  setup_bound_var (4000,"save_size",save_size);
  setup_bound_var (300,"stack_size",stack_size);
  setup_bound_var (16384,"dvi_buf_size",dvi_buf_size);
  setup_bound_var (79,"error_line",error_line);
  setup_bound_var (50,"half_error_line",half_error_line);
  setup_bound_var (79,"max_print_line",max_print_line);
  setup_bound_var (65536,"obj_tab_size",obj_tab_size);
  setup_bound_var (65536,"pdf_mem_size",pdf_mem_size);
  setup_bound_var (20000,"dest_names_size",dest_names_size);
  const_chk (main_memory,inf_main_memory,sup_main_memory);
  if (ini_version) {
    extra_mem_top = 0;
    extra_mem_bot = 0;
  }
  if (extra_mem_bot > sup_main_memory)
    extra_mem_bot = sup_main_memory;
  if (extra_mem_top > sup_main_memory)
    extra_mem_top = sup_main_memory;
  mem_top = mem_bot + main_memory;
  mem_min = mem_bot;
  mem_max = mem_top;
  /* Check other constants against their sup and inf. */
  const_chk (trie_size,inf_trie_size,sup_trie_size);
  const_chk (hyph_size,inf_hyph_size,sup_hyph_size);
  const_chk (buf_size,inf_buf_size,sup_buf_size);
  const_chk (nest_size,inf_nest_size,sup_nest_size);
  const_chk (max_in_open,inf_max_in_open,sup_max_in_open);
  const_chk (param_size,inf_param_size,sup_param_size);
  const_chk (save_size,inf_save_size,sup_save_size);
  const_chk (stack_size,inf_stack_size,sup_stack_size);
  const_chk (dvi_buf_size,inf_dvi_buf_size,sup_dvi_buf_size);
  const_chk (pool_size,inf_pool_size,sup_pool_size);
  const_chk (string_vacancies,inf_string_vacancies,sup_string_vacancies);
  const_chk (pool_free,inf_pool_free,sup_pool_free);
  const_chk (max_strings,inf_max_strings,sup_max_strings);
  const_chk (strings_free,inf_strings_free,sup_strings_free);
  const_chk (font_mem_size,inf_font_mem_size,sup_font_mem_size);
  const_chk (font_max,inf_font_max,sup_font_max);
  const_chk (obj_tab_size,inf_obj_tab_size,sup_obj_tab_size);
  const_chk (pdf_mem_size,inf_pdf_mem_size,sup_pdf_mem_size);
  const_chk (dest_names_size,inf_dest_names_size,sup_dest_names_size);
  if (error_line > ssup_error_line)
    error_line = ssup_error_line;
  /* array memory allocation */ 
  buffer = xmalloc_array (ASCII_code, buf_size);
  nest = xmalloc_array (list_state_record, nest_size);
  save_stack = xmalloc_array (memory_word, save_size);
  input_stack = xmalloc_array (in_state_record,stack_size);
  input_file = xmalloc_array (FILE *, max_in_open);
  line_stack = xmalloc_array (integer, max_in_open);
  eof_seen = xmalloc_array (boolean, max_in_open);
  grp_stack = xmalloc_array (save_pointer, max_in_open);
  if_stack = xmalloc_array (pointer, max_in_open);
  source_filename_stack = xmalloc_array (str_number, max_in_open);
  full_source_filename_stack = xmalloc_array (str_number, max_in_open);
  param_stack = xmalloc_array (halfword, param_size);
  dvi_buf = xmalloc_array (eight_bits, dvi_buf_size);
  hyph_word = xmalloc_array (str_number, hyph_size);
  hyph_list = xmalloc_array (halfword, hyph_size);
  hyph_link = xmalloc_array (hyph_pointer, hyph_size);
  obj_tab = xmalloc_array (obj_entry, obj_tab_size);
  pdf_mem = xmalloc_array (integer, pdf_mem_size);
  dest_names = xmalloc_array (dest_name_entry, dest_names_size);
  if (ini_version) {
    yzmem = xmalloc_array (memory_word, mem_top - mem_bot);
    mem = yzmem - mem_bot; /* Some compilers require |mem_bot=0| */
    eqtb = xmalloc_array (memory_word, eqtb_size);
    font_info = xmalloc_array (fmemory_word, font_mem_size);
  }
  hash_initialize();
  /* strings init is needed always ... */
  str_start = xmalloc_array (pool_pointer, max_strings);
  str_pool = xmalloc_array (packed_ASCII_code, pool_size);
  history = fatal_error_stop; /* in case we quit during initialization */
  t_open_out;   /* open the terminal for output */ 
  if (ready_already == 314159)
    goto START_OF_TEX;
  /* begin expansion of Check the ``constant'' values... */
  /* module 14 */
  /* Later on we will say `\ignorespaces|if mem_max>=max_halfword then bad:=14|',
   * or something similar. (We can't do that until |max_halfword| has been defined.)
   */
  bad = 0;
  if ((half_error_line < 30) || (half_error_line > error_line - 15))
    bad = 1;
  if (max_print_line < 60)
    bad = 2;
  if (dvi_buf_size % 8 != 0)
    bad = 3;
  if (mem_bot + 1100 > mem_top)
    bad = 4;
  if (hash_prime > HASH_SIZE)
    bad = 5;
  if (max_in_open >= 128)
    bad = 6;
  if (mem_top < 256 + 11)
    bad = 7; /* we will want |null_list>255| */
  /* module 111 */  
  /* Here are the inequalities that the quarterword and halfword values
   * must satisfy (or rather, the inequalities that they mustn't satisfy):
   */
  if ((mem_min != mem_bot) || (mem_max != mem_top))
    bad = 10;
  if ((mem_min > mem_bot) || (mem_max < mem_top))
    bad = 10;
  if ((min_quarterword > 0) || (max_quarterword < 127))
    bad = 11;
  if ((min_halfword > 0) || (max_halfword < 32767))
    bad = 12;
  if ((min_quarterword < min_halfword) || (max_quarterword > max_halfword))
    bad = 13;
  if ((mem_min < min_halfword)|| (mem_max >= max_halfword)|| (mem_bot - mem_min > max_halfword + 1))
    bad = 14;
  if ((max_font_max < min_halfword)|| (max_font_max > max_halfword))
    bad = 15;
  if (font_max > font_base + max_font_max)
    bad = 16;
  if ((save_size > max_halfword)|| (max_strings > max_halfword))
    bad = 17;
  if (buf_size > max_halfword)
    bad = 18;
  if (max_quarterword - min_quarterword < 255)
    bad = 19;
  /* module 290 */
  if (cs_token_flag + eqtb_size > max_halfword)
    bad = 21;
  /* module 522 */
  if (format_default_length > file_name_size)
    bad = 31;
  /* module 1394 */
  /* Here's something that isn't quite so obvious. It guarantees that
   * |info(par_shape_ptr)| can hold any positive~|n| for which |get_node(2*n+1)|
   * doesn't overflow the memory capacity.
   */
  if (2 * max_halfword < mem_top - mem_min)
    bad = 41;
  /* end expansion of Check the ``constant'' values... */
  if (bad > 0) {
    fprintf(term_out,"%s%s%ld\n", "Ouch---my internal constants have been clobbered!", "---case ", (integer) bad);
    goto FINAL_END;
  };
  /* get_strings_started is needed always and before initialize  */
  if (!(get_strings_started()))
    goto FINAL_END;
  initialize(); /* set global variables to their starting values */
  if (ini_version) {
    init_prim(0); /* call |primitive| for each primitive */
    init_str_ptr = str_ptr;
    init_pool_ptr = pool_ptr;
    fix_date_and_time;
  } else {
  init_prim(1);
  }
  ready_already = 314159;
 START_OF_TEX:
  /* begin expansion of Initialize the output routines */
  print_initialize ();
  /* module 61 */ 
  /* Here is the very first thing that \TeX\ prints: a headline that identifies
   * the version number and format package. The |term_offset| variable is temporarily
   * incorrect, but the discrepancy is not serious since we assume that the banner
   * and format identifier together will occupy at most |max_print_line|
   * character positions.
   */
  fprintf ( term_out , "%s%c%s%c%s",banner);
  wterm_string (version_string);
  if (format_ident > 0)
    slow_print (format_ident);
  print_ln();
  update_terminal;
  /* module 528 */
  /* Initially |jobname=0|; it becomes nonzero as soon as the true name is known.
   * We have |jobname=0| if and only if the `\.{log}' file has not been opened,
   * except of course for a short time just after |jobname| has become nonzero.
   */
  jobname = 0;
  name_in_progress = false;
  log_opened = false;
  /* module 533 */
  output_file_name = 0;
  /* end expansion of Initialize the output routines */
  /* begin expansion of Get the first line of input and prepare to start */
  /* module 1482 */
  /* When we begin the following code, \TeX's tables may still contain garbage;
   * the strings might not even be present. Thus we must proceed cautiously to get
   * bootstrapped in.
   * 
   * But when we finish this part of the program, \TeX\ is ready to call on the
   * |main_control| routine to do its work.
   */
  {
    /* begin expansion of Initialize the input routines */
    cmdchr_initialize();
    /* next 4 lines where part of the above proc initially */
    if (!init_terminal())
      goto FINAL_END;
    limit = last;
    first = last + 1;    /* |init_terminal| has set |loc| and |last| */
    /* end expansion of Initialize the input routines */
    /* begin expansion of Enable \eTeX, if requested */
    /* module 1591 */
  /* 
     * The program has two modes of operation: (1)~In \TeX\ compatibility mode
     * it fully deserves the name \TeX\ and there are neither extended features
     * nor additional primitive commands. There are, however, a few
     * modifications that would be legitimate in any implementation of \TeX\
     * such as, e.g., preventing inadequate results of the glue to \.{DVI}
     * unit conversion during |ship_out|. (2)~In extended mode there are
     * additional primitive commands and the extended features of \eTeX\ are
     * available.
     * 
     * The distinction between these two modes of operation initially takes
     * place when a `virgin' \.{eINITEX} starts without reading a format file.
     * Later on the values of all \eTeX\ state variables are inherited when
     * \.{eVIRTEX} (or \.{eINITEX}) reads a format file.
     * 
     * The code below is designed to work for cases where `$|init|\ldots|tini|$'
     * is a run-time switch.
     */    
    if ((buffer[loc] == '*') && (format_ident == slow_make_tex_string(" (INITEX)"))) {
      set_no_new_control_sequence (false);
      /* begin expansion of Generate all \eTeX\ primitives */
      init_etex_prim();
      /* end expansion of Generate all \eTeX\ primitives */
      incr (loc);
      eTeX_mode = 1; /* enter extended mode */
      /* begin expansion of Initialize variables for \eTeX\ extended mode */  
      /* module 1758 */
      max_reg_num = 32767;
      max_reg_help_line = "A register number must be between 0 and 32767.";
      /* end expansion of Initialize variables for \eTeX\ extended mode */
  }
    if (!is_no_new_control_sequence()){ /* just entered extended mode ? */
      set_no_new_control_sequence (true);
    } else {
      /* end expansion of Enable \eTeX, if requested */
      if ((format_ident == 0) || (buffer[loc] == '&') || dump_line) {
    if (format_ident != 0)
      initialize(); /* erase preloaded format */ 
    if (!(open_fmt_file()))
      goto FINAL_END;
    if (!(load_fmt_file())) {
      w_close (fmt_file);
      goto FINAL_END;
    };
    w_close (fmt_file);
    while ((loc < limit) && (buffer[loc] == ' '))
      incr (loc);
      };
    }
    if (eTeX_ex)
      wterm_string("entering extended mode\n");
    if (end_line_char_inactive) {
      decr (limit);
    } else {
      buffer[limit] = end_line_char;
    }
    if (mltex_enabled_p) {
      wterm_string ("MLTeX v2.2 enabled\n");
    };
    fix_date_and_time;
    if (trie_not_ready) { /* initex without format loaded */
      trie_xmalloc(trie_size);
      /* Allocate and initialize font arrays */
      font_xmalloc(font_max);
      pdffont_xmalloc(font_max);
    vf_xmalloc(font_max);
      pdffont_initialize_init(font_max);
    font_initialize_init();
    };
    font_used = xmalloc_array (boolean, font_max);
    for (font_k = font_base; font_k <= font_max; font_k++)
      font_used[font_k] = false;
    /* Compute the magic offset */ /* not used */
    /* begin expansion of Initialize the print |selector|... */
    initialize_selector;
    /* end expansion of Initialize the print |selector|... */
    if ((loc < limit) && (cat_code (buffer[loc]) != escape)) {
    start_input(); /* \.{\\input} assumed */
  } 
    /* begin expansion of Read values from config file if necessary */
    read_values_from_config_file();
    /* end expansion of Read values from config file if necessary */
  };
  /* end expansion of Get the first line of input and prepare to start */
  history = spotless; /* ready to go! */ 
  main_control(); /* come to life */ 
  final_cleanup(); /* prepare for death */ 
  close_files_and_terminate();
 FINAL_END:
  update_terminal ; 
  ready_already   = 0 ;
  if ( ( history   !=  spotless )  && ( history   !=  warning_issued )) {
  return 1 ; 
  } else { 
  return 0 ;
  }; 
};

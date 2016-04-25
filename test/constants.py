# Bounds
mem_bot = 0
ssup_error_line = 255
ssup_max_strings = 262143
ssup_trie_opcode = 65535
ssup_trie_size = 262143
ssup_hyph_size = 65535
iinf_hyphen_size = 610
max_font_max = 2000
font_base = 0
inf_trie_size = 8000
sup_trie_size = ssup_trie_size
inf_main_memory = 2999
sup_main_memory = 32000000
inf_max_strings = 3000
sup_max_strings = ssup_max_strings
inf_strings_free = 100
sup_strings_free = sup_max_strings
inf_buf_size = 500
sup_buf_size = 300000
inf_nest_size = 40
sup_nest_size = 4000
inf_max_in_open = 6
sup_max_in_open = 127
inf_param_size = 60
sup_param_size = 6000
inf_save_size = 600
sup_save_size = 40000
inf_stack_size = 200
sup_stack_size = 30000
inf_dvi_buf_size = 800
sup_dvi_buf_size = 65536
inf_font_mem_size = 20000
sup_font_mem_size = 1000000
sup_font_max = max_font_max
# Could be smaller, but why?
inf_font_max = 50
inf_pool_size = 32000
sup_pool_size = 40000000
inf_pool_free = 1000
sup_pool_free = sup_pool_size
inf_string_vacancies = 8000
sup_string_vacancies = sup_pool_size-23000
sup_hyph_size = ssup_hyph_size
# Must be not less than |hyph_prime|!
inf_hyph_size = iinf_hyphen_size
# min size of the cross-reference table for PDF output
inf_obj_tab_size = 32000
# max size of the cross-reference table for PDF output
sup_obj_tab_size = 8388607
# min size of the |pdf_mem| array
inf_pdf_mem_size = 32000
# max size of the |pdf_mem| array
sup_pdf_mem_size = 524288
inf_dest_names_size = 10000
sup_dest_names_size = 131072
ssup_error_line = 255

# Defaults
main_memory = 250000
extra_mem_top = 0
extra_mem_bot = 0
pool_size = 50000
string_vacancies = 750
pool_free = 500
max_strings = 300
strings_free = 100
font_mem_size = 100000
font_max = 500
trie_size = 20000
hyph_size = 659
buf_size = 3000
nest_size = 50
max_in_open = 15
param_size = 60
save_size = 4000
stack_size = 300
dvi_buf_size = 16384
obj_tab_size = 65536
pdf_mem_size = 65536
dest_names_size = 20000
error_line = 79
half_error_line = 50
max_print_line = 79

file_name_size = 256

font_base = 0
max_font_max = 2000

# From globals.h
min_quarterword = 0
max_quarterword = 255
min_halfword = -268435455
max_halfword = 268435455

# From hash.h
HASH_SIZE = 256 * 256 * 16

#ifndef TEX_CONTROL_H
#define TEX_CONTROL_H

/* module 1177 */
EXTERN font_index main_k; /* index into |font_info| */
EXTERN pointer main_p; /* temporary register for list manipulation */
EXTERN halfword bchar; /* right boundary character of current font, or |non_char| */
EXTERN halfword false_bchar; /* nonexistent character matching |bchar|, or |non_char| */

EXTERN void control_initialize (void);

EXTERN void do_assignments (void);

boolean its_all_over (void);
void handle_main_loop(void);
void handle_easy_cases(void);

extern boolean cancel_boundary;

#endif

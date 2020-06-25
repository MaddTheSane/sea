#ifndef __private_extern
#define __private_extern __attribute__((visibility("hidden")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

//! Counts number of cells != 0 in rempli.
__private_extern
int compter_remplis (guchar ** rempli, int width_i, int height_i);

//! Compute the graph, cuts it and updates the image.
//! @param rempli see render.c. Tells whether the the pixel is filled and if there is a cut here.
//! @param patch_posn Where to put the patch.
//! @param coupe_h_here Pixels lost along an old horizontal cut
//! @param coupe_h_west Pixels lost along an old horizontal cut
//! @param coupe_v_here Pixels lost along an old vertical cut
//! @param coupe_v_north Pixels lost along an old vertical cut
__private_extern
void decoupe_graphe(
    int* patch_posn, //*< Where to put the patch.
    int width_i, int height_i, int width_p, int height_p,
    int channels,
    guchar **rempli, //*<see render.c. Tells whether the the pixel is filled and if there is a cut here.
    guchar  *image, guchar * patch,
    guchar  *coupe_h_here, guchar * coupe_h_west,   //*< Pixels lost along an old horizontal cut
    guchar  *coupe_v_here, guchar * coupe_v_north,  //*< idem for vertical cuts
    gboolean make_tileable, gboolean invert);

//! Allocates the memory (with malloc) and fills with 0.
__private_extern
guchar ** init_guchar_tab_2d (gint x, gint y);


/** Compute the best position to put the patch,
 * between (x_patch_posn_min, y_patch_posn_min)
 * and     (x_patch_posn_max, y_patch_posn_max).
 * @param resultat The position where the patch will have to be put.
 */
__private_extern
void offset_optimal(
    gint *resultat, //*< The position where the patch will have to be put.
    guchar *image, guchar *patch,
    gint width_p, gint height_p, gint width_i, gint height_i,
    gint x_patch_posn_min, gint y_patch_posn_min, gint x_patch_posn_max, gint y_patch_posn_max,
    // Admissible positions for the patch, this function determines the best one.
    gint channels,
    guchar ** rempli,
    gboolean make_tileable);

//! Returns the minimal unfilled pixel under lexicographical order (y,x).
__private_extern int * pixel_a_remplir (guchar ** rempli, int width_i, int height_i, int* resultat);

__private_extern
gint modulo (gint x, gint m);

#ifdef __cplusplus
}
#endif

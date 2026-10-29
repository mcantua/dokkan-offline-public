#ifndef OD_DUO_VIEWPORT_H
#define OD_DUO_VIEWPORT_H
#include <stddef.h>

/* Point coordinates, independent of UIKit and the original engine ABI. */
typedef struct { double x, y, width, height; } ODDuoRect;
typedef struct { double top, left, bottom, right; } ODDuoInsets;
typedef struct {
    ODDuoRect bounds, usable, canvas;
    double logical_width, logical_height, scale;
} ODDuoViewport;

/* Optional fixed-canvas placement. Logical dimensions come from the actual
   renderer, never device constants. Division/fold regions must not be supplied
   as occlusions. The original engine may instead consume raw host geometry. */
int od_duo_viewport(ODDuoRect bounds, ODDuoInsets safe,
                    const ODDuoRect *occlusions, size_t count,
                    double logical_width, double logical_height,
                    ODDuoViewport *result);
/* Rejects letterbox touches. Coordinates use the same host space as bounds. */
int od_duo_canvas_point(const ODDuoViewport *viewport, double host_x, double host_y,
                         double *logical_x, double *logical_y);
#endif

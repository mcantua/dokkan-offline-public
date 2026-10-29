#include "ODDuoViewport.h"
#include <math.h>

static int valid(ODDuoRect r) {
    return isfinite(r.x) && isfinite(r.y) && isfinite(r.width) &&
           isfinite(r.height) && r.width > 0 && r.height > 0 &&
           isfinite(r.x + r.width) && isfinite(r.y + r.height);
}
static double fit(ODDuoRect r, double w, double h) {
    return valid(r) ? fmin(r.width / w, r.height / h) : 0;
}
static ODDuoRect intersection(ODDuoRect a, ODDuoRect b) {
    double x = fmax(a.x, b.x), y = fmax(a.y, b.y);
    return (ODDuoRect){x, y, fmin(a.x+a.width, b.x+b.width)-x,
                             fmin(a.y+a.height, b.y+b.height)-y};
}
int od_duo_viewport(ODDuoRect bounds, ODDuoInsets safe,
                    const ODDuoRect *cuts, size_t count,
                    double w, double h, ODDuoViewport *out) {
    if (!out || !valid(bounds) || !isfinite(w) || !isfinite(h) ||
        w <= 0 || h <= 0 || count > 64 || (count && !cuts) ||
        !isfinite(safe.top) || !isfinite(safe.left) ||
        !isfinite(safe.bottom) || !isfinite(safe.right) ||
        safe.top < 0 || safe.left < 0 || safe.bottom < 0 || safe.right < 0)
        return 0;
    ODDuoRect area = {bounds.x+safe.left, bounds.y+safe.top,
                     bounds.width-safe.left-safe.right,
                     bounds.height-safe.top-safe.bottom};
    if (!valid(area)) return 0;
    for (size_t i=0; i<count; ++i) {
        if (!valid(cuts[i])) return 0;
        ODDuoRect c=intersection(area, cuts[i]);
        if (!valid(c)) continue;
        /* Bounded conservative placement. Each selected region avoids all
           previous cuts. This intentionally does not claim a global packing
           optimum for arbitrary internal camera arrangements. */
        ODDuoRect choices[] = {
            {area.x,area.y,c.x-area.x,area.height},
            {c.x+c.width,area.y,area.x+area.width-c.x-c.width,area.height},
            {area.x,area.y,area.width,c.y-area.y},
            {area.x,c.y+c.height,area.width,area.y+area.height-c.y-c.height}
        };
        size_t best=0; double score=0;
        for (size_t j=0; j<4; ++j) {
            double value=fit(choices[j],w,h);
            if (value>score) { best=j; score=value; }
        }
        if (!(score>0)) return 0;
        area=choices[best];
    }
    double scale=fit(area,w,h), cw=w*scale, ch=h*scale;
    if (!isfinite(scale) || !(scale>0) || !isfinite(cw) || !isfinite(ch)) return 0;
    ODDuoViewport v={bounds,area,
        {area.x+(area.width-cw)/2,area.y+(area.height-ch)/2,cw,ch},w,h,scale};
    *out=v; return 1;
}
int od_duo_canvas_point(const ODDuoViewport *v, double x, double y,
                         double *lx, double *ly) {
    if (!v || !lx || !ly || !valid(v->canvas) || !isfinite(v->scale) ||
        v->scale<=0 || !isfinite(x) || !isfinite(y) ||
        x<v->canvas.x || y<v->canvas.y ||
        x>=v->canvas.x+v->canvas.width || y>=v->canvas.y+v->canvas.height)
        return 0;
    *lx=(x-v->canvas.x)/v->scale; *ly=(y-v->canvas.y)/v->scale;
    return isfinite(*lx) && isfinite(*ly);
}

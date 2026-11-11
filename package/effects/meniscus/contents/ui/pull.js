.pragma library
// How glass leaves and joins a screen border: Liquid Glass's gooey morphs, the split and merge of
// two glass shapes in one GlassEffectContainer, played with the border as the other glass, the way
// a droplet meets a puddle.
//
// frame, arriving (the split): the border swells into a bead under the panel's place and the panel
// grows out of it as a lobe, a little past its size. It draws away past its place, the neck between
// it and the bead thins to an hourglass and snaps in one frame, leaving both round; the panel
// springs back to its place and size and the bead sinks. Leaving (the merge): the panel gathers
// itself and falls towards the border, which rises to meet it; before they touch each reaches out a
// tip, they join with a fat neck and the panel drains into the bead, which swells with it and
// relaxes flat. The content blurs while the glass is joined and sharpens as the panel parts.
// drawer: a panel that lives on its border slides out of it and back, its foot always fused to it.
// drift: without the pull, the panel only forms in place, springing to size.
//
// The neck is Glass's fuse, the shader's smooth union of the panel and the bead, which joins them
// while the gap between them is under half its reach and bulges them towards each other under all
// of it. Every film takes m, 0 at rest .. 1 gone, played linearly in time (arrivals from 1 to 0):
// the easing and the springs are in here. `rest` is the panel's resting rect and `screen` the rect
// whose `side` border ("top", "bottom", "left", "right") it belongs to, both in the panel's parent.
// `stretch` scales the neck's reach (1 by default, 0 for none) and `bounce` the overshoot of the
// springs and of the swelling (1 by default, 0 for none).
// A film returns the panel's {x, y, width, height}; the bead as `fuse`, in the panel's coordinates,
// with its `fuseRadius` and `fuseReach`; how far the glass has formed (`materialize`); for the
// content laid out at the resting size its `scale`, `opacity` and `blur` (0..1); and `round`,
// 0..1, for corners rounder than at rest, up to a blob.

var JOINED = 0.55;      // share of an arrival by which it has snapped off its border
var PINCH = 0.46;       // ... or sooner, once its neck spans this share of the reach
var DRAIN = 0.35;       // share of a departure by which the panel has drained into the border
var SETTLE = 0.85;      // share of a drawer's arrival its spring takes to come to rest

function clamp(v, lo, hi) { return Math.min(hi, Math.max(lo, v)); }
function clamp01(v) { return clamp(v, 0, 1); }
function mix(a, b, t) { return a + (b - a) * t; }
function smooth(t) { t = clamp01(t); return t * t * (3 - 2 * t); }
function easeOut(t, p) { return 1 - Math.pow(1 - clamp01(t), p); }

// A damped spring's step response, 0 to 1 as t runs 0..1 and settled by 1. bounce 0 is critically
// damped; 1 overshoots by about 9%, 2 by about 22%.
function spring(t, bounce) {
    t = clamp01(t);
    var w0 = 8, zeta = 1 / (1 + 0.65 * Math.max(bounce, 0)), y;
    if (zeta > 0.999) {
        y = 1 - Math.exp(-w0 * t) * (1 + w0 * t);
    } else {
        var a = zeta * w0, wd = w0 * Math.sqrt(1 - zeta * zeta);
        y = 1 - Math.exp(-a * t) * (Math.cos(wd * t) + a / wd * Math.sin(wd * t));
    }
    return mix(y, 1, smooth((t - 0.8) / 0.2));
}

// A rect in border space: `a` runs along the border, `n` from it into the screen.
function toBorder(r, screen, side) {
    switch (side) {
    case "top": return { a: r.x, span: r.width, near: r.y - screen.y, depth: r.height };
    case "left": return { a: r.y, span: r.height, near: r.x - screen.x, depth: r.width };
    case "right": return { a: r.y, span: r.height, near: screen.x + screen.width - r.x - r.width, depth: r.width };
    default: return { a: r.x, span: r.width, near: screen.y + screen.height - r.y - r.height, depth: r.height };
    }
}

function fromBorder(a, span, n0, n1, screen, side) {
    switch (side) {
    case "top": return Qt.rect(a, screen.y + n0, span, n1 - n0);
    case "left": return Qt.rect(screen.x + n0, a, n1 - n0, span);
    case "right": return Qt.rect(screen.x + screen.width - n1, a, n1 - n0, span);
    default: return Qt.rect(a, screen.y + screen.height - n1, span, n1 - n0);
    }
}

function pose(body, pool, reach, poolRadius, scale, opacity, materialize, blur, round) {
    return {
        x: body.x, y: body.y, width: body.width, height: body.height,
        fuse: pool ? Qt.rect(pool.x - body.x, pool.y - body.y, pool.width, pool.height) : Qt.rect(0, 0, 0, 0),
        fuseRadius: pool ? poolRadius : 0,
        fuseReach: pool ? reach : 0,
        materialize: clamp01(materialize),
        scale: scale,
        opacity: clamp01(opacity),
        blur: clamp01(blur),
        round: clamp01(round),
    };
}

function frame(m, arriving, rest, screen, side, stretch, bounce) {
    var t = clamp01(arriving ? 1 - m : m);
    var r = toBorder(rest, screen, side);
    var w = r.span, h = r.depth, gap = Math.max(r.near, 0), centre = r.a + w / 2;
    var R = clamp(0.25 * Math.min(w, h), 16, 72);      // the bead the border swells into
    var crest = 0.45 * R;                               // how far out of the border it rises
    var k = clamp(stretch, 0, 2) * R;
    var hidden = -k / 2 - 4;                            // a bead this low neither shows nor joins
    var give = clamp(bounce, 0, 2);
    var swell = 1 + 0.2 * give * Math.min(1, 96 / Math.min(w, h));
    var seed = Math.min(2 * R, w, h);                   // the lobe a panel grows from
    var span, depth, near, top, radius = R, reach = k, blur, materialize, round;

    if (arriving) {
        // The panel grows out of the bead past its size and relaxes to it. Its near edge leaves the
        // border and carries on past its place, stretching the neck, which the bead holds on to,
        // until the neck snaps; then the panel springs back to its place and the bead sinks.
        var grow = easeOut(t / 0.45, 2), relax = smooth((t - JOINED) / 0.35);
        span = mix(mix(seed, w * swell, grow), w, relax);
        depth = mix(mix(seed, h * swell, grow), h, relax);
        var lift = 0.4 * k * give;
        var travel = function (u) { return mix(-seed / 2, gap + lift, easeOut(u / JOINED, 2)); };
        var bead = function (u) {
            return Math.min(mix(hidden, crest, smooth(u / 0.1)),
                            travel(u) - PINCH * k * smooth((u - 0.2) / (JOINED - 0.2)));
        };
        var snap = JOINED;
        for (var i = 1; i < 32; i++) {
            if (travel(i / 32 * JOINED) - bead(i / 32 * JOINED) >= PINCH * k) {
                snap = i / 32 * JOINED;
                break;
            }
        }
        near = t < JOINED ? travel(t) : gap + lift * (1 - spring((t - JOINED) / (1 - JOINED), give));
        if (t < snap) {
            top = bead(t);
        } else {
            // Parted: the neck is gone in one frame; a reach of a pixel keeps the bead drawn, apart.
            top = mix(bead(snap), hidden, smooth((t - snap) / 0.2));
            reach = 1;
        }
        blur = 1 - smooth((t - 0.25) / (snap - 0.05));
        materialize = smooth(t / 0.2);
        round = 1 - grow;
    } else {
        // The panel gathers itself and falls towards the bead's middle, faster and faster, while the
        // bead rises to meet it; it drains into the bead, which swells and then relaxes flat.
        var fall = clamp01(t / DRAIN);
        var drain = smooth((t - 0.1) / (DRAIN - 0.1));
        var full = smooth((t - 0.15) / (DRAIN - 0.15));
        var ebb = smooth((t - DRAIN) / (0.8 - DRAIN));
        radius = R * mix(mix(1, 1.2, full), 1, ebb);
        top = t < DRAIN ? mix(hidden, mix(crest, crest + 0.25 * R, full), smooth(t / 0.12))
                        : mix(crest + 0.25 * R, hidden, ebb);
        var size = mix(1, 0.94, smooth(t / 0.12));
        span = mix(w * size, R, drain);
        depth = mix(h * size, R, drain);
        var mid = mix(gap + h / 2, top - radius, fall * fall);
        near = mid - depth / 2;
        blur = smooth(t / 0.25);
        materialize = 1 - smooth((t - 0.8) / 0.2);
        round = drain;
    }

    var scale = Math.min(1, span / w, depth / h);
    var body = fromBorder(centre - span / 2, span, near, near + depth, screen, side);
    var pool = k > 0 && top > hidden + 0.5
             ? fromBorder(centre - radius, 2 * radius, top - 2 * radius, top, screen, side) : null;
    return pose(body, pool, reach, radius, scale, smooth((scale - 0.12) / 0.3), materialize, blur, round);
}

function drawer(m, arriving, rest, screen, side, stretch, bounce) {
    var t = clamp01(arriving ? 1 - m : m);
    var r = toBorder(rest, screen, side);
    var w = r.span, h = r.depth, centre = r.a + w / 2;
    var k = clamp(stretch, 0, 2) * Math.min(48, 0.5 * Math.min(w, h));
    // Out of sight with its foot's fillets when closed; past rest, the foot stretches a neck.
    var out = arriving ? spring(t / SETTLE, bounce) : 1 - t * t;
    var near = r.near - (1 - out) * (r.near + h + k / 2 + 4);
    var body = fromBorder(r.a, w, near, near + h, screen, side);
    // The border's surface, a little wider than the foot and just past the border so it never
    // shows on its own; the foot meets it in concave fillets. A drawer is solid glass all along.
    var pool = k > 0 ? fromBorder(centre - w / 2 - k, w + 2 * k, -k - 2, -2, screen, side) : null;
    return pose(body, pool, k, 0, 1, 1, 1, 0, 0);
}

function drift(m, arriving, rest, screen, side, bounce) {
    var t = clamp01(arriving ? 1 - m : m);
    var r = toBorder(rest, screen, side);
    var s, shift, blur, materialize, opacity;
    if (arriving) {
        s = mix(0.88, 1, spring(t / SETTLE, bounce));
        shift = 24 * (1 - spring(t / SETTLE, bounce / 2));
        blur = 1 - smooth((t - 0.2) / 0.5);
        materialize = smooth(t / 0.4);
        opacity = smooth(t / 0.3);
    } else {
        s = mix(1, 0.9, smooth(t));
        shift = 16 * t * t;
        blur = smooth(t / 0.5);
        materialize = 1 - smooth((t - 0.15) / 0.85);
        opacity = 1 - smooth((t - 0.3) / 0.6);
    }
    var span = r.span * s, depth = r.depth * s;
    var near = r.near + (r.depth - depth) / 2 - shift;
    var body = fromBorder(r.a + (r.span - span) / 2, span, near, near + depth, screen, side);
    return pose(body, null, 0, 0, s, opacity, materialize, blur, 0);
}

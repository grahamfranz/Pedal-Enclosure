/* ============================================================
 *  Parametric Guitar Pedal Enclosure
 *  ------------------------------------------------------------
 *  Inspired by Hammond die-cast boxes (1590A / 1590B / 1590BB /
 *  125B). Open-bottom shell with a removable lid, corner screw
 *  bosses, and all the usual holes for pots, footswitch, LED,
 *  1/4" jacks and a DC barrel jack.
 *
 *  Layout (top-down view, looking at the top face):
 *
 *        +X  <-- back edge (DC jack)
 *     +-------------------+
 *     |       [dc]        |
 *     |  o   o   o   o    |   knob row
 *  [O]|                   |[I]   -Y = output,  +Y = input
 *     |        *          |   LED
 *     |                   |
 *     |       ( X )       |   footswitch
 *     |                   |
 *     +-------------------+
 *        -X  <-- toe
 *
 *  Tweak everything in the Customizer panel (Window > Customizer
 *  in OpenSCAD) or edit the variables below.
 *
 *  License: public domain / CC0
 * ============================================================ */

/* [Preset] */
// Pick a common Hammond size, or choose "custom" to use the fields below.
preset = "1590B"; // [custom, 1590A, 1590B, 1590BB, 125B]

/* [Render] */
// Which part to render.
part = "both"; // [enclosure, lid, both, assembled]
// Flip the enclosure so the top face is on the bed (cleanest finish for the
// labeled face). Either way each part's print-bottom sits on Z = 0.
flip_enclosure_for_print = true;
// Flip the lid so any recesses (nut pockets or counterbores) face away from
// the bed — they bridge cleanly when printed open-side up.
flip_lid_for_print = true;

/* [Custom Outer Size — used when preset = "custom"] */
custom_length = 112;  // along X (long axis)
custom_width  = 60;   // along Y
custom_height = 31;   // along Z

/* [Shell] */
wall_thickness = 2.5;
lid_thickness  = 3.0;  // bump to ≥ nut_pocket_depth + 0.6 mm when using nut modes
corner_radius  = 5;
// Smoothness — higher = prettier curves, slower render.
facets = 72;

/* [Lid Locating Lip] */
// A stepped flange on the lid perimeter that sits on the enclosure rim,
// preventing shear and keeping the lid aligned.
include_lip = true;
lip_height  = 1.5;  // height of the perimeter flange (mm)

/* [Screw Mounting] */
// How the lid screws fasten into the corner bosses.
include_screw_bosses = false; // set false to free corner space for a full-width board
boss_fastener   = "hex_nut"; // [self_tap, hex_nut, square_nut]
screw_hole_d    = 2.7;   // pilot hole for self_tap (M3 → 2.7 mm)
screw_boss_d    = 8;     // corner boss outside diameter
screw_inset     = 6;     // distance from outer wall to boss centre
lid_clearance_d = 3.6;   // M3 free-fit through the lid (also used as boss clearance for nut modes)
lid_counterbore = true;  // recess the screw heads into the lid
// Nut pocket — used when boss_fastener is "hex_nut" or "square_nut".
// Pocket is recessed into the BOTTOM (outside) face of the lid, so make sure
// lid_thickness is at least nut_pocket_depth + ~0.6 mm of plastic on top.
nut_af          = 5.5;   // across-flats dimension (M3 standard hex/square = 5.5 mm)
nut_pocket_depth = 2.4;  // M3 hex ≈ 2.4 mm, M3 square ≈ 1.8 mm

/* [Board Mount] */
// Raised standoffs inside the enclosure for mounting a CircuitMesh or other proto board.
board_standoffs       = true;
board_standoff_height = 10;   // distance from the top-wall underside to the board (mm)
board_standoff_d      = 6;    // standoff post diameter (mm)
board_screw_margin    = 4;    // from inner wall corner to standoff centre — match your board's value
board_pilot_d         = 2.7;  // M3 self-tap pilot drilled up into the standoff

/* [Top: Knobs] */
// Automatically adjust knob count for tight enclosures (1590A uses 2 knobs, others use 3)
num_knobs          = (preset == "1590A") ? 2 : 3;
knob_hole_d        = 7.5;   // 3/8" pot bushing clearance
knob_row_from_back = 18;    // distance of knob row from +X wall
knob_side_margin   = 13;    // distance from first/last knob to long side

/* [Top: Footswitch] */
footswitch_hole_d     = 12.5;  // 12 mm stomp switch
footswitch_from_front = 22;    // distance from -X wall

/* [Top: LED] */
include_led    = true;
led_hole_d     = 5.2;    // 5 mm LED pass-through (use ~8.2 for bezel)
led_from_front = 45;

/* [Sides: Audio Jacks] */
input_jack_d         = 9.5;   // 1/4" enclosed jack
output_jack_d        = 9.5;
jack_height_from_lid = 15;    // centre height above the lid seat

/* [Back: DC Jack] */
include_dc_jack        = true;
dc_jack_d              = 12;   // 2.1 mm barrel jack with panel boss
dc_jack_board_offset   = -6;    // barrel jack centre height above the board surface

/* [Hidden] */
$fn = facets;
EPS = 0.02;

// ============================================================
//  Geometry
// ============================================================

function _preset_dims() =
    preset == "1590A"  ? [92.5, 38.5, 31] :
    preset == "1590B"  ? [112,   60,   31] :
    preset == "1590BB" ? [119,   94,   34] :
    preset == "125B"   ? [121,   66,   39] :
                         [custom_length, custom_width, custom_height];

_dims = _preset_dims();
L = _dims[0];
W = _dims[1];
H = _dims[2];

// Auto-calculate DC jack height to align with a board-mounted barrel jack.
dc_jack_height_from_lid = H - wall_thickness - board_standoff_height + dc_jack_board_offset - lid_thickness;

echo(str("Outer size: ", L, " x ", W, " x ", H, " mm"));

// Sanity check: nut pocket must fit inside the lid with some plastic on top.
if ((boss_fastener == "hex_nut" || boss_fastener == "square_nut")
    && lid_thickness < nut_pocket_depth + 0.6)
    echo(str("WARNING: lid_thickness (", lid_thickness,
             ") is too thin for the ", boss_fastener, " pocket (",
             nut_pocket_depth, " mm). Bump lid_thickness to at least ",
             nut_pocket_depth + 0.6, " mm."));

// ---------- helpers ----------

module rounded_prism(l, w, h, r) {
    rr = max(0.1, min(r, min(l, w) / 2 - 0.1));
    hull() for (x = [rr, l - rr], y = [rr, w - rr])
        translate([x, y, 0]) cylinder(r = rr, h = h);
}

function _corner_points() = [
    [screw_inset,     screw_inset    ],
    [L - screw_inset, screw_inset    ],
    [screw_inset,     W - screw_inset],
    [L - screw_inset, W - screw_inset]
];

function _board_standoff_points() = [
    [wall_thickness + board_screw_margin, wall_thickness + board_screw_margin              ],
    [L - wall_thickness - board_screw_margin, wall_thickness + board_screw_margin          ],
    [wall_thickness + board_screw_margin, W - wall_thickness - board_screw_margin          ],
    [L - wall_thickness - board_screw_margin, W - wall_thickness - board_screw_margin      ]
];

// A cylinder pointing in +X, +Y, -X or -Y — handy for side cutouts.
module hole_thru_y_plus(x, z, d) {            // pokes through +Y wall
    translate([x, W - wall_thickness - 1, z])
        rotate([-90, 0, 0]) cylinder(d = d, h = wall_thickness + 2);
}
module hole_thru_y_minus(x, z, d) {           // pokes through -Y wall
    translate([x, wall_thickness + 1, z])
        rotate([90, 0, 0]) cylinder(d = d, h = wall_thickness + 2);
}
module hole_thru_x_plus(y, z, d) {            // pokes through +X wall (back)
    translate([L - wall_thickness - 1, y, z])
        rotate([0, 90, 0]) cylinder(d = d, h = wall_thickness + 2);
}

// ---------- the enclosure (open bottom, closed top) ----------

module enclosure() {
    difference() {
        union() {
            // Outer shell with hollow interior, open at Z = 0.
            difference() {
                rounded_prism(L, W, H, corner_radius);
                translate([wall_thickness, wall_thickness, -EPS])
                    rounded_prism(
                        L - 2 * wall_thickness,
                        W - 2 * wall_thickness,
                        H - wall_thickness + EPS,
                        max(0.5, corner_radius - wall_thickness)
                    );
            }
            // Corner screw bosses (solid posts running top-to-bottom inside).
            if (include_screw_bosses)
                for (p = _corner_points())
                    translate([p[0], p[1], 0])
                        cylinder(d = screw_boss_d, h = H - wall_thickness);
            // Board standoffs — posts hanging from the top wall so a proto board
            // can mount at a fixed distance below the top face.
            if (board_standoffs)
                for (p = _board_standoff_points())
                    translate([p[0], p[1], H - wall_thickness - board_standoff_height])
                        cylinder(d = board_standoff_d, h = board_standoff_height);
        }

        // -------- cutouts --------

        // Boss fastener holes — self_tap gets a tight pilot in the boss;
        // nut modes get a clearance hole all the way through so the screw can
        // pass from the top face down to a captive nut on the lid's underside.
        if (include_screw_bosses)
            for (p = _corner_points())
                translate([p[0], p[1], -EPS])
                    cylinder(
                        d = boss_fastener == "self_tap" ? screw_hole_d : lid_clearance_d,
                        h = boss_fastener == "self_tap" ? H - wall_thickness - 1
                                                        : H - wall_thickness + EPS
                    );

        // Board standoff pilot holes — drilled UP into the standoff bottom,
        // so the board is screwed into place from below.
        if (board_standoffs)
            for (p = _board_standoff_points())
                translate([p[0], p[1], H - wall_thickness - board_standoff_height - EPS])
                    cylinder(d = board_pilot_d, h = 5 + EPS);

        // Knob row (top face).
        knob_span    = W - 2 * knob_side_margin;
        knob_spacing = num_knobs > 1 ? knob_span / (num_knobs - 1) : 0;
        for (i = [0 : num_knobs - 1]) {
            yk = num_knobs > 1
                ? knob_side_margin + i * knob_spacing
                : W / 2;
            translate([L - knob_row_from_back, yk,
                       H - wall_thickness - 1])
                cylinder(d = knob_hole_d, h = wall_thickness + 2);
        }

        // Footswitch (top face).
        translate([footswitch_from_front, W / 2,
                   H - wall_thickness - 1])
            cylinder(d = footswitch_hole_d, h = wall_thickness + 2);

        // LED (top face).
        if (include_led)
            translate([led_from_front, W / 2,
                       H - wall_thickness - 1])
                cylinder(d = led_hole_d, h = wall_thickness + 2);

        // Audio jacks (centred along X on the long sides).
        jz = lid_thickness + jack_height_from_lid;
        hole_thru_y_plus (L / 2, jz, input_jack_d);
        hole_thru_y_minus(L / 2, jz, output_jack_d);

        // DC jack (back / +X wall).
        if (include_dc_jack)
            hole_thru_x_plus(
                W / 2,
                lid_thickness + dc_jack_height_from_lid,
                dc_jack_d
            );

        // Top-wall through-holes: lets screws enter from the top face. Needed when
        // there are no bosses (so the screw has a path) or when using machine screws
        // in hex/square nut modes (to thread into the nut pocket on the lid underside).
        if (!include_screw_bosses) {
            // No bosses: use standoff positions so holes align with standoffs.
            for (p = _board_standoff_points()) {
                if (board_standoffs) {
                    // Hole must reach down through standoff to pilot hole
                    translate([p[0], p[1], H - wall_thickness - board_standoff_height - EPS])
                        cylinder(d = lid_clearance_d, h = board_standoff_height + wall_thickness + 2 * EPS);
                } else {
                    // Just through the top wall
                    translate([p[0], p[1], H - wall_thickness - EPS])
                        cylinder(d = lid_clearance_d, h = wall_thickness + 2 * EPS);
                }
                if (lid_counterbore && (boss_fastener == "hex_nut" || boss_fastener == "square_nut"))
                    translate([p[0], p[1], H - 1.6])
                        cylinder(d = lid_clearance_d + 3, h = 1.6 + EPS);
            }
        } else if (boss_fastener == "hex_nut" || boss_fastener == "square_nut") {
            // With bosses and nut modes: use corner positions.
            for (p = _corner_points()) {
                translate([p[0], p[1], H - wall_thickness - EPS])
                    cylinder(d = lid_clearance_d, h = wall_thickness + 2 * EPS);
                if (lid_counterbore)
                    translate([p[0], p[1], H - 1.6])
                        cylinder(d = lid_clearance_d + 3, h = 1.6 + EPS);
            }
        }
    }
}

// ---------- the lid (bottom plate) ----------

module lid() {
    lR = max(0.5, corner_radius - wall_thickness);
    // Clearance between the plug and the cavity walls so the plug slips in
    // without binding.
    lip_fit = 0.3;
    plug_L  = L - 2 * wall_thickness - 2 * lip_fit;
    plug_W  = W - 2 * wall_thickness - 2 * lip_fit;
    plug_R  = max(0.5, lR - lip_fit);
    total_h = lid_thickness + (include_lip ? lip_height : 0);

    difference() {
        union() {
            // Base plate: full L × W footprint, same as the enclosure.
            rounded_prism(L, W, lid_thickness, corner_radius);
            // Raised plug that drops into the enclosure cavity for lateral
            // location. Same inner profile as the cavity, slightly undersized.
            if (include_lip)
                translate([wall_thickness + lip_fit,
                           wall_thickness + lip_fit,
                           lid_thickness])
                    rounded_prism(plug_L, plug_W, lip_height, plug_R);
        }
        // Screw holes all the way through base + plug.
        // When there are no bosses, use standoff positions so holes align with standoffs.
        // Otherwise use corner positions.
        if (!include_screw_bosses) {
            for (p = _board_standoff_points()) {
                translate([p[0], p[1], -EPS])
                    cylinder(d = lid_clearance_d, h = total_h + 2 * EPS);
                if (boss_fastener == "hex_nut") {
                    translate([p[0], p[1], -EPS])
                        cylinder(d = (nut_af + 0.4) / cos(30),
                                 h = nut_pocket_depth + EPS, $fn = 6);
                } else if (boss_fastener == "square_nut") {
                    translate([p[0] - (nut_af + 0.4) / 2,
                               p[1] - (nut_af + 0.4) / 2,
                               -EPS])
                        cube([nut_af + 0.4, nut_af + 0.4, nut_pocket_depth + EPS]);
                }
            }
        } else {
            for (p = _corner_points()) {
                translate([p[0], p[1], -EPS])
                    cylinder(d = lid_clearance_d, h = total_h + 2 * EPS);
                if (boss_fastener == "self_tap") {
                    if (lid_counterbore)
                        translate([p[0], p[1], -EPS])
                            cylinder(d = lid_clearance_d + 3, h = 1.6);
                } else if (boss_fastener == "hex_nut") {
                    translate([p[0], p[1], -EPS])
                        cylinder(d = (nut_af + 0.4) / cos(30),
                                 h = nut_pocket_depth + EPS, $fn = 6);
                } else if (boss_fastener == "square_nut") {
                    translate([p[0] - (nut_af + 0.4) / 2,
                               p[1] - (nut_af + 0.4) / 2,
                               -EPS])
                        cube([nut_af + 0.4, nut_af + 0.4, nut_pocket_depth + EPS]);
                }
            }
        }
    }
}

// ============================================================
//  Render
// ============================================================

// Enclosure oriented for printing: either as-modeled (open-side down,
// rim on the bed) or flipped (open-side up, top face on the bed).
// In both cases the part's lowest point is at Z = 0.
module enclosure_for_print() {
    if (flip_enclosure_for_print)
        translate([0, W, H]) rotate([180, 0, 0]) enclosure();
    else
        enclosure();
}

module show_both() {
    enclosure_for_print();
    // When flipped, rotate so recesses point away from the bed. The lid's
    // total height is base + plug, and after rotate([180,0,0]) its Y range
    // is [-W..0] — translate Y by 2W + 15 so it sits past the enclosure.
    lid_total_h = lid_thickness + (include_lip ? lip_height : 0);
    if (flip_lid_for_print)
        translate([0, 2 * W + 15, lid_total_h]) rotate([180, 0, 0]) lid();
    else
        translate([0, W + 15, 0]) lid();
}

module show_assembled() {
    translate([0, 0, lid_thickness]) enclosure();
    lid();
}

if      (part == "enclosure") enclosure_for_print();
else if (part == "lid")       lid();
else if (part == "both")      show_both();
else if (part == "assembled") show_assembled();

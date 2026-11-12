# Assemblies, joints and fits

## Part frames and joints

Build every part at a convenient origin in its own frame (base on the table, yoke at its mounting face, cradle on its pivot axis), attach joints, and let `connect_to` place things. Keeps each part simple and its STL already in a sane frame.

- `RigidJoint(label, part, Location)` - a frame on the part.
- `RevoluteJoint(label, part, axis=Axis(origin, dir), angular_range=(lo, hi))` - when connected to a child's `RigidJoint`, the child joint's +Z is aligned to `dir` and rotated `angle` about it. `connect_to` raises `ValueError` outside `angular_range`. To probe past the design range (finding real limits), override the range constants in the probe script, not the model.
- **0.13 bug** (undocumented): `angle_reference` with a non-Z axis applies the axis rotation twice - `relative_to` builds a frame whose Z is already the axis and multiplies it onto the axis location. With `Axis.X` and reference `(0, 1, 0)` a child's local Z arm ends up along world +Z. Likely a regression from the [#1410](https://github.com/gumyr/build123d/issues/1410) fix, which only tested `Axis.Z`. Leave it out, and give the child `RigidJoint(..., Axis(origin, dir).location)` with the same `dir`, so angle 0 is identity.
- Default `angular_range` is `(0, 360)` - pass `(-180, 180)` or whatever you need, or negative angles raise.
- The docs' Joints and Assemblies chapters cover the rest (grep `out/build123d-llms.txt`). Worth knowing from them: `shape.global_location` is the world location of a child inside a nested assembly, `show_topology()` prints an assembly tree with locations, and repeated hardware can be `copy.copy(screw).locate(...)` - a shallow copy shares the geometry, so 20 screws cost one.
- `parent.joints["x"].connect_to(child.joints["y"], angle=a)` moves **child** in place. Build fresh parts for each pose (`def pose(pan, tilt) -> Assembly` that constructs everything).
- When unsure what a joint does, connect a marker part - arms of length 10/20/30 along local X/Y/Z - and print its bbox. Cheaper than reasoning about rotation order.

A frozen dataclass (`Assembly(base, yoke, ..., bearings, hardware)`) returned by `pose()` beats a dict - named fields and you can add `compound()` for export. Every script (fit table, sweep, renders, export) imports `pose` - nothing else places parts.

### Worked example: a bearing seated in a housing, a wheel spinning on top

Tested on 0.13. At `pose(0)` the nub is at +X, at `pose(90)` it's at +Y, and the bearing sits flush with the housing top.

```python
from dataclasses import dataclass
from build123d import *
from bd_warehouse.bearing import SingleRowDeepGrooveBallBearing

BEARING = "M8-22-7"  # 608: OD 22, bore 8, width 7
OD, W = 22.0, 7.0
HOUSING_H = 15.0
RUN_GAP = 0.5  # wheel to housing
CENTRED = (Align.CENTER, Align.CENTER, Align.MIN)

def housing() -> Part:
    part = Cylinder(20, HOUSING_H, align=CENTRED) - Pos(0, 0, HOUSING_H - W) * Cylinder(OD / 2, W, align=CENTRED)
    RigidJoint("bearing", part, Location((0, 0, HOUSING_H - W)))  # bearing joint "a" is its bottom face
    RevoluteJoint("spin", part, axis=Axis((0, 0, HOUSING_H + RUN_GAP), (0, 0, 1)), angular_range=(-180, 180))
    return part

def wheel() -> Part:
    part = Cylinder(30, 5, align=CENTRED) + Pos(20, 0, 5) * Box(4, 4, 4, align=CENTRED)
    RigidJoint("hub", part, Location((0, 0, 0)))  # +Z of this frame goes along the spin axis
    return part

@dataclass(frozen=True)
class Assembly:
    housing: Part
    wheel: Part
    bearing: Compound

def pose(angle: float) -> Assembly:
    h, w, b = housing(), wheel(), SingleRowDeepGrooveBallBearing(BEARING, "SKT")
    h.joints["bearing"].connect_to(b.joints["a"])
    h.joints["spin"].connect_to(w.joints["hub"], angle=angle)
    return Assembly(h, w, b)
```

For a horizontal axis, put the RevoluteJoint on `Axis(origin, (1, 0, 0))` and give the child `RigidJoint("hub", part, Axis((0, 0, 0), (1, 0, 0)).location)` built along the same direction - then angle 0 is the as-modelled orientation.

## bd_warehouse parts

- Fasteners (`SocketHeadCapScrew("M4-0.7", 16, "iso4762", simple=True)`): origin under the head, shank along -Z, joint `"a"`. Point the mounting joint's +Z out of the hole. `simple=True` models threads at the **minor** diameter, so they don't false-clash with tap holes - and can't tell you a tap hole is undersized either.
- Bearings (`SingleRowDeepGrooveBallBearing("M8-22-7", "SKT")`): joints `"a"` (bottom face) and `"b"` (top). `.solids()` is `[outer ring, inner ring, balls...]`, which is how you check a shoulder sits on the inner race. Sizes via `SingleRowDeepGrooveBallBearing.sizes("SKT")`. 608 inner race OD 12.1, 625 is 8.4.
- `VSlotLinearRail("20x20", length)` in `bd_warehouse.open_builds` for 2020 extrusion.
- Flatten to solids before any boolean (`Compound(x.solids())`) - see SKILL.md.

## Fit table, not "no clashes"

Zero interference proves nothing about engagement or seating. Write down every intended relationship and check them all (`tools/fit.py`):

```python
from tools.fit import Expect, check, floating, retained
a = pose(0)
for ok, line in check([
    Expect("608 outer race in hub", a.bearings[0].solids()[0], a.hub),         # seat: touching, no overlap
    Expect("hub to bracket side gap", a.hub, a.bracket, gap=1.0),              # designed gap, +/- 0.05
    Expect("spool clear of wall", a.spool, a.bracket, min_gap=5),              # stay-clear, anything >= 5
    Expect("snap hook engagement", a.hook, a.wall, overlap=20),                # intended interference
]):
    print(line)
```

If a seat shows overlap (a bearing in its pocket reporting hundreds of mm³), the pocket is too small or too shallow, or the joint is in the wrong place - fix the geometry, don't relabel it as a press fit. `gap=` is a designed value, not a minimum - a 0.5 mm running fit that measures 11 mm means the part is floating. Use `min_gap=` for stay-clear requirements. Seats are touching with zero overlap; don't model press fits as overlap.

Then two checks that don't depend on you having thought of the right rows:

- `touching, loose = floating(named, ground="bracket")` - contact graph of every part, and the parts with no chain of contacts back to the ground part. Anything in `loose` isn't held by anything. Also read the graph: a rotating part should touch only its bearings (or bushings), never the static parts. This caught a bearing pocket overcut both ways that left the bearing 5 um off its seat - invisible in renders, missed by every other check.
- `retained(part, everything_else, axis, max_float)` - how far a part slides each way along its axis before hitting something (`None` = it comes off). Axially retained means both directions are blocked within the float you intended. If one direction is meant to be open (gravity, a lid), say so in the requirements table.

Plus `clashes({...})` across everything for the stuff you didn't think of.

A pair whose gap is always small (pin in a bore) masks everything else when you measure part-to-part clearance - measure the specific sub-parts you care about (`bearing.solids()[0]` for the outer race).

When cutting a pocket or hole, overcut only past the **open** end (`OVERCUT` beyond the face). Centring a `+0.01` fudge on the pocket also moves the floor and unseats whatever sits in it.

## Range of motion

Sweep `pose()` over a grid. Run `clashes` once at the home pose, then in the sweep only check parts that move relative to each other: `clashes_between(ground, pan_group, tilt_group)`, leaving out the bearings that are the joints. A full `clashes` per pose on the pan-tilt was ~2.4 s (booleans against every bearing ball) and an 8 minute sweep. Coarse grids lie: in the pan-tilt, pan 0 and 90 were clear and 45 clashed with the screw heads. A point at radius R moves `R * dtheta` per step, so either sample finer than your smallest clearance allows or work out where the worst case is and include it. Report `clearance` at each pose rather than pass/fail - a trend towards zero tells you where the limit is.

Positive control: break the design on purpose (lower the axis 10 mm) and confirm the sweep finds it.

## Insertion path

Every part needs a way in. `insertion_path(part, already_placed, direction, travel, step)` slides the part out along its assembly direction and reports collisions. Use a step smaller than the narrowest gap on the way. This caught printed-on pivot pins that were wider than the gap between the yoke arms - perfectly clash-free, completely unassemblable.

## Mechanical rules the model won't tell you

These came from looking at a section through the pivot after every check passed:

- Clamp only the **inner** race on the rotating side and seat the outer race in the fixed housing. Everything else gets a gap - otherwise tightening drags a part into the housing. A loose spacer works where a printed boss would block insertion.
- Check fastener heads against what they bear on (an M5 SHCS head is 8.72, wider than a 625 inner race - add a shim).
- A shaft resting on a bearing needs a real shoulder on the inner race. Don't trust comments that say one exists.
- Heads proud of a surface something rotates over will clip it - counterbore them.

## Export

```python
part.color = Color("orange"); part.label = "yoke"   # per child
export_step(Compound(children=[...], label="assembly"), "out/assembly.step")
```

`import_step` round-trips labels, colours and child count - check them. STLs come from the zero pose, moved back to the part frame: `part.moved(part.location.inverse())`.

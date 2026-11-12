# build123d 0.13 API notes

The big ones (builder auto-add, flattening compounds, joints) are in SKILL.md. "(docs)" means it's in the official narrative docs - grep the llms-full.txt for it. The rest were only found by tripping over them.

- `shape.is_valid` is a property, not a method.
- `Hole`, `CounterBoreHole`, `CounterSinkHole` take **radius**.
- `Plane.XZ` normal is -Y, so `extrude(Plane.XZ * sketch, 5)` goes towards -Y and `Plane.XZ.offset(5)` sits at y = -5. `Plane.YZ` normal is +X.
- Sketches are built on a local `Plane.XY` and published to their placement on exit, so inside `BuildSketch(Plane.XZ)` selectors see local XY coordinates, and nested builders don't inherit placements (docs: Tips/FAQ).
- `a.intersect(b)` returns a ShapeList or None. Use `(a & b).volume` (empty gives 0).
- `section(part, plane)` (docs) or `part & plane` give a Sketch of the exact section faces - same result.
- `split(shape, plane, keep=...)` can return an empty shape - check `.faces()` before using it.
- `from build123d import *` exports `Solid`, `Part`, `Compound` but not `Shape` (`from build123d.topology import Shape`).
- `Location * Vector` isn't supported - use vector addition or `Pos(v) * shape`. `Vector` has no `to_tuple` (that's `Color`) and isn't subscriptable (`v[0]` raises) - use `tuple(v)` or `v.X`.
- `Pos(vector)`, `Pos(x, y, z)` and `Pos(Z=1.5)` all work.
- `project_to_viewport` takes a camera position (docs) and is perspective (not documented) - see [viewing](viewing.md).
- `ExportSVG` 0-255 RGB tuples are deprecated (docs), use colour names or hex. Layer text is hollow without `fill_color`.
- The docs' logging example (`BuildPart context requested by Box`) is out of date for 0.13 - it logs `None` for the class. Count the `Completed integrating` lines instead.

## Modelling patterns that work

Profile first: sketch in 2D (`BuildSketch` or `Rectangle(...) + Circle(...)`), fillet 2D corners there, then `extrude`/`revolve`. 2D fillets almost never fail; 3D ones on a stack of boxes often do. Do the remaining 3D fillets and chamfers last.

Selecting edges (all return ShapeLists you can pass straight to fillet/chamfer):

```python
cut = plate - Pos(Z=2) * Box(16, 16, 5)
cut.edges(Select.NEW)                          # edges the cut created (the pocket rim) - works on algebra results too
cut.edges(Select.LAST)                         # everything the right operand brought in (incl. the pocket's vertical corners)
part.edges().filter_by(Axis.Z)                 # straight edges parallel to Z - the vertical corners
part.edges().group_by(Axis.Z)[-1]              # edges at the highest Z - the top rim
part.faces().sort_by(Axis.Z)[-1].edges().filter_by(GeomType.CIRCLE)   # face first, then its edges: hole rims on the top face
part.edges().filter_by(lambda e: e.is_interior)  # concave edges - inside corners
```

- `Select.NEW` vs `LAST` is easy to get wrong: the pocket's vertical edges belong to the cutting box, so they're `LAST`, not `NEW`. Print `len(...)` and a centre or two before filleting.
- Algebra: `fillet(edges, 2)` or `part.fillet(2, edges)`, `part.chamfer(0.5, None, edges)`. Builder: `fillet(bp.edges().filter_by(Axis.Z), 2)`.
- "No suitable edges" / `IndexError` from `fillet` means the selection was empty.
- Countersunk screws use `CounterSinkHole(radius, counter_sink_radius)`, not `CounterBoreHole`.
- `Hole`, `CounterBoreHole`, `CounterSinkHole` cut along -Z of the current location. For a hole in a side face, locate on the face: `with Locations(bp.faces().sort_by(Axis.X)[-1]): Hole(2, 5)`.
- Fuse many shapes in one go - `Part() + [loc * Box(...) for loc in locs]` or `GridLocations(...) * shape` - not `+=` in a loop, which re-fuses everything each time (docs: "Performance considerations in algebra mode", 25x in their example).
- Repeated hardware (screws, bearings): `copy.copy(screw).locate(loc)` shares the geometry - much faster and smaller STEP files than building each one (docs: Assemblies, "Shallow vs. Deep Copies").

## Assemblies and export

- `child.location` is relative to its parent compound; `child.global_location` is the world placement. `assembly.show_topology()` prints the tree with labels and locations - quickest check that an export is structured right.
- `pack(shapes, padding, align_z=True)` lays parts out flat on the XY plane without overlapping - handy for a print plate STL.
- `export_step` keeps `label` and `color` on compound children and `import_step` reads them back.

## bd_warehouse class names

Guessing these costs a run each. `fastener`: `SocketHeadCapScrew`, `CounterSunkScrew`, `ButtonHeadScrew`, `PanHeadScrew`, `HexHeadScrew`, `SetScrew`, `ShoulderScrew`, `HexNut`, `SquareNut`, `HeatSetNut`, `PlainWasher`, plus `ClearanceHole`/`TapHole`/`InsertHole` builder helpers. `bearing`: `SingleRowDeepGrooveBallBearing`, `SingleRowCappedDeepGrooveBallBearing`, `SingleRowAngularContactBallBearing`, `SingleRowCylindricalRollerBearing`, `SingleRowTaperedRollerBearing`, plus a `PressFitHole` builder helper. When unsure: `[n for n in dir(module) if n[0].isupper()]`, and `Cls.sizes("<type>")` / `Cls.types()` for valid sizes.

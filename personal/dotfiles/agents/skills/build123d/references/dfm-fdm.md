# FDM printing

Ask (or assume and state) nozzle, material and print orientation. Defaults that held up: 0.4 mm nozzle, PETG, model in print orientation (+Z up, bed at min Z) so the checks mean something.

## Rules to design in

- Walls >= 3 perimeters (1.2 mm at 0.4). Name it and derive wall thickness from it.
- Overhangs <= 45 deg from vertical. Chamfer the underside of anything that sticks out rather than filleting it.
- Flat ceilings are fine as **bridges** (held at both ends, up to ~20 mm) and need support as **ledges** (held at one end). Port cutouts in walls are usually bridges.
- Holes print undersize - add ~0.2 mm on diameter for clearance, or use the real part as a press fit target and test print.
- Fit clearances: 0.2-0.3 mm per side for sliding fits, ~0.1 mm on diameter for printed bearing press fits.
- Snap fits: cantilever strain `1.5 t y / L^2` (rectangular arm, fixed end). PETG/PLA take ~4% once; keep repeated snaps under ~2.5%. Give the hook a 45 deg lead-in chamfer and a small land. `dfm_fdm.cantilever_strain` does the sum.
- Check port/connector cutouts against the **plug** envelope (overmould, not just the receptacle). Official board drawings give positions; plug sizes are datasheet-typical, so mark them approximate.
- Round holes in vertical walls (panel sockets, glands) want a **teardrop** - 45 deg tangents off the circle, flattened about 1 mm above it so the top bridges instead of drooping. Check the flat is still hidden by the part's flange or nut.

## Electronics enclosures

Notes from a tray + lid for a PD trigger, buck, Wagos, a fan hub and an ESP32 (`models/air_filter.py` in the private designs package), designed before any of the parts had arrived.

- Assume the sizes are wrong until someone's measured them. Put every part size in one named constant, mark each one as a datasheet value or a guess, and choose mounts based on how much a wrong guess would hurt.
- **Zip tie cradles** for boards and modules you haven't measured: two end pads (~3 mm tall) with corner fences, and the tie goes _under_ the part through the gap between the pads. They tolerate a few mm of error and need no mounting holes. Mounts that grip by size (snap pockets for Wagos, posts that hold a PCB by its edges) don't tolerate errors, so those are the ones to caliper before printing a batch.
- Give each part a keep-out (the part plus space for plugs, wires and bending) and size the tray from the keep-outs, not the other way round. A dumb row packer (left to right, with a gap between keep-outs) plus a pairwise overlap assertion was enough - when a measurement changes, the tray resizes itself or raises an error instead of printing a clash.
- Ask which way up it'll be mounted. A box screwed to a vertical panel means gravity no longer holds anything on its posts, so add hold-down pins on the lid (with a ~0.3 mm gap) or ties.
- Down-facing pin headers + Dupont leads need ~24 mm under the PCB (housing ~14 mm plus room to bend).

## How the checks work

`m = to_trimesh(part)` tessellates to a trimesh mesh (needs `rtree` for ray casting).

- `overhangs(m, max_angle_deg=45)`: faces whose normal z is below `-cos(90 - angle)` and that aren't on the bed, grouped into connected regions via face adjacency. Regions with no z spread are reported as `flat ceiling L x W` - look at a section to decide bridge vs ledge, the mesh can't tell what's holding it.
- `thin_walls(m, min_t)`: sample random surface points, cast a ray inward along -normal, distance to the first hit is local thickness. Anything under `min_t` comes back with its location.

Controls that validated them: a 30 deg tilted shelf (flags), a 0.8 mm walled box (flags at 1.2).

Zero interference between lid and base doesn't prove a snap engages. Check the intended overlap of the hook against the wall without its window is > 0 and roughly what you designed (`Expect(..., overlap=...)`) - see [assemblies](assemblies.md).

# Seeing the model

An agent can open PNGs but not SVGs (`open_files` shows SVG as XML) and can't screenshot the OCP viewer. So every view ends as a PNG. `tools/look.py` has the three that earned their keep - here's how each works so you can bend them.

## Which view for what

| Question | View |
| --- | --- |
| Is the overall shape right? Are parts where I think? | `shaded` 2x2 |
| Through or blind? Counterbore depth? What's behind that face? | `hidden_lines` |
| Does this fit? Gap, engagement, bearing stack, port clearance | `section`, zoomed |

Print per-solid bounding boxes before rendering anything when a part looks wrong - `[(tuple(s.bounding_box().min), tuple(s.bounding_box().max)) for s in part.solids()]` localises strays and misplaced parts faster than any picture.

## Shaded (pyvista)

`shape.tessellate(tol, angular_tolerance)` returns `(vertices, triangles)`. pyvista wants a flat face array `[3, i, j, k, 3, ...]`, so `pv.PolyData(verts, [x for t in tris for x in (3, *t)])`. Feature edges (`mesh.extract_feature_edges(30)`) drawn in black on top make the shape readable - without them flat shading turns into blobs.

The camera bits that matter: `enable_parallel_projection()` (orthographic, so you can compare sizes), `focal_point` at the bbox centre, `position = centre + 1000 * direction`, then `reset_camera()` to fit. `off_screen=True` works headless.

Colour per part, not per face - assemblies are unreadable otherwise.

## Hidden lines (build123d projection + resvg)

`shape.project_to_viewport(camera_position, viewport_up, look_at)` returns `(visible_edges, hidden_edges)` as 2D edges in mm, centred on `look_at`.

- The first argument is a camera **position** (the docs say so) and the projection is perspective (they don't). Passing a direction like `(1, -1, 1)` puts the camera inside the part. Use `centre + dir.normalized() * bbox.diagonal * 20` - far enough away that it's effectively orthographic.
- The same view frame is `Plane(origin=look_at, x_dir=up.cross(dir), z_dir=dir)`. `plane.to_local_coords(p)` maps any model point onto the projected edges - that's how you place dimensions on a drawing.
- `ExportSVG(scale=...)` with a `hidden` layer using `LineType.ISO_DASH`, then `nix run nixpkgs#resvg -- --width 1200 in.svg out.png` (~3 s warm). Use colour names, not 0-255 tuples (deprecated).
- Don't reach for `nix run nixpkgs#f3d` to render STLs - it pulls in all of VTK and took minutes before it was killed. resvg (or `nixpkgs#librsvg`'s `rsvg-convert -b white`) is a few MB.

## Sections (exact, matplotlib)

`shape & plane` (same result as the documented `section(shape, plane)` op) returns a Sketch of the exact cut faces - no meshing involved until you draw it. For each face, `face.tessellate(0.01)` gives triangles for the fill and `edge.positions(np.linspace(0, 1, 30))` gives outlines. Map 3D points to 2D with `plane.to_local_coords(p)` and draw a `PolyCollection` per part. Zoom with `xlim`/`ylim` in plane coordinates and turn on a minor grid - you can read 0.2 mm off it.

Pick a plane through the feature: `Plane.XZ.offset(-5)` cuts at y = +5 (XZ's normal is -Y, so offsets go the other way), or `Plane(origin=..., z_dir=...)` for anything else. Through a joint axis is almost always the most useful cut for a mechanism.

Whole-assembly shaded cutaways (`split` + render) look nice but are too coarse to judge fits. `split()` can also return an empty shape when a part is wholly on the discarded side, so skip shapes without faces.

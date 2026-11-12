# Dimensioned drawings

build123d can make a decent A4 drawing with `TechnicalDrawing`, projected views and `ExtensionLine`/`DimensionLine`. The trick is mapping model points onto the page with the same transform as the projected edges.

```python
from build123d import *

class View:
    """A far-camera projection plus the matching Plane, so model points land where the edges do."""
    def __init__(self, part, direction, up, page_xy):
        c = part.bounding_box().center()
        d, u = Vector(direction).normalized(), Vector(up).normalized()
        self.plane = Plane(origin=c, x_dir=u.cross(d), z_dir=d)
        self.offset = Vector(*page_xy, 0)
        vis, hid = part.project_to_viewport(c + d * 5000, viewport_up=u, look_at=c)
        self.visible = [Pos(self.offset) * e for e in vis]
        self.hidden = [Pos(self.offset) * e for e in hid]

    def pt(self, model_xyz):
        p = self.plane.to_local_coords(Vector(model_xyz))
        return tuple(Vector(p.X, p.Y, 0) + self.offset)

# Third angle: top above front, right to the right of front
front = View(part, (0, -1, 0), (0, 0, 1), (-75, -5))
top = View(part, (0, 0, 1), (0, 1, 0), (-75, 62))
right = View(part, (1, 0, 0), (0, 0, 1), (5, -5))

draft = Draft(font_size=3.0, decimal_precision=1, display_units=False)
exp = ExportSVG(scale=1.0, line_weight=0.2)
exp.add_layer("visible", line_weight=0.35)
exp.add_layer("hidden", line_color="gray", line_type=LineType.ISO_DASH)
exp.add_layer("dims", line_color="blue", fill_color="blue")  # without fill_color text renders hollow
exp.add_layer("frame", fill_color="black")
...
exp.add_shape(ExtensionLine(border=[front.pt(a), front.pt(b)], offset=8, draft=draft), layer="dims")
exp.add_shape(TechnicalDrawing(title="...", sub_title="6061-T6", drawing_number="X-001", page_size=PageSize.A4, nominal_text_size=6), layer="frame")
exp.write("out/drawing.svg")   # then resvg to PNG and look at it
```

- Page origin is the A4 centre, units mm at `scale=1`. The title block sits bottom-right (roughly x > 0, y < -47) - keep views out of it.
- `ExtensionLine(offset=+n)` puts the dimension on the right of the a->b direction; flip the sign or swap points to move it. `offset=0` raises - use `DimensionLine(path=[a, b], label=...)` for in-line dims like diameters.
- Dimension from named constants (`right.pt((PLATE_T, -h, MOTOR_Z + h))`), not from measuring the projection, so the drawing stays true when the model changes.
- Always render to PNG and look - overlapping dims and views drifting into the title block are only obvious visually.

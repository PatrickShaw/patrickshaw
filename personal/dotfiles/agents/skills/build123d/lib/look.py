"""See a build123d model as PNGs an agent can open. See references/viewing.md for why each works.

Needs: pyvista (shaded), matplotlib (section), `nix run nixpkgs#resvg` (hidden_lines).
"""

import subprocess
from pathlib import Path

from build123d import Compound, ExportSVG, LineType, Plane, Shape, Vector

# camera direction (target -> camera), up vector
VIEWS = {
    "iso": ((1, -1, 1), (0, 0, 1)),
    "front -Y": ((0, -1, 0), (0, 0, 1)),
    "top +Z": ((0, 0, 1), (0, 1, 0)),
    "right +X": ((1, 0, 0), (0, 0, 1)),
}
FAR = 20  # camera distance in bbox diagonals - far enough that perspective is negligible
FEATURE_ANGLE = 30  # degrees between faces before pyvista draws an edge


def solids(shape: Shape) -> Compound:
    """Flatten nested compounds (bd_warehouse parts, assemblies) to their placed solids."""
    return Compound(shape.solids())


def png(svg: Path, width: int = 1200) -> Path:
    out = Path(svg).with_suffix(".png")
    subprocess.run(["nix", "run", "nixpkgs#resvg", "--", "--width", str(width), str(svg), str(out)], check=True)
    return out


def _to_pv(shape: Shape, tol: float):
    import pyvista as pv

    verts, tris = shape.tessellate(tol, angular_tolerance=0.2)
    return pv.PolyData([tuple(v) for v in verts], [x for t in tris for x in (3, *t)])


def shaded(items: list[tuple[Shape, str]], out: str | Path, views=VIEWS, size=(1400, 1050), tol=0.05) -> Path:
    """[(shape, colour), ...] -> one PNG with a 2x2 grid of orthographic views."""
    import pyvista as pv

    # split() can leave an empty shape when a part is wholly on the cut side
    meshes = [(_to_pv(solids(s), tol), c) for s, c in items if s.faces()]
    pl = pv.Plotter(off_screen=True, shape=(2, 2), window_size=size)
    bounds = pv.merge([m for m, _ in meshes]).bounds
    centre = tuple((bounds[i] + bounds[i + 1]) / 2 for i in (0, 2, 4))
    for i, (name, (direction, up)) in enumerate(views.items()):
        pl.subplot(i // 2, i % 2)
        for mesh, colour in meshes:
            pl.add_mesh(mesh, color=colour)
            pl.add_mesh(mesh.extract_feature_edges(FEATURE_ANGLE), color="black", line_width=1)
        pl.add_text(name, font_size=10)
        pl.add_axes()
        pl.enable_parallel_projection()
        pl.camera.focal_point = centre
        pl.camera.position = tuple(c + 1000 * d for c, d in zip(centre, direction))
        pl.camera.up = up
        pl.reset_camera()
    pl.screenshot(str(out))
    pl.close()
    return Path(out)


def hidden_lines(shape: Shape, out_svg: str | Path, direction=(1, -1, 1), up=(0, 0, 1), width=1000) -> Path:
    """Visible edges black, hidden edges blue dashed. Best for internal features."""
    bb = shape.bounding_box()
    centre = bb.center()
    # project_to_viewport takes a camera POSITION and is perspective, so park it far away
    camera = centre + Vector(direction).normalized() * (bb.diagonal * FAR)
    visible, hidden = shape.project_to_viewport(camera, viewport_up=up, look_at=centre)
    size = max(Compound(children=visible + hidden).bounding_box().size)
    exp = ExportSVG(scale=100 / size, line_weight=0.25)
    exp.add_layer("visible")
    exp.add_layer("hidden", line_color="royalblue", line_type=LineType.ISO_DASH)
    exp.add_shape(visible, layer="visible")
    exp.add_shape(hidden, layer="hidden")
    exp.write(str(out_svg))
    return png(Path(out_svg), width)


def section(items: list[tuple[Shape, str]], plane: Plane, out: str | Path, xlim=None, ylim=None, title="") -> Path:
    """Exact 2D cut of several shapes on `plane`, one fill colour per shape, mm grid.

    xlim/ylim are plane-local (plane.x_dir, plane.y_dir) ranges to zoom on a detail.
    """
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import numpy as np
    from matplotlib.collections import PolyCollection

    def local(points):
        return np.array([tuple(plane.to_local_coords(p))[:2] for p in points])

    fig, ax = plt.subplots(figsize=(8, 8))
    for shape, colour in items:
        for face in (solids(shape) & plane).faces():
            verts, tris = face.tessellate(0.01)
            ax.add_collection(PolyCollection(local(verts)[np.array(tris)], facecolor=colour, edgecolor="none", alpha=0.8))
            for edge in face.edges():
                pts = local(edge.positions(np.linspace(0, 1, 30)))
                ax.plot(pts[:, 0], pts[:, 1], color="black", linewidth=0.6)
    ax.set_aspect("equal")
    ax.autoscale_view()
    if xlim:
        ax.set_xlim(*xlim)
    if ylim:
        ax.set_ylim(*ylim)
    ax.minorticks_on()
    ax.grid(True, linewidth=0.3)
    ax.grid(True, which="minor", linewidth=0.1)
    ax.set_xlabel(f"plane x_dir {tuple(round(c, 2) for c in plane.x_dir)} (mm)")
    ax.set_ylabel(f"plane y_dir {tuple(round(c, 2) for c in plane.y_dir)} (mm)")
    ax.set_title(title)
    fig.savefig(out, dpi=110, bbox_inches="tight")
    plt.close(fig)
    return Path(out)

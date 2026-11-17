"""3-axis CNC accessibility audit. See references/dfm-cnc.md for how to read findings.

A setup is the direction the tool comes FROM (TOP = (0, 0, 1) means the
spindle points down -Z at the part). Heuristic, not CAM - it finds the
questions to ask, it doesn't prove a part is machinable.
"""

from dataclasses import dataclass

from build123d import GeomType, Shape, Vector

PROBE = 0.05  # mm off a face, to test what's just outside it
RAY_STEP = 0.5  # mm between is_inside samples along a tool approach ray
PARALLEL = 0.999  # |cos| above this counts as aligned


@dataclass(frozen=True)
class Finding:
    kind: str
    where: tuple[float, float, float]
    detail: str


def _ray_clear(part: Shape, start: Vector, direction: Vector, length: float) -> bool:
    steps = int(length / RAY_STEP)
    return not any(part.is_inside(start + direction * (i * RAY_STEP)) for i in range(1, steps))


def _on_stock_face(part: Shape, face, normal: Vector) -> bool:
    """Faces on the bbox (e.g. the back of the part) are left by the stock, not cut."""
    bb, fb = part.bounding_box(), face.bounding_box()
    for axis, c in ((Vector(1, 0, 0), "X"), (Vector(0, 1, 0), "Y"), (Vector(0, 0, 1), "Z")):
        if normal.dot(axis) < -PARALLEL and abs(getattr(fb.min, c) - getattr(bb.min, c)) < 1e-6:
            return True
        if normal.dot(axis) > PARALLEL and abs(getattr(fb.max, c) - getattr(bb.max, c)) < 1e-6:
            return True
    return False


def _aligned(v: Vector, d: Vector) -> bool:
    return abs(v.dot(d)) > PARALLEL


def _perpendicular(v: Vector, d: Vector) -> bool:
    return abs(v.dot(d)) < 1 - PARALLEL


def audit(part: Shape, setups: dict[str, tuple], tool_r: float) -> list[Finding]:
    dirs = {k: Vector(v).normalized() for k, v in setups.items()}
    length = part.bounding_box().diagonal
    found: list[Finding] = []

    for face in part.faces():
        p = face.center()
        n = face.normal_at(p)
        reach = [k for k, d in dirs.items() if n.dot(d) > -1e-6 and _ray_clear(part, p + n * PROBE, d, length)]
        if not reach:
            kind = "stock-face" if _on_stock_face(part, face, n) else "undercut"
            found.append(Finding(kind, tuple(p), f"{face.geom_type.name} face unreachable from {list(dirs)}"))
            continue
        if face.geom_type == GeomType.PLANE and not any(_aligned(n, dirs[k]) or _perpendicular(n, dirs[k]) for k in reach):
            found.append(Finding("3d-toolpath", tuple(p), f"sloped plane, reachable from {reach}"))
        if face.geom_type == GeomType.CYLINDER and face.radius < tool_r:
            # Full circles get drilled, so only partial arcs (pocket corners, slot ends) need the end mill
            is_hole = any(e.geom_type == GeomType.CIRCLE and e.is_closed for e in face.edges())
            axis = face.axis_of_rotation.direction
            if not is_hole and any(_aligned(axis, dirs[k]) for k in reach):
                found.append(Finding("small-radius", tuple(p), f"r={face.radius:.2f} < tool r={tool_r}"))

    for edge in part.edges():
        if edge.geom_type != GeomType.LINE:
            continue
        faces = [f for f in part.faces() if any(edge.is_same(fe) for fe in f.edges())]
        if len(faces) != 2:
            continue
        p = edge.center()
        n1, n2 = (f.normal_at(p) for f in faces)
        if n1.dot(n2) > PARALLEL:
            continue  # tangent, not a corner
        if not part.is_inside(p + n1 * PROBE - n2 * PROBE):
            continue  # convex
        # Floor-to-wall corners are fine: the end mill's flat bottom leaves them sharp
        if any(_aligned(a, d) and _perpendicular(b, d) for d in dirs.values() for a, b in ((n1, n2), (n2, n1))):
            continue
        t = edge.tangent_at(0.5)
        if any(_aligned(t, d) for d in dirs.values()):
            found.append(Finding("sharp-inside-corner", tuple(p), f"edge along {tuple(round(c) for c in t)} needs r>={tool_r}"))
        else:
            found.append(Finding("3d-blend", tuple(p), "concave sloped junction - a 3D toolpath leaves the ball radius here"))
    return found

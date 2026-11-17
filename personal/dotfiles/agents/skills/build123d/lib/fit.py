"""Fit, clearance and assembly checks. See references/assemblies.md for when to use each.

Everything flattens to solids first: booleans against a bd_warehouse Compound
directly can report phantom overlaps (seen: 6 mm^3 where no ball existed).
"""

import itertools
from collections.abc import Callable, Iterable
from dataclasses import dataclass

from build123d import Compound, Pos, Shape, Vector

OVERLAP_TOL = 1e-3  # mm^3 - touching faces can leave tiny slivers in the boolean result
TOUCH_TOL = 1e-6  # mm
GAP_TOL = 0.05  # mm - designed gaps must come out within this


def solids(shape: Shape) -> Compound:
    return Compound(shape.solids())


def overlap(a: Shape, b: Shape) -> float:
    return (solids(a) & solids(b)).volume


def clearance(a: Shape, b: Shape) -> float:
    """Minimum distance, 0 if touching or overlapping. ~5x faster than a boolean."""
    return solids(a).distance_to(solids(b))


def _boxes_overlap(a: Shape, b: Shape) -> bool:
    ba, bb = a.bounding_box(), b.bounding_box()
    return all(a0 <= b1 and b0 <= a1 for a0, a1, b0, b1 in zip(tuple(ba.min), tuple(ba.max), tuple(bb.min), tuple(bb.max)))


def clashes(named: dict[str, Shape], ignore: Callable[[str, str], bool] = lambda a, b: False) -> list[tuple[str, str, float]]:
    """Every pair with overlap volume above OVERLAP_TOL."""
    found = []
    for (n1, s1), (n2, s2) in itertools.combinations(named.items(), 2):
        # Most pairs in an assembly are nowhere near each other and the bbox test is ~free
        if ignore(n1, n2) or not _boxes_overlap(s1, s2):
            continue
        v = overlap(s1, s2)
        if v > OVERLAP_TOL:
            found.append((n1, n2, round(v, 3)))
    return found


def clashes_between(*groups: dict[str, Shape]) -> list[tuple[str, str, float]]:
    """Clashes only across groups of parts that move relative to each other.

    For a motion sweep, group parts by which joint they ride on (ground / pan / tilt).
    Parts in the same group are rigidly connected so their clashes can't change with
    the pose - check those once at home with clashes(). Leave the bearings that ARE
    the joints out of the sweep, they're covered by the fit table.
    """
    found = []
    for ga, gb in itertools.combinations(groups, 2):
        for (n1, s1), (n2, s2) in itertools.product(ga.items(), gb.items()):
            if _boxes_overlap(s1, s2):
                v = overlap(s1, s2)
                if v > OVERLAP_TOL:
                    found.append((n1, n2, round(v, 3)))
    return found


@dataclass(frozen=True)
class Expect:
    """An intended relationship between two shapes. Set exactly one of:

    - nothing: a seat - must touch without overlapping
    - gap: a designed gap (running fit, side clearance) - must be within GAP_TOL of it.
      A 0.5 mm running fit that measures 11 mm isn't a fit, the part's floating.
    - min_gap: stay-clear requirement (spool vs wall) - anything at least this big
    - overlap: intended interference (snap hook engagement) - at least this many mm^3.
      Model press fits at nominal size as seats, not as overlap
    """

    name: str
    a: Shape
    b: Shape
    gap: float | None = None
    min_gap: float | None = None
    overlap: float | None = None


def check(expectations: Iterable[Expect]) -> list[tuple[bool, str]]:
    results = []
    for e in expectations:
        d, v = clearance(e.a, e.b), overlap(e.a, e.b)
        if e.overlap is not None:
            ok, want = v >= e.overlap, f"overlap >= {e.overlap}"
        elif e.min_gap is not None:
            ok, want = d >= e.min_gap, f"clearance >= {e.min_gap}"
        elif e.gap is not None:
            ok, want = abs(d - e.gap) <= GAP_TOL and v < OVERLAP_TOL, f"clearance {e.gap} +/- {GAP_TOL}"
        else:
            ok, want = d < TOUCH_TOL and v < OVERLAP_TOL, "seated (touching, no overlap)"
        results.append((ok, f"{'ok ' if ok else 'BAD'} {e.name}: want {want}, got clearance {d:.3f} overlap {v:.3f}"))
    return results


def floating(named: dict[str, Shape], ground: str) -> tuple[dict[str, list[str]], list[str]]:
    """Contact graph (who touches whom) and the parts with no chain of contacts back to `ground`.

    A part that touches nothing isn't held by anything - it's a modelling bug even
    when every clash check passes. Treat a bd_warehouse bearing as one node.
    """
    touching = {n: [] for n in named}
    for (n1, s1), (n2, s2) in itertools.combinations(named.items(), 2):
        if clearance(s1, s2) < TOUCH_TOL:
            touching[n1].append(n2)
            touching[n2].append(n1)
    reached, todo = {ground}, [ground]
    while todo:
        for n in touching[todo.pop()]:
            if n not in reached:
                reached.add(n)
                todo.append(n)
    return touching, [n for n in named if n not in reached]


def retained(part: Shape, others: Shape, axis, max_float: float, step: float = 0.1) -> dict[str, float | None]:
    """How far `part` can slide each way along `axis` before hitting `others` (None = it falls off).
    Axial retention means both directions are blocked within max_float."""
    d = Vector(axis).normalized()
    part, others = solids(part), solids(others)
    free = {}
    for sign, label in ((1, "+"), (-1, "-")):
        free[label] = next(
            (round(i * step, 3) for i in range(1, int(max_float / step) + 2) if (Pos(d * (sign * i * step)) * part & others).volume > OVERLAP_TOL),
            None,
        )
    return free


def insertion_path(part: Shape, fixed: Shape, direction, travel: float, step: float) -> list[tuple[float, float]]:
    """Slide `part` out along `direction` (the reverse of how it goes in) and
    return [(distance, overlap)] wherever it collides with `fixed`.

    Pick step smaller than the smallest gap on the path or it can jump a lip.
    """
    d = Vector(direction).normalized()
    part, fixed = solids(part), solids(fixed)
    hits = []
    n = int(travel / step) + 1
    for i in range(n):
        v = (Pos(d * (i * step)) * part & fixed).volume
        if v > OVERLAP_TOL:
            hits.append((round(i * step, 3), round(v, 3)))
    return hits

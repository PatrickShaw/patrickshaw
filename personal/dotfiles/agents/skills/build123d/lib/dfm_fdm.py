"""FDM printability checks on a mesh. See references/dfm-fdm.md. Needs trimesh + rtree."""

import math

import numpy as np
import trimesh
from build123d import Shape

BED_EPS = 0.01  # mm - faces this close to the bed are on it, not overhangs
FLAT_EPS = 0.01  # mm of z spread for a region to count as a flat ceiling


def to_trimesh(shape: Shape, tol: float = 0.05) -> trimesh.Trimesh:
    verts, tris = shape.tessellate(tol, angular_tolerance=0.2)
    return trimesh.Trimesh([tuple(v) for v in verts], tris, process=True)


def overhangs(mesh: trimesh.Trimesh, max_angle_deg: float = 45, min_area: float = 1.0):
    """Connected downward-facing regions steeper than max_angle from vertical, in print orientation (+Z up).

    Flat ceilings are reported separately with their span, because whether they're
    a bridge (held both ends, fine up to ~20 mm) or a ledge (needs support) depends
    on what's around them - eyeball those in a section.
    """
    bed_z = mesh.bounds[0][2]
    limit = -math.cos(math.radians(90 - max_angle_deg))
    bad = np.where((mesh.face_normals[:, 2] < limit) & (mesh.triangles_center[:, 2] > bed_z + BED_EPS))[0]
    if not len(bad):
        return []
    found = []
    for group in trimesh.graph.connected_components(mesh.face_adjacency, nodes=bad, min_len=1):
        area = float(mesh.area_faces[group].sum())
        if area < min_area:
            continue
        pts = mesh.triangles[group].reshape(-1, 3)
        lo, hi = pts.min(0), pts.max(0)
        if hi[2] - lo[2] < FLAT_EPS:
            long_side, short_side = sorted((hi[0] - lo[0], hi[1] - lo[1]), reverse=True)
            kind = f"flat ceiling {long_side:.1f} x {short_side:.1f}"
        else:
            kind = "overhang"
        found.append((round(area, 1), kind, np.round([lo, hi], 2).tolist()))
    return sorted(found, reverse=True)


def thin_walls(mesh: trimesh.Trimesh, min_t: float, samples: int = 4000, seed: int = 0):
    """Ray-cast inward from random surface points - the distance to the far side is the local thickness."""
    pts, idx = trimesh.sample.sample_surface(mesh, samples, seed=seed)
    normals = mesh.face_normals[idx]
    origins = pts - normals * 1e-3
    hits, ray_idx, _ = mesh.ray.intersects_location(origins, -normals, multiple_hits=False)
    t = np.full(len(pts), np.inf)
    t[ray_idx] = np.linalg.norm(hits - origins[ray_idx], axis=1)
    return [(round(float(t[i]), 2), np.round(pts[i], 1).tolist()) for i in np.where(t < min_t)[0]]


def cantilever_strain(thickness: float, deflection: float, length: float) -> float:
    """Peak strain of a rectangular snap arm fixed at one end: 1.5 t y / L^2.
    PETG/PLA take ~4% once, keep repeated snaps under ~2.5%."""
    return 1.5 * thickness * deflection / length**2

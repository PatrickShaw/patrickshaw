# 3-axis CNC

Ask (or assume and state) the smallest end mill and the setups before modelling. Defaults that held up: 3 mm for detail, 6 mm for pocketing, aluminium 6061.

## Rules to design in

- **Inside vertical corners get a radius >= tool radius**, ideally a bit more (tool r + 0.5) so the tool isn't fully engaged. Name it (`INSIDE_CORNER_R`) and derive from the tool.
- Floor-to-wall corners can be sharp - the flat end of the mill leaves them.
- Every face must be reachable from some setup direction with nothing in the way. Undercuts (T-slots, internal grooves) need special tools - avoid unless asked.
- Sloped faces mean a 3D toolpath with a ball mill and the junction where a slope meets a wall gets the ball radius, not sharp. Either blend it on purpose (`GUSSET_BLEND_R`) or avoid slopes.
- Slots narrower than the pocketing tool can't be pocketed - widen them or drop to the small tool.
- Holes are drilled, so their radius doesn't matter. Counterbores sit next to fillets more often than you'd think - derive positions so the counterbore clears the fillet (a rendering caught this, the numbers didn't).
- Write the setups in the part's docstring (`TOP +Z, FRONT +X, SIDE +Y`) - the machinist needs them and so does the audit.

## How `dfm_cnc.audit` decides

`audit(part, setups={"TOP": (0, 0, 1), ...}, tool_r=1.5)` - a setup is the direction the tool comes **from**.

- **Reachability**: for each face, step a point from just off the face centre along each setup direction, testing `part.is_inside` every 0.5 mm. If no setup gets out clean, it's an `undercut` - or a `stock-face` if the face sits on the bounding box (the back of the part, left by the stock).
- **Concave corners**: for each straight edge with two faces, test a point just inside the corner bisector. If it's inside the material the edge is concave. Concave edges parallel to a setup axis are `sharp-inside-corner` (need a radius); ones that aren't axis-aligned are `3d-blend`. Floor-to-wall pairs are skipped.
- **Small radii**: partial cylindrical faces (not full holes) with radius < tool_r parallel to a reachable setup are `small-radius`.
- **Sloped planes** reachable from a setup but not parallel/perpendicular to it are `3d-toolpath`.

It's a heuristic to find questions, not CAM. Run it at the detail tool radius and again at the pocketing radius - expect slot ends to flag at the bigger one. Controls that validated it: a sharp-cornered pocket (flags the corners), a T-slot (flags the undercut).

It's slow-ish on big parts (seconds per hundred faces) because of the `is_inside` stepping.

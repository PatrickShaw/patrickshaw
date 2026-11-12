---
name: build123d
description: How to design, see and verify parts and assemblies in build123d (Python CAD on OpenCascade) as an agent - project setup, rendering to PNGs you can actually look at, fit/clearance/motion checks, joints, CNC and FDM manufacturability, drawings and STEP/STL export. Load before writing, reviewing or debugging build123d or bd_warehouse code.
---

# build123d

Field notes from building a CNC bracket, a snap-fit FDM case and a pan-tilt assembly in build123d 0.13. Most of the time lost was in two places: not being able to *see* the model, and checks that passed while the design was wrong. This skill is mostly about those two.

## Read the official docs first

build123d publishes LLM-friendly docs: an index at <https://build123d.readthedocs.io/en/latest/llms.txt> and the full narrative docs (concepts, tutorials, joints, tips/FAQ, import/export - not the autodoc API reference) as one file. Fetch the one matching the installed version and grep it before guessing or digging in source:

```sh
v=$(uv run python -c "import build123d; print(build123d.__version__)")
mkdir -p out && curl -sL -o out/build123d-llms.txt "https://build123d.readthedocs.io/en/v$v/llms-full.txt"
grep -n -i "<topic>" out/build123d-llms.txt
```

`latest` documents features newer than a pinned release, so use the versioned one. Sections worth reading once: Key Concepts (builder and algebra), Tips/FAQ, Joints, Assemblies, Performance considerations in algebra mode. For anything the docs don't cover (joint argument semantics live in autodoc), read the installed source - it's small and readable - then check GitHub issues.

The docs' own design advice, which held up: **2D before 3D** (sketch a profile, then extrude/revolve) rather than stacking boxes and cylinders, **fillets and chamfers last**, and derive dimensions from a few key parameters.

## Setup

```sh
uv init --bare && uv add build123d bd_warehouse pyvista trimesh rtree matplotlib pytest
mkdir -p parts tools tests scripts out && touch parts/__init__.py tools/__init__.py
cp ~/.agents/skills/build123d/lib/{look,fit,dfm_cnc,dfm_fdm}.py tools/
cp ~/.agents/skills/build123d/lib/test_parts.py tests/
printf '\n[tool.pytest.ini_options]\npythonpath = ["."]\n' >> pyproject.toml
```

- `parts/<thing>.py` holds pure functions that return shapes, one frame per part. Annotate returns (`-> Solid`) - `tests/test_parts.py` auto-discovers zero-arg builders by annotation and checks valid / one solid / STEP round trip.
- Run scripts as modules from the project root (`uv run python -m scripts.export`) so `parts` imports without `PYTHONPATH`.
- `look.hidden_lines` and drawings convert SVG to PNG with `nix run nixpkgs#resvg` (Nix is assumed on Patrick's machines).
- First pyvista render takes ~45 s (VTK init), then ~2 s. Don't kill it.
- For the human: `uv add ocp_vscode ocp_viewer`, run `uv run python -m ocp_viewer` (the standalone viewer moved out of `ocp_vscode`) and call `ocp_vscode.show(...)`. Don't try to screenshot it with headless Chrome - DevTools is blocked on the work Mac and you'll just eat a 3 minute timeout.

## The loop

0. **Turn the brief into a requirements table before modelling** - one row per requirement: the requirement, the geometry that meets it, the check that proves it. Bearings, joints, retention, "spins freely", "assemblable", print orientation all get rows. You're done when every row has a passing check, not when the scripts run. A test agent with this skill skipped the bearings and joints entirely, then reported success.
1. **Name every dimension and derive it from a constraint** (clearance, fastener size, tool radius, printer nozzle). Hand-picked numbers caused most real bugs: a counterbore notching a fillet, a cradle 3 mm narrower than its "SIDE_GAP" said. A constant that's never used is a bug.
2. **Write a frame plan before code**: the assembly axes, each part's origin, and every joint as `parent.joint at (x, y, z) dir -> child.joint`. Most placement bugs are a joint in the wrong place (an axle axis on the wall face instead of the boss tip), and they're cheap to catch on paper.
3. **Build each part in its own frame** and place them with joints in **one** `pose(...)` function that every script imports - never retype placements in a check script, they drift. See the worked example in [assemblies](references/assemblies.md).
4. **Look at it** with `tools/look.py` ([viewing](references/viewing.md)). Shaded 2x2 for overall shape, hidden lines for internal features, a 2D section for anything under ~1 mm or any mechanism. **Before opening the PNG, write down what you expect to see** (which part where, touching what, gaps of what size), then compare line by line. "Looks reasonable" is how a spool sitting on the wall plate got signed off. Sections found four design bugs that every clash check passed.
5. **Check the numbers** with `tools/fit.py`: a table of intended seats, designed gaps and overlaps (not just "no clashes"), `floating()` to prove every part is held by something, `retained()` for axial retention, plus range of motion and insertion paths for assemblies. **When a check fails, fix the design** - only change the expectation if the original intent was wrong, and say why in a comment.
6. **Check manufacturability**: [CNC](references/dfm-cnc.md) / [FDM](references/dfm-fdm.md).
7. **Give every new check a positive control** that must fail - a 500 mm³ overlap, a sharp pocket, a part with its pin put back. Twice in three builds a check "passed" because it couldn't fail.
8. **Report against the requirements table**, unmet rows first. Two test agents with this skill reported "all requirements met" on designs where the spool and hub weren't touching anything - `floating()` is there so that can't happen quietly.

## Gotchas that cost the most

Most of these are documented - the docs link says where. The point of listing them is that they're easy to skim past.

- **Shapes made while a `with BuildPart()` is active add themselves to it immediately** ([docs](https://build123d.readthedocs.io/en/latest/key_concepts_builder.html), "Why modifying objects directly doesn't work in Builder mode"). So `Pos(...) * Box(...)` or `Box(...).moved(...)` inside a builder, or in a helper called from one, adds an unmoved `Box` at the origin and moves a throwaway copy. `Polygon` raises; `Box` silently joins. If the stray lands inside the body it fuses and nothing can detect it. Rule: helpers that return shapes are pure algebra and builders never call them; inside builders, place with `Locations`. With INFO logging on (`logging.getLogger("build123d").setLevel(logging.INFO)`), every shape that joins logs its own `Completed integrating 1 object(s)` line - an extra one means a stray.
- **Flatten nested compounds before measuring**: `Compound(x.solids())`. A nested Compound's `.volume` only counts its top level ([docs](https://build123d.readthedocs.io/en/latest/assemblies.html), "Iterating Over Compounds"), and booleans against bd_warehouse compounds directly reported a 6 mm³ overlap where no ball existed. `fit.py` and `look.py` flatten for you.
- `(a & b).volume` for interference - `a.intersect(b)` returns a ShapeList or None. `a.distance_to(b)` gives clearance and is ~5x faster.
- **`RevoluteJoint(axis=<not Z>, angle_reference=...)` is broken in 0.13** (undocumented): the axis rotation gets applied twice and the child points the wrong way. Omit `angle_reference` - details and the workaround in [assemblies](references/assemblies.md). The default `angular_range` is `(0, 360)`, so negative angles raise unless you set one.
- `connect_to` moves the *other* part in place, so build fresh parts per pose. It also enforces `angular_range`.
- `is_valid` is a property, and it can say True for self-intersecting shapes (docs: Tips, "Self Intersection"). `Hole`/`CounterBoreHole` take radius. `Plane.XZ` normal is **-Y**. More in [api-gotchas](references/api-gotchas.md).
- Clash checks can't tell you a design is assemblable or mechanically sensible. Check insertion paths and look at sections.

## References

- [references/viewing.md](references/viewing.md) - how the three render types work and when to use each
- [references/assemblies.md](references/assemblies.md) - joints, bd_warehouse parts, pose sweeps, fit tables, insertion paths, bearing/fastener rules
- [references/dfm-cnc.md](references/dfm-cnc.md) - 3-axis rules and how `dfm_cnc.audit` decides
- [references/dfm-fdm.md](references/dfm-fdm.md) - print rules, overhang/thin wall checks, snap fits
- [references/drawings.md](references/drawings.md) - dimensioned 2D drawings with `TechnicalDrawing`
- [references/api-gotchas.md](references/api-gotchas.md) - smaller 0.13 API surprises, edge selection / fillet / hole patterns, bd_warehouse class names

`lib/` holds the helper modules. They're meant to be copied into a project and read - each is short and says why it works the way it does.

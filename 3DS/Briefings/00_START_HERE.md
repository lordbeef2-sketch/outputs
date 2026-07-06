# 3DS Knowledge Pack

Snapshot date: 2026-07-06

Purpose:
- Give an AI a clean offline starter pack for the Dassault/No Magic ecosystem around Cameo, Teamwork Cloud, SysML, EICD-to-pinout workflows, and the supporting languages most likely to show up in automation and plugin work.
- This expanded drop is also meant to teach and operationalize, not just inform.

How to read this pack:
1. Read `01_VERSION_SNAPSHOT.md` first.
2. Read `10_PRODUCTION_DEPLOYMENT_PLAYBOOK.md` if the task is real-world delivery, not just learning.
3. Read `11_LEARNING_PATH_AND_CURRICULUM.md` if onboarding a human or AI.
4. Read the topic file you need.
5. Use `..\References\SOURCE_INDEX.md` for authoritative links and `..\References\VERSION_MATRIX.csv` for quick parsing.
6. Use `19_MASTER_INDEX.md` if you want the shortest path by role or objective.

Two-folder layout:
- `Briefings`
  - Distilled AI-readable notes, workflows, and mental models.
- `References`
  - Source index, machine-readable maps, and raw version/source pointers.

Truth rail:
- This is a best-effort synthesis, not a full mirrored vendor documentation set.
- "Latest" is as verified on 2026-07-06 from official/public primary sources.
- For 3DS/No Magic products, "latest" can mean base release, refresh release, or hot fix. This pack tracks the latest public release line I could verify, and calls out hot-fix caveats where visible.

High-value mental model:
- Cameo Systems Modeler is the client/modeling environment built on the MagicDraw platform.
- Teamwork Cloud / Magic Collaboration Studio is the repository/collaboration/server side.
- SysML v1 and SysML v2 are not interchangeable; treat them as two related but different modeling stacks.
- If the goal is to inspect model contents, prefer official APIs, reports, exports, and repository services before reverse-parsing internal file structures.

Suggested AI use:
- For version compatibility: read `01_VERSION_SNAPSHOT.md`.
- For Cameo/TWC operations and upgrade thinking: read `02_*.md` and `03_*.md`.
- For language/standards reasoning: read `04_*.md`.
- For EICD digestion and pinout generation: read `05_*.md`.
- For scripts/plugins/data extraction: read `06_*.md`.
- For coding assistance: read `07_*.md`, `08_*.md`, and `09_*.md`.
- For production delivery: read `10_*.md`, `16_*.md`, and `18_*.md`.
- For learning/teaching: read `11_*.md`.
- For fast navigation: read `19_*.md`.
- For hands-on practice: read `20_*.md` and `21_*.md`.
- For common task recipes: read `22_*.md`.
- For course-style teaching: read `23_*.md`.
- For real constrained execution: read `24_*.md`.
- For example pipelines: read `25_*.md` and the sample files in `..\References`.
- For ready-made starter artifacts: read `26_*.md`.
- For QA discipline: read `27_*.md`.
- For report/document strategy: read `28_*.md`.
- For offline packaging: read `29_*.md`.
- For the recommended finishing orientation: read `30_*.md`.
- For plugin-safe operating rails and boundaries: read `31_*.md` and `32_*.md`.
- For plugin work: read `12_*.md` plus the plugin examples in `..\References`.
- For TWC integration work: read `13_*.md`.
- For SysML migration: read `14_*.md`.
- For authoritative pinout transformation design: read `15_*.md`.

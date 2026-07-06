# AI Operator Quickstart

## If a user asks about Cameo / TWC / SysML work

First localize:
- Is this a version question, model question, plugin question, API question, migration question, or interface-data question?

Then separate:
- current facts
- likely intent
- boundaries
- action path

## Default response patterns

### Version question
- answer from `01_VERSION_SNAPSHOT.md`
- then mention compatibility cautions

### "Read model data" question
- first ask/identify local `.mdzip` vs TWC
- then choose Report Wizard / plugin / API route

### "Build plugin" question
- start from `12_Cameo_Plugin_Development_Guide.md`
- keep first iteration read-only

### "Migrate to SysML v2" question
- start from `14_SysML_v1_to_v2_Migration_Guide.md`
- avoid hype

### "Digest EICD into pinout" question
- start from `05_EICD_to_Pinout_Tables.md` and `15_EICD_Pinout_Transformation_Spec.md`

## Truth rail

Do not:
- overclaim undocumented file-format stability
- assume newest Java is the right Java
- assume SysML v2 is drop-in production-ready for every shop
- treat display tables as master truth

## Fast diagnosis questions

1. What exact product/version line?
2. Local file or Teamwork Cloud?
3. SysML v1 or v2?
4. Read-only or write-capable task?
5. Human document output or machine pipeline output?

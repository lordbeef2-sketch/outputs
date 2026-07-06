# Compatibility Notes

## Java support snapshots from official No Magic docs

### 2022x
- Modeling tools:
  - OpenJDK `11.0.14.1+1`
- Teamwork Cloud:
  - OpenJDK `11.0.14.1+1`
- Cameo Collaborator / Web Application Platform / Resources / TWCloud Admin Console NG:
  - Java `17`

### 2024x Refresh3
- Modeling tools:
  - Eclipse Temurin / HotSpot `17.0.14`
- Modeling tools HotFix 1:
  - Java `17.0.17+10`
- Teamwork Cloud / Magic Collaboration Studio:
  - Eclipse Temurin / HotSpot `17.0.14`
- Cameo Collaborator / WAP / Resources / TWCloud Admin Console NG:
  - Eclipse Temurin / HotSpot `21.0.6`

### 2026x Refresh1
- Modeling tools:
  - Eclipse Temurin / HotSpot `21.0.10+7`
- Teamwork Cloud / Magic Collaboration Studio:
  - Eclipse Temurin / HotSpot `21.0.10+7`
- Cameo Collaborator / WAP / Resources / TWCloud Admin Console NG:
  - Eclipse Temurin / HotSpot `21.0.10+7`
- Cassandra note:
  - Cassandra `5.0.x` requires JDK `17`

## Practical implications

- Never assume one Java runtime covers every product component identically across lines.
- Collaboration/admin/web components may have different runtime notes than the modeling client.
- On Linux, vendor pages note that Java is not bundled in installation files.
- OpenJ9 is explicitly discouraged; HotSpot is recommended.

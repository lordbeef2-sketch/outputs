#!/usr/bin/env python3
"""
Sample EICD normalizer

Purpose:
- Read a raw CSV export from an ICD/EICD-like table
- Expand simple packed differential-pair rows
- Emit a normalized CSV that is closer to the canonical pinout schema

This is a teaching sample, not a production parser.
"""

from __future__ import annotations

import csv
from pathlib import Path


def split_pair(value: str) -> list[str]:
    if "-" in value:
        left, right = value.split("-", 1)
        return [left.strip(), right.strip()]
    return [value.strip()]


def normalize_direction(raw: str) -> str:
    value = (raw or "").strip().upper()
    mapping = {
        "OUT": "source-to-dest",
        "IN": "dest-to-source",
        "BIDIR": "bidirectional",
        "BIDIRECTIONAL": "bidirectional",
        "N/A": "n/a",
        "NA": "n/a",
    }
    return mapping.get(value, "n/a")


def main() -> None:
    root = Path(__file__).resolve().parent
    source_path = root / "SAMPLE_EICD_RAW.csv"
    output_path = root / "SAMPLE_PINOUT_NORMALIZED_GENERATED.csv"

    output_fields = [
        "interface_id",
        "interface_name",
        "source_system",
        "source_element",
        "source_connector",
        "source_pin",
        "dest_system",
        "dest_element",
        "dest_connector",
        "dest_pin",
        "signal_name",
        "signal_type",
        "direction",
        "protocol_layer",
        "electrical_limits",
        "wire_color_or_id",
        "shield_drain",
        "revision",
        "source_doc_ref",
        "notes",
    ]

    rows: list[dict[str, str]] = []

    with source_path.open(newline="", encoding="utf-8") as infile:
        reader = csv.DictReader(infile)
        for idx, row in enumerate(reader, start=1):
            source_pins = split_pair(row["From Pin"])
            dest_pins = split_pair(row["To Pin"])

            if len(source_pins) != len(dest_pins):
                raise ValueError(
                    f"Packed pin mismatch on row {idx}: {row['From Pin']} vs {row['To Pin']}"
                )

            signal_name = row["Signal"].strip()
            signal_type = row["Type"].strip().lower()
            direction = normalize_direction(row["Direction"])

            expanded_names = [signal_name]
            if len(source_pins) == 2 and signal_name.endswith("_DIFF"):
                base = signal_name.removesuffix("_DIFF")
                expanded_names = [f"{base}_P", f"{base}_N"]

            interface_id = f"IF-{idx:03d}"
            for part_index, (source_pin, dest_pin) in enumerate(zip(source_pins, dest_pins)):
                rows.append(
                    {
                        "interface_id": interface_id,
                        "interface_name": row["Interface"].strip(),
                        "source_system": row["From System"].strip(),
                        "source_element": "",
                        "source_connector": row["From Connector"].strip(),
                        "source_pin": source_pin,
                        "dest_system": row["To System"].strip(),
                        "dest_element": "",
                        "dest_connector": row["To Connector"].strip(),
                        "dest_pin": dest_pin,
                        "signal_name": expanded_names[min(part_index, len(expanded_names) - 1)],
                        "signal_type": signal_type,
                        "direction": direction,
                        "protocol_layer": "1000BASE-T" if "ETH" in signal_name else ("UART" if "UART" in signal_name else ""),
                        "electrical_limits": row["Voltage"].strip(),
                        "wire_color_or_id": "",
                        "shield_drain": "",
                        "revision": row["Revision"].strip(),
                        "source_doc_ref": row["Document"].strip(),
                        "notes": row["Notes"].strip(),
                    }
                )

    with output_path.open("w", newline="", encoding="utf-8") as outfile:
        writer = csv.DictWriter(outfile, fieldnames=output_fields)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} normalized rows to {output_path}")


if __name__ == "__main__":
    main()

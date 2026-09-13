#!/usr/bin/env python3
import sys
import re

def convert_labels(input_file, output_file):
    """
    Converts a ca65/ld65 label file into a Stella/DASM compatible .sym file.

    ca65 format:  al 000080 .my_label
    DASM format:  my_label                  0080 (R )
    """
    try:
        with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
            for line in infile:
                # Match ca65 pattern: 'al' followed by a 6-digit hex address,
                # a dot (optional prefix), and the symbol name
                match = re.match(r'^al\s+([0-9A-Fa-f]{6})\s+\.?([A-Za-z0-9_]+)', line)
                if match:
                    hex_addr = match.group(1)[2:] # Grab the last 4 characters for 16-bit addressing
                    label_name = match.group(2)
                    # DASM format: Label right-padded or left-aligned, hex value, and (R )
                    outfile.write(f"{label_name:<30} {hex_addr} (R )\n")
        print(f"Successfully converted {input_file} to {output_file}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python convert_sym.py <input_labels.txt> <output_rom.sym>")
        sys.exit(1)
    convert_labels(sys.argv[1], sys.argv[2])

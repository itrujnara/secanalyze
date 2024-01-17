import sys
from secdoc import SecStruc

def main() -> None:
    if len(sys.argv) < 2:
        raise ValueError("Expected a file. Usage: python3 extract.py [PDB path]")
    try:
        s = SecStruc(sys.argv[1])
    except Exception:
        raise ValueError(f"Could not process PDB file {sys.argv[1]}.\
 Verify that it is available and correct.\
 In particular, if the file contains a DBREF entry,\
 verify that it is correct, or remove it.\
")
    s.print_report()

if __name__ == "__main__":
    main()
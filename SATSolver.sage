"""SAT-based computations for palindromic van der Waerden numbers.

Requires the tawSolver executable, compiled from SAT/tawSolver.cpp.
Run the notebook from the root directory of the GitHub repository.
"""

import os
import shutil
import subprocess
from pathlib import Path
import tempfile

def GetSATSolver():
    """
    Locate tawSolver, compiling it from source if necessary.

    Run the notebook from the repository's root directory.
    """

    root = Path.cwd()
    source = root / "SAT" / "tawSolver.cpp"

    executable = root / "SAT" / (
        "tawSolver.exe" if os.name == "nt" else "tawSolver"
    )

    # Already compiled
    if executable.is_file():
        return str(executable)

    # Check that the source is available
    if not source.is_file():
        raise FileNotFoundError(
            f"Missing SAT solver source: {source}"
        )

    # Find an installed C++ compiler
    compiler = shutil.which("g++") or shutil.which("clang++")

    if compiler is None:
        raise RuntimeError(
            "A C++ compiler (g++ or clang++) is required "
            "to compile tawSolver."
        )

    print("Compiling tawSolver from source...", flush=True)

    subprocess.run(
        [
            compiler,
            "-std=c++17",
            "-O3",
            "-DNDEBUG",
            "-o", str(executable),
            str(source)
        ],
        check=True
    )

    print("SAT solver compiled successfully!", flush=True)

    return str(executable)

def PVDW_CNF(n, t, filename):
    """Write a DIMACS CNF encoding of palindromic (3,t)-avoiding 2-colorings.

    Variables correspond to the symmetric pairs {i, n+1-i}, with 1-based
    position indices. True and false encode the two colors.

    A positive clause for every 3-term progression forbids that progression
    from being entirely false; a negative clause for every t-term progression
    forbids that progression from being entirely true.
    """
    n, t = int(n), int(t)
    if n < 1 or t < 3:
        raise ValueError("Require n >= 1 and t >= 3.")

    def variable(i):
        return min(i, n + 1 - i)

    clauses = []
    for d in range(1, (n - 1) // 2 + 1):
        for a in range(1, n - 2 * d + 1):
            clauses.append([variable(a + j * d) for j in range(3)])

    for d in range(1, (n - 1) // (t - 1) + 1):
        for a in range(1, n - (t - 1) * d + 1):
            clauses.append([-variable(a + j * d) for j in range(t)])

    with open(filename, "w", encoding="utf-8") as f:
        f.write("p cnf {} {}\n".format((n + 1) // 2, len(clauses)))
        for clause in clauses:
            f.write(" ".join(map(str, clause)) + " 0\n")

    return filename


def PVDW_SAT(n, t):
    """Return True if an admissible palindromic coloring exists, else False."""
    solver = GetSATSolver()

    # A unique temporary file prevents clashes between different runs.
    with tempfile.TemporaryDirectory(prefix="pvdw_") as directory:
        cnf = Path(directory) / "pvdw.cnf"
        PVDW_CNF(n, t, cnf)
        completed = subprocess.run(
            [str(solver), str(cnf), "-nil", "-cout"],
            capture_output=True, text=True
        )

    statuses = [line.strip() for line in completed.stdout.splitlines()
                if line.startswith("s ")]
    if "s SATISFIABLE" in statuses:
        return True
    if "s UNSATISFIABLE" in statuses:
        return False
    raise RuntimeError(
        "tawSolver returned no recognized SAT status (exit {}).\nstdout:\n{}\nstderr:\n{}"
        .format(completed.returncode, completed.stdout, completed.stderr)
    )


def FindPVDW(t):
    """Return (lower, upper) palindromic van der Waerden thresholds.

    For each parity, find the first n without an admissible palindromic
    coloring. The reported bounds are one less than these two n-values.
    """
    first_unsat = {}
    n = 1
    while len(first_unsat) < 2:
        parity = n % 2
        if parity not in first_unsat and not PVDW_SAT(n, t):
            first_unsat[parity] = n
        n += 1

    bounds = [value - 1 for value in first_unsat.values()]
    return (min(bounds), max(bounds))

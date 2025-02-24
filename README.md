**Blench** is a multi-language benchmarking suite that automates the build, evaluation, and reporting of benchmarks written in various programming languages including Rust, C, C++, Java, Python, Go, OCaml, Zig, Fortran, and Julia. This benchmarking tool is provided as a Bash script that compiles and runs benchmarks with configurable timeouts, core counts, and run numbers.

## Features

- **Multi-Language Support:** Benchmarks for Rust, C, C++, Java, Python, Go, OCaml, Zig, Fortran, and Julia.
- **Automated Build:** Compiles/builds each benchmark and ensures executables are marked as executable.
- **Configurable Evaluation:** Specify timeout, number of cores, and run count.
- **Concise Reporting:** Generates a minimal JSON report with only relevant system, compiler, and performance data.
- **Easy Sharing:** Automatically copies the report to your clipboard for quick mailing.

## Requirements

- **Bash 3.2+** (default on macOS; Linux supported)
- **Toolchain for each language:**
  - Rust (cargo, rustc)
  - C/C++ (gcc/clang, g++/clang++)
  - Java (javac, java)
  - Python 3
  - Go
  - OCaml (opam, ocamlopt)
  - Zig
  - Fortran (gfortran)
  - Julia

For installation hints for each tool, see the script's `get_install_cmd` function.

## Installation

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/vitruves/blench.git
   cd blench

	2.	Make the Script Executable:

chmod +x blench.bash


	3.	Install Benchmarks:

./blench.bash install

This command builds the benchmarks and creates the executables in the build/ directory.

Usage

After installation, run the evaluation phase with customizable options. For example:

./blench.bash --timeout 1 --mp 3 --stats 1

	•	--timeout <sec>: Timeout in seconds for each benchmark.
	•	--mp <cores>: Number of cores to use.
	•	--stats <n-runs>: (Optional) Number of runs per benchmark (default: 1).
	•	--lang <lang1,lang2,...>: (Optional) Comma-separated list of languages to run (or all).

Example

Running with a 1‑second timeout, 3 cores, and 1 run per benchmark:

./blench.bash --timeout 1 --mp 3 --stats 1

The script performs a brief warmup run, then evaluates each benchmark, prints a performance podium and detailed results to the console, and generates a JSON report (benchmark_report.json) that is automatically copied to your clipboard for easy sharing.

Report and Sharing

The generated JSON report includes:
	•	System: Operating system and version.
	•	Compilers: Versions for each language.
	•	Parameters: Timeout, core count, and run count.
	•	Results: Average, minimum, and maximum operations per second.

After evaluation, the report is copied to your clipboard (using pbcopy on macOS or xclip on Linux) so you can quickly paste it into an email.

Cleaning Up

To remove all build artifacts and the generated report, run:

./blench.bash clean

Troubleshooting
	•	Missing Dependencies:
Run:

./blench.bash check

to verify that all required tools are installed.

	•	OCaml Module Name Warning:
Ensure your OCaml source file is named bench_ocaml.ml (in the src/ directory).
	•	Fortran Warnings:
Legacy warnings from Fortran (such as non-integer DO loop bounds) can usually be ignored. If preferred, modify your Fortran source to declare all array indices and DO loop bounds as integers.

Contributing

Contributions are welcome! Please open an issue or submit a pull request with your improvements.

License

This project is licensed under the MIT License.
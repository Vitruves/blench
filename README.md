
![result-MTtQpJBAg3](https://github.com/user-attachments/assets/3392f0f2-39b1-477f-873e-90552714eb54)

# Blench

**Blench** is a multi-language benchmarking suite that automates the build, evaluation, and reporting of benchmarks written in various programming languages, including Rust, C, C++, Java, Python, Go, OCaml, Zig, Fortran, and Julia. Distributed as a single Bash script, Blench simplifies compiling and running benchmarks with configurable timeouts, core counts, and run numbers.

---

## Features

### Multi-Language Support
Supports benchmarks in:
- Rust
- C
- C++
- Java
- Python
- Go
- OCaml
- Zig
- Fortran
- Julia

### Automated Build
- Compiles/builds each benchmark and ensures executables are properly set with executable permissions.

### Configurable Evaluation
- Customize the benchmark run with options for timeout duration, number of cores, and run count.

### Concise Reporting
- Generates a minimal JSON report containing essential system, compiler, and performance data.

### Easy Sharing
- Automatically copies the generated JSON report to your clipboard for seamless sharing.

---

## Requirements

### General Requirements
- **Bash 3.2+** (default on macOS; Linux is also supported)

### Language Toolchains
- **Rust**: Requires `cargo` and `rustc`
- **C/C++**: Requires `gcc`/`clang` and `g++`/`clang++`
- **Java**: Requires `javac` and `java`
- **Python**: Python 3.x
- **Go**
- **OCaml**: Requires `opam` and `ocamlopt`
- **Zig**
- **Fortran**: Requires `gfortran`
- **Julia**

For installation hints for each tool, refer to the script’s `get_install_cmd` function.

---

## Installation

### Clone the Repository
```bash
git clone https://github.com/vitruves/blench.git
cd blench
```

### Make the Script Executable
```bash
chmod +x blench.bash
```

### Install Benchmarks
```bash
./blench.bash install
```
This command builds the benchmarks and creates the executables in the `build/` directory.

---

## Usage

After installation, you can run the evaluation phase with customizable options. For example, to run with a **1-second timeout, 3 cores, and 1 run per benchmark**, use:
```bash
./blench.bash --timeout 1 --mp 3 --stats 1
```

### Command-Line Options
- `--timeout <sec>`: Specifies the timeout in seconds for each benchmark.
- `--mp <cores>`: Sets the number of cores to use.
- `--stats <n-runs>`: (Optional) Specifies the number of runs per benchmark (default is 1).
- `--lang <lang1,lang2,...>`: (Optional) Comma-separated list of languages to run (defaults to all languages).

---

## Evaluation Workflow

### 1. Warmup Run
- A brief warmup is executed before the actual evaluation.

### 2. Benchmark Evaluation
- Each benchmark is evaluated, and a **performance podium** is printed to the console along with detailed results.

### 3. Reporting
- A **JSON report (`benchmark_report.json`)** is generated containing:
  - **System**: Operating system and version.
  - **Compilers**: Versions for each language used.
  - **Parameters**: Timeout, core count, and run count.
  - **Results**: Average, minimum, and maximum operations per second.

### 4. Sharing
- The report is **automatically copied to your clipboard** (using `pbcopy` on macOS or `xclip` on Linux) for easy sharing.
- Feel free to send it to **johan.natter@gmail.com** for statistics (I will publish them once I gather enough!).

---

## Cleaning Up
To remove all build artifacts and the generated report, run:
```bash
./blench.bash clean
```

---

## Troubleshooting

### Missing Dependencies
Run the following command to verify that all required tools are installed:
```bash
./blench.bash check
```

### OCaml Module Name Warning
Ensure your OCaml source file is named **`bench_ocaml.ml`** and is located in the `src/` directory.

### Fortran Warnings
Legacy warnings (such as **non-integer DO loop bounds**) can typically be ignored. To suppress warnings, consider modifying your Fortran source to declare all array indices and DO loop bounds as integers.

---

## Contributing
Contributions are welcome! If you have improvements or suggestions, please open an issue or submit a pull request.

---

## License
This project is licensed under the **MIT License**.


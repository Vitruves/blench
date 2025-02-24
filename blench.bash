#!/usr/bin/env bash
set -e

############################################
# Global Variables and Directories
############################################

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
PROJECT_ROOT="$(dirname "$SCRIPT_PATH")"
BUILD_DIR="$PROJECT_ROOT/build"
SRC_DIR="$PROJECT_ROOT/src"
STATS_RUNS=1
WARMUP_TIME=1  # seconds of warmup
# Comma-separated language list
LANGUAGES="rust,cpp,c,java,python,go,ocaml,zig,fortran,julia"
REPORT_FILE="benchmark_report.json"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

############################################
# Utility Functions
############################################

get_deps() {
    local lang=$1
    case $lang in
        rust)   echo "cargo rustc" ;;
        cpp)    echo "c++" ;;
        c)      echo "gcc" ;;
        java)   echo "javac java" ;;
        python) echo "python3" ;;
        go)     echo "go" ;;
        ocaml)  echo "opam" ;;
        zig)    echo "zig" ;;
        fortran) echo "gfortran" ;;
        julia)  echo "julia" ;;
    esac
}

get_install_cmd() {
    local lang=$1
    case $lang in
        rust)   echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh" ;;
        cpp)    echo "xcode-select --install || brew install gcc" ;;
        c)      echo "brew install gcc" ;;
        java)   echo "brew install openjdk" ;;
        python) echo "brew install python3" ;;
        go)     echo "brew install go" ;;
        ocaml)  echo "brew install opam && opam init && opam install ocamlfind base-threads" ;;
        zig)    echo "brew install zig" ;;
        fortran) echo "brew install gcc" ;;
        julia)  echo "brew install julia" ;;
    esac
}

print_help() {
    cat <<EOF
Usage:
  $0 install            # Install (build) all benchmarks
  $0 check              # Check required dependencies
  $0 clean              # Remove all build artifacts
  $0 --timeout <sec> --mp <cores> [--stats <n-runs>] [--lang <lang1,lang2,...>]

Options:
  --timeout <sec>    Timeout in seconds for each benchmark
  --mp <cores>       Number of cores to use
  --stats <n-runs>   Number of runs for statistics (default: 1)
  --lang <langs>     Comma-separated list of languages to run (or 'all')
EOF
}

############################################
# Build Functions
############################################

build_with_warning() {
    local lang=$1
    local cmd=$2
    echo "-- Building $lang benchmark"
    if ! (cd "$BUILD_DIR" && eval "$cmd") 2> >(grep -vE "warning: (object file.*was built for newer.*macOS.*version|reexported library.*libunwind)" >&2); then
        echo -e "${RED}Error building $lang benchmark${NC}"
        return 1
    fi
}

install_benchmarks() {
    echo "-- Installing benchmarks"
    mkdir -p "$BUILD_DIR"
    local failed=()

    # Rust
    if ! build_with_warning "Rust" "(cd $PROJECT_ROOT && cargo build --release) && ln -sf $PROJECT_ROOT/target/release/bench-rust $BUILD_DIR/"; then
        failed+=("rust")
    fi

    # C++
    if command -v g++ >/dev/null 2>&1; then
        CXX="g++"
    else
        CXX="clang++"
    fi
    if ! build_with_warning "C++" "$CXX -O3 -march=native -flto -pthread -std=c++11 $SRC_DIR/bench-cpp.cpp -o bench-cpp"; then
        failed+=("cpp")
    fi

    # C
    if ! build_with_warning "C" "gcc -O3 -march=native -flto -pthread $SRC_DIR/bench-c.c -o bench-c"; then
        failed+=("c")
    fi

    # Java
    if ! build_with_warning "Java" "mkdir -p classes/bench && javac -d classes $SRC_DIR/BenchJava.java"; then
        failed+=("java")
    fi

    # Python
    echo "-- Setting up Python benchmark"
    if ! build_with_warning "Python" "(cd $BUILD_DIR && ln -sf ../src/bench-python.py bench-python)"; then
        failed+=("python")
    fi

    # Go
    if ! build_with_warning "Go" "go build -o bench-go -ldflags=\"-s -w\" $SRC_DIR/bench-go.go"; then
        failed+=("go")
    fi

    # OCaml – use the original file name to keep a valid module name
    if command -v opam >/dev/null 2>&1; then
        eval "$(opam env)"
        rm -f "$SRC_DIR"/bench_ocaml.{cmi,cmx,o}
        OCAML_CMD="ocamlfind ocamlopt -O3 -thread -package unix,threads -linkpkg -ccopt '-Wl,-no_compact_unwind'"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            OCAML_CMD="$OCAML_CMD -cclib -framework -cclib CoreFoundation"
        fi
        if ! build_with_warning "OCaml" "$OCAML_CMD $SRC_DIR/bench_ocaml.ml -o $BUILD_DIR/bench-ocaml"; then
            failed+=("ocaml")
        fi
    else
        failed+=("ocaml")
    fi

    # Zig – fix: extract final number from output
    if ! build_with_warning "Zig" "zig build-exe $SRC_DIR/bench-zig.zig -O ReleaseFast --name bench-zig"; then
        failed+=("zig")
    fi

    # Fortran
    if ! build_with_warning "Fortran" "gfortran -O3 -march=native -fopenmp $SRC_DIR/bench-fortran.f90 -o bench-fortran"; then
        failed+=("fortran")
    fi

    # Julia
    echo "-- Setting up Julia benchmark"
    if ! build_with_warning "Julia" "cp $SRC_DIR/bench-julia.jl $BUILD_DIR/bench-julia && chmod +x $BUILD_DIR/bench-julia"; then
        failed+=("julia")
    fi

    # Ensure all built binaries are executable
    for exe in "$BUILD_DIR"/bench-* "$BUILD_DIR"/classes/bench/*; do
        [ -f "$exe" ] && chmod +x "$exe"
    done

    echo "-- Installation complete"
    if [ ${#failed[@]} -gt 0 ]; then
        echo -e "${YELLOW}Warning: Some benchmarks failed to build: ${failed[*]}${NC}"
    fi
}

############################################
# Benchmark Execution Functions
############################################

benchmark_exists() {
    local lang=$1
    case $lang in
        java)
            [ -d "$BUILD_DIR/classes/bench" ] && [ -f "$BUILD_DIR/classes/bench/BenchJava.class" ]
            ;;
        python)
            [ -f "$BUILD_DIR/bench-python" ] && [ -x "$BUILD_DIR/bench-python" ]
            ;;
        julia)
            [ -f "$BUILD_DIR/bench-julia" ] && [ -x "$BUILD_DIR/bench-julia" ]
            ;;
        *)
            [ -f "$BUILD_DIR/bench-$lang" ] && [ -x "$BUILD_DIR/bench-$lang" ]
            ;;
    esac
}

execute_benchmark() {
    local lang=$1 timeout=$2 cores=$3
    local cmd=""
    case $lang in
        java)   cmd="java -cp classes bench.BenchJava --timeout $timeout --mp $cores" ;;
        python) cmd="python3 bench-python --timeout $timeout --mp $cores" ;;
        julia)  cmd="julia bench-julia --timeout $timeout --mp $cores" ;;
        zig)    cmd="./bench-zig --timeout $timeout --mp $cores" ;;
        *)      cmd="./bench-$lang --timeout $timeout --mp $cores" ;;
    esac
    local output
    output=$(cd "$BUILD_DIR" && eval "$cmd")
    local num
    if [ "$lang" = "zig" ]; then
        num=$(echo "$output" | grep -o "[0-9]\+" | tail -n 1)
    else
        num=$(echo "$output" | grep -o "[0-9]\+")
    fi
    if [ -n "$num" ]; then
        echo "$num"
    else
        echo "$output"
    fi
}

RESULTS=()
RESULT_LANGS=()

run_benchmark() {
    local lang=$1 timeout=$2 cores=$3 runs=$4 mode=${5:-""}
    if ! benchmark_exists "$lang"; then
        echo -e "${YELLOW}Skipping $lang: benchmark not built${NC}"
        return 0
    fi
    if [ "$mode" != "warmup" ]; then
        printf "${GREEN}-- Running %s benchmark (%d runs)${NC}\n" "$lang" "$runs"
    fi
    local results=()
    for ((i=1; i<=runs; i++)); do
        [ "$mode" != "warmup" ] && printf "   Run %d: " "$i"
        local result
        result=$(execute_benchmark "$lang" "$timeout" "$cores")
        if [ $? -eq 0 ] && [ -n "$result" ]; then
            echo "$result operations"
            results+=("$result")
        else
            echo -e "${RED}Failed - skipping remaining runs${NC}"
            return 0
        fi
    done
    if [ "$mode" != "warmup" ]; then
        if [ "$runs" -gt 1 ] && [ ${#results[@]} -gt 0 ]; then
            local sum=0 min=${results[0]} max=${results[0]}
            for r in "${results[@]}"; do
                sum=$((sum + r))
                [ "$r" -lt "$min" ] && min=$r
                [ "$r" -gt "$max" ] && max=$r
            done
            local avg=$((sum / runs))
            RESULTS+=("$lang:$avg")
            RESULT_LANGS+=("$lang")
            echo "   Statistics:"
            echo "     Average: $avg"
            echo "     Min: $min"
            echo "     Max: $max"
            printf "    {\"lang\": \"%s\", \"avg\": %d, \"min\": %d, \"max\": %d},\n" "$lang" "$avg" "$min" "$max" >> "$REPORT_FILE"
        else
            RESULTS+=("$lang:${results[0]}")
            RESULT_LANGS+=("$lang")
            printf "    {\"lang\": \"%s\", \"avg\": %d, \"min\": %d, \"max\": %d},\n" "$lang" "${results[0]}" "${results[0]}" "${results[0]}" >> "$REPORT_FILE"
        fi
    fi
}

display_podium() {
    local -a sorted_langs=()
    for result in "${RESULTS[@]}"; do
        IFS=':' read -r lang score <<< "$result"
        sorted_langs+=("$lang $score")
    done
    IFS=$'\n' sorted_langs=($(sort -k2 -nr <<<"${sorted_langs[*]}"))
    unset IFS
    local count=${#sorted_langs[@]}
    echo
    echo "🏆 Performance Podium 🏆"
    echo "--------------------------"
    for ((i=0; i<count && i<3; i++)); do
        echo "${sorted_langs[i]}"
    done
    echo "--------------------------"
    echo "Detailed Results:"
    for result in "${RESULTS[@]}"; do
        IFS=':' read -r lang score <<< "$result"
        printf "%-10s : %'12d operations/s\n" "$lang" "$score"
    done
    echo
}

############################################
# Report and Mail Functions
############################################

generate_report() {
    local timeout=$1
    local cores=$2
    local runs=$3
    {
        echo "{"
        echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"system\": {"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "    \"os\": \"macOS\","
            echo "    \"version\": \"$(sw_vers -productVersion)\""
        else
            echo "    \"os\": \"Linux\","
            echo "    \"version\": \"$(uname -r)\""
        fi
        echo "  },"
        echo "  \"compilers\": {"
        echo "    \"rust\": \"$(rustc --version 2>/dev/null || echo 'not installed')\","
        echo "    \"cpp\": \"$(g++ --version 2>/dev/null | head -n1 || clang++ --version 2>/dev/null | head -n1 || echo 'not installed')\","
        echo "    \"c\": \"$(gcc --version 2>/dev/null | head -n1 || echo 'not installed')\","
        echo "    \"java\": \"$(java -version 2>&1 | head -n1 || echo 'not installed')\","
        echo "    \"python\": \"$(python3 --version 2>/dev/null || echo 'not installed')\","
        echo "    \"go\": \"$(go version 2>/dev/null || echo 'not installed')\","
        echo "    \"ocaml\": \"$(ocamlopt -version 2>/dev/null || echo 'not installed')\","
        echo "    \"zig\": \"$(zig version 2>/dev/null || echo 'not installed')\","
        echo "    \"fortran\": \"$(gfortran --version 2>/dev/null | head -n1 || echo 'not installed')\","
        echo "    \"julia\": \"$(julia --version 2>/dev/null || echo 'not installed')\""
        echo "  },"
        echo "  \"parameters\": {"
        echo "    \"timeout\": $timeout,"
        echo "    \"cores\": $cores,"
        echo "    \"runs\": $runs"
        echo "  },"
        echo "  \"results\": ["
    } > "$REPORT_FILE"
}

send_report_via_mail() {
    local report_file=$1
    if [ ! -f "$report_file" ]; then
        echo -e "${RED}No report found to send.${NC}"
        return 1
    fi
    if command -v pbcopy >/dev/null 2>&1; then
        cat "$report_file" | pbcopy
        echo -e "${GREEN}Report copied to clipboard (macOS). Paste it in your email client to send it to the maintainer.${NC}"
    elif command -v xclip >/dev/null 2>&1; then
        cat "$report_file" | xclip -selection clipboard
        echo -e "${GREEN}Report copied to clipboard (Linux). Paste it in your email client to send it to the maintainer.${NC}"
    else
        echo -e "${YELLOW}Clipboard utility not found. Please open $report_file and send it manually via email.${NC}"
    fi
}

############################################
# Clean Function
############################################

clean_benchmarks() {
    echo "-- Cleaning build artifacts"
    [ -d "$BUILD_DIR" ] && { rm -rf "$BUILD_DIR"; echo "   Removed build directory"; }
    [ -d "$PROJECT_ROOT/target" ] && { rm -rf "$PROJECT_ROOT/target"; echo "   Removed Rust target directory"; }
    rm -f "$SRC_DIR"/*.{cmi,cmx,o} && echo "   Removed OCaml intermediate files"
    [ -f "$REPORT_FILE" ] && { rm -f "$REPORT_FILE"; echo "   Removed benchmark report"; }
    echo -e "${GREEN}-- Clean complete${NC}"
}

############################################
# Main Execution
############################################

main() {
    if [ $# -eq 0 ]; then
        print_help
        exit 1
    fi

    case "$1" in
        install)
            install_benchmarks
            exit 0
            ;;
        check)
            check_dependencies
            exit $?
            ;;
        clean)
            clean_benchmarks
            exit 0
            ;;
        --help)
            print_help
            exit 0
            ;;
    esac

    # Ensure benchmarks are installed before evaluation.
    if [ ! -d "$BUILD_DIR" ] || [ -z "$(ls -A "$BUILD_DIR")" ]; then
        echo -e "${RED}Benchmarks not installed. Please run './blench.bash install' before evaluation.${NC}"
        exit 1
    fi

    local timeout="" cores="" langs="$LANGUAGES"
    while [ $# -gt 0 ]; do
        case "$1" in
            --timeout)
                timeout="$2"; shift 2 ;;
            --mp)
                cores="$2"; shift 2 ;;
            --stats)
                STATS_RUNS="$2"; shift 2 ;;
            --lang)
                if [ "$2" = "all" ]; then
                    langs="$LANGUAGES"
                elif [[ "$2" == *","* ]]; then
                    langs="$2"
                else
                    shift; langs=""
                    while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
                        langs="${langs}${langs:+,}$1"
                        shift
                    done
                    continue
                fi
                shift 2 ;;
            *)
                echo "Unknown option: $1"
                print_help
                exit 1 ;;
        esac
    done

    if [ -z "$timeout" ] || [ -z "$cores" ]; then
        echo -e "${RED}Error: --timeout and --mp are required${NC}"
        print_help
        exit 1
    fi

    echo -e "${GREEN}-- Starting benchmarks${NC}"
    echo "   Warmup: ${WARMUP_TIME}s"
    echo "   Timeout: ${timeout}s"
    echo "   Cores: $cores"
    echo "   Runs per benchmark: $STATS_RUNS"
    echo ""

    generate_report "$timeout" "$cores" "$STATS_RUNS"

    IFS=',' read -ra LANG_ARRAY <<< "$langs"
    for lang in "${LANG_ARRAY[@]}"; do
        # Run warmup, then evaluation
        run_benchmark "$lang" "$WARMUP_TIME" "$cores" 1 "warmup" >/dev/null 2>&1
        run_benchmark "$lang" "$timeout" "$cores" "$STATS_RUNS"
    done

    echo -e "${GREEN}-- Report generated: $REPORT_FILE${NC}"
    display_podium
    send_report_via_mail "$REPORT_FILE"

    {
        echo "  ]"
        echo "}"
    } >> "$REPORT_FILE"
}

main "$@"
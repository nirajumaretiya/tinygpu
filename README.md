# tiny-gpu

A minimal GPU implementation in Verilog optimized for learning how GPUs work from the ground up.

Built with fewer than 15 files of fully documented Verilog code, complete architecture & ISA documentation, working matrix addition/multiplication kernels, and full support for kernel simulation & execution traces.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
  - [GPU](#gpu)
  - [Memory](#memory)
  - [Core](#core)
- [ISA](#isa)
- [Execution](#execution)
  - [Core](#core-1)
  - [Thread](#thread)
- [Kernels](#kernels)
  - [Matrix Addition](#matrix-addition)
  - [Matrix Multiplication](#matrix-multiplication)
- [Simulation](#simulation)
- [Next Steps](#next-steps)

## Overview

Modern GPUs are complex pieces of hardware, and while many resources exist on GPU programming, very few explain the hardware details. **tiny-gpu** is designed as an educational tool that simplifies GPU design and operation, stripping away the extra layers of production complexity to focus on core principles:

- **Architecture** – Understand the building blocks of a GPU.
- **Parallelization** – Learn how SIMD programming is implemented in hardware.
- **Memory** – See how GPUs manage limited memory bandwidth with dedicated controllers and caching.

By studying tiny-gpu, you’ll gain a deeper insight into the basic elements that underlie both traditional GPUs and modern ML accelerators.

## Architecture

### GPU

tiny-gpu executes a single kernel at a time. To launch a kernel, the following steps occur:

1. Global program memory is loaded with kernel code.
2. Data memory is loaded with necessary data.
3. The device control register is set with the number of threads for the kernel.
4. The kernel is launched by activating the start signal.

The GPU consists of several units:

- **Device Control Register:** Holds metadata like `thread_count` which defines the number of threads to launch.
- **Dispatcher:** Organizes threads into blocks and dispatches them to available compute cores. It monitors kernel execution and signals when the job is done.
- **Compute Cores:** Execute the kernels using dedicated resources for each thread.
- **Memory Controllers:** Manage data and program memory accesses.
- **Cache:** Stores frequently accessed data to reduce the cost of repeated global memory access.

### Memory

The GPU interfaces with separate global memories for data and program instructions.

- **Data Memory:** 
  - 8-bit addressability (256 rows).
  - 8-bit data per row.
- **Program Memory:** 
  - 8-bit addressability (256 rows).
  - 16-bit instructions, as defined by the ISA.

Memory controllers handle the bandwidth constraints by managing requests between the compute cores and the external memories.

### Core

Each compute core processes one block at a time. Every thread within a block is equipped with its own ALU, LSU, PC, and register file. Core components include:

- **Scheduler:** Executes all threads in a block in lockstep. Although simple, it effectively demonstrates the principles of parallel execution.
- **Fetcher:** Retrieves instructions from program memory.
- **Decoder:** Translates instructions into control signals.
- **Register Files:** Store each thread’s working data, including special read-only registers (`%blockIdx`, `%blockDim`, `%threadIdx`) used for SIMD programming.
- **ALUs:** Perform arithmetic and logic operations.
- **LSUs:** Handle global memory load and store operations.
- **PC Units:** Maintain the program counter for each thread and manage branching using the `BRnzp` instruction.

## ISA

tiny-gpu features a concise 11-instruction ISA, supporting essential operations for kernel execution. The instructions include:

- **BRnzp:** Conditional branch based on the NZP register.
- **CMP:** Compares two registers and sets the NZP flag.
- **ADD, SUB, MUL, DIV:** Basic arithmetic operations.
- **LDR, STR:** Load and store data from global memory.
- **CONST:** Load an immediate constant into a register.
- **RET:** Indicates the end of a thread's execution.

Registers are 4 bits wide, providing 16 registers per thread; registers `R0`–`R12` are general-purpose, and the last 3 are dedicated to the SIMD registers.

## Execution

### Core

Each compute core processes instructions through a six-step control flow:

1. **FETCH:** Retrieve the next instruction using the current program counter.
2. **DECODE:** Convert the instruction into control signals.
3. **REQUEST:** Issue memory requests if needed (for LDR/STR).
4. **WAIT:** Handle asynchronous memory responses.
5. **EXECUTE:** Perform arithmetic or logical computations.
6. **UPDATE:** Update the register files and NZP flag.

This step-by-step approach emphasizes clarity over optimization.

### Thread

Each thread follows the same six-step execution cycle, using its own register file to hold data. The dedicated read-only registers for `%blockIdx`, `%blockDim`, and `%threadIdx` facilitate SIMD operations across threads.

## Kernels

The repository includes two example kernels to illustrate the functionality of tiny-gpu.

### Matrix Addition

The matrix addition kernel performs element-wise addition on two 1x8 matrices using separate threads. It leverages the SIMD registers to calculate the index and uses LDR/STR for memory operations.

```asm
.threads 8
.data 0 1 2 3 4 5 6 7          ; Matrix A (1 x 8)
.data 0 1 2 3 4 5 6 7          ; Matrix B (1 x 8)

MUL R0, %blockIdx, %blockDim
ADD R0, R0, %threadIdx         ; i = blockIdx * blockDim + threadIdx

CONST R1, #0                   ; Base address for Matrix A
CONST R2, #8                   ; Base address for Matrix B
CONST R3, #16                  ; Base address for Matrix C

ADD R4, R1, R0                 ; Compute address for A[i]
LDR R4, R4                     ; Load A[i]

ADD R5, R2, R0                 ; Compute address for B[i]
LDR R5, R5                     ; Load B[i]

ADD R6, R4, R5                 ; Compute C[i] = A[i] + B[i]

ADD R7, R3, R0                 ; Compute address for C[i]
STR R7, R6                     ; Store C[i]

RET                            ; End of kernel

# tiny-gpu

A minimal GPU implementation in Verilog optimized for learning how GPUs work from the ground up.

Built with fewer than 15 fully documented Verilog files, tiny-gpu includes complete documentation on its architecture and ISA, working kernels for matrix addition and multiplication, and full support for kernel simulation with detailed execution traces.

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
- [Advanced Functionality](#advanced-functionality)
- [Next Steps](#next-steps)

## Overview

Modern GPUs are notoriously complex. While many resources exist for GPU programming, very few explain the inner hardware details. **tiny-gpu** is designed as an educational tool to help you understand GPU fundamentals by stripping away production-grade complexities. With tiny-gpu, you can learn:

- **Architecture:** Discover the fundamental building blocks of a GPU.
- **Parallelization:** Understand how the SIMD programming model is implemented in hardware.
- **Memory Management:** Learn about the techniques used to handle limited memory bandwidth through dedicated controllers and caching.

This project provides a clear, minimalistic design that highlights the critical components common to both traditional GPUs and modern ML accelerators.

## Architecture

### GPU

tiny-gpu is designed to execute one kernel at a time. The process of launching a kernel involves:

1. **Program Loading:** Load the global program memory with the kernel code.
2. **Data Loading:** Load data memory with the necessary data.
3. **Thread Specification:** Specify the total number of threads to launch via the device control register.
4. **Kernel Launch:** Start the kernel execution by setting the start signal.

The GPU comprises several key units:

- **Device Control Register:** Stores metadata (like `thread_count`) that determines how many threads to launch.
- **Dispatcher:** Groups threads into blocks and distributes them to compute cores. It manages block execution and signals when the kernel has finished.
- **Compute Cores:** Execute the kernel instructions using dedicated resources for each thread.
- **Memory Controllers:** Manage access to the external global data and program memories.
- **Cache:** Stores frequently accessed data to reduce costly repeated accesses to external memory.

### Memory

tiny-gpu uses separate memories for data and program instructions:

- **Data Memory:**
  - 8-bit addressability (256 rows).
  - Each row holds 8 bits of data.
- **Program Memory:**
  - 8-bit addressability (256 rows).
  - Each instruction is 16 bits, conforming to the ISA.

Memory controllers balance the load between compute cores and external memory by managing request traffic and ensuring bandwidth limitations are respected.

### Core

Each compute core is responsible for executing one block of threads at a time. Every thread within a block is equipped with its own set of components:

- **Scheduler:** Coordinates the execution of all threads in a block sequentially and in lockstep. Although the scheduling is simplified, it demonstrates the key principles of parallel execution.
- **Fetcher:** Asynchronously retrieves instructions from program memory (or cache, when available).
- **Decoder:** Converts fetched instructions into a set of control signals for execution.
- **Register Files:** Store each thread’s working data, including three special read-only registers (`%blockIdx`, `%blockDim`, and `%threadIdx`) critical for SIMD operations.
- **ALUs:** Each thread’s arithmetic logic unit performs basic arithmetic operations (`ADD`, `SUB`, `MUL`, `DIV`) and comparisons (`CMP`).
- **LSUs:** Handle asynchronous load (`LDR`) and store (`STR`) operations to global memory.
- **PC Units:** Maintain individual program counters for threads and manage branching with instructions like `BRnzp`.

## ISA

tiny-gpu implements a concise 11-instruction ISA to support simple kernels. The instructions include:

- **BRnzp:** Conditional branch based on the NZP register flags.
- **CMP:** Compares two registers and sets the NZP flag based on the result.
- **ADD, SUB, MUL, DIV:** Basic arithmetic operations.
- **LDR, STR:** Load and store data to/from global memory.
- **CONST:** Load a constant value into a register.
- **RET:** Indicates the end of a thread’s execution.

Each register is specified with 4 bits, providing 16 registers per thread. Registers R0 to R12 are general-purpose, while the last 3 are dedicated to SIMD functionality.

## Execution

### Core

Each compute core processes instructions through a six-step pipeline:

1. **FETCH:** Retrieve the instruction at the current program counter.
2. **DECODE:** Convert the fetched instruction into control signals.
3. **REQUEST:** Issue memory access requests (for LDR/STR operations).
4. **WAIT:** Await responses for asynchronous memory operations.
5. **EXECUTE:** Perform the required arithmetic or logical operations.
6. **UPDATE:** Write back results to register files and update the NZP flag.

This detailed control flow makes it easier to understand how GPUs manage and execute instructions.

### Thread

Each thread follows the same six-step sequence, maintaining its own set of registers. The inclusion of the special read-only registers (`%blockIdx`, `%blockDim`, `%threadIdx`) enables parallel execution under the SIMD paradigm.

## Kernels

tiny-gpu includes example kernels that demonstrate its capabilities. Two key examples are provided:

### Matrix Addition

This kernel performs element-wise addition on two 1x8 matrices. Each thread computes the sum of corresponding elements from two matrices.

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
STR R7, R6                     ; Store result in Matrix C

RET                            ; End of kernel

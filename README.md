# Pipelined RISC-V CPU

This project implements a **pipelined RISC-V CPU** in Verilog.
The CPU supports a subset of instructions and is tested using provided testbenches and synthesis tools.

## Experiment Results

Example synthesis results (`make time`):

* **Area:** 9461.62 µm² (< 25,000 µm² target)
* **Frequency:** \~1.27 GHz (1 / 788 ps)
* **Gates Used:** 7798

## Features

* Implements a 8-stage pipelined CPU (IF, ID, EX(0,1,2,3), MEM, WB).
* Handles **data hazards** and **control hazards**.
* Supports the required instruction subset.
* Synthesized and tested with **Yosys** and the **FreePDK 45nm** standard cell library.

## How to Run

1. Build and test:

   ```bash
   make
   make test
   ```
2. View timing and area results:

   ```bash
   make time
   ```

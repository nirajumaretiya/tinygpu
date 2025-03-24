# 🚀 tinygpu

<div align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"/>
  <img src="https://img.shields.io/badge/Verilog-2001-orange.svg" alt="Verilog"/>
  <img src="https://img.shields.io/badge/docs-latest-green.svg" alt="Documentation"/>
</div>

> 🚀 *Originally created by [Adam Majmudar](https://github.com/adam-maj/tiny-gpu). This is a cloned and slightly customized version by [adam-maj](https://github.com/adam-maj). Huge shoutout to the original project for making GPU architecture so approachable!*

<div align="center">
  <img src="https://readme-typing-svg.herokuapp.com?font=Fira+Code&pause=1000&color=2D9EF7&center=true&vCenter=true&width=435&lines=A+minimal+GPU+implementation+in+Verilog;Optimized+for+learning+GPU+fundamentals" alt="Typing SVG" />
</div>

A minimal GPU implementation in Verilog optimized for learning how GPUs work from the ground up. Built with fewer than 15 fully documented Verilog files, tinygpu includes complete documentation on its architecture and ISA, working kernels for matrix addition and multiplication, and full support for kernel simulation with detailed execution traces.

## 🌟 Features

<table>
  <tr>
    <td align="center">🎯 <b>Simplified Architecture</b></td>
    <td align="center">📚 <b>Complete Documentation</b></td>
    <td align="center">💻 <b>Working Examples</b></td>
  </tr>
  <tr>
    <td>Learn GPU fundamentals without production-grade complexities</td>
    <td>Detailed explanations of architecture, ISA, and execution flow</td>
    <td>Ready-to-use kernels for matrix operations</td>
  </tr>
  <tr>
    <td align="center">🔍 <b>Simulation Support</b></td>
    <td align="center">🎓 <b>Educational Focus</b></td>
  </tr>
  <tr>
    <td>Detailed execution traces for debugging and learning</td>
    <td>Perfect for understanding GPU internals</td>
  </tr>
</table>

## 📚 Table of Contents

<div align="center">
  <table>
    <tr>
      <td><a href="#overview">Overview</a></td>
      <td><a href="#architecture">Architecture</a></td>
      <td><a href="#isa">ISA</a></td>
    </tr>
    <tr>
      <td><a href="#execution">Execution</a></td>
      <td><a href="#kernels">Kernels</a></td>
      <td><a href="#getting-started">Getting Started</a></td>
    </tr>
  </table>
</div>

## Overview

Modern GPUs are notoriously complex. While many resources exist for GPU programming, very few explain the inner hardware details. **tinygpu** is designed as an educational tool to help you understand GPU fundamentals by stripping away production-grade complexities. With tinygpu, you can learn:

<table>
  <tr>
    <td align="center">🏗️ <b>Architecture</b></td>
    <td align="center">🔄 <b>Parallelization</b></td>
    <td align="center">💾 <b>Memory Management</b></td>
  </tr>
  <tr>
    <td>Discover the fundamental building blocks of a GPU</td>
    <td>Understand how the SIMD programming model is implemented in hardware</td>
    <td>Learn about techniques for handling limited memory bandwidth</td>
  </tr>
</table>

This project provides a clear, minimalistic design that highlights the critical components common to both traditional GPUs and modern ML accelerators.

## Architecture

### GPU

tinygpu is designed to execute one kernel at a time. The process of launching a kernel involves:

<div align="center">
  <table>
    <tr>
      <td>1️⃣ <b>Program Loading</b></td>
      <td>2️⃣ <b>Data Loading</b></td>
    </tr>
    <tr>
      <td>Load kernel code into global program memory</td>
      <td>Load necessary data into data memory</td>
    </tr>
    <tr>
      <td>3️⃣ <b>Thread Specification</b></td>
      <td>4️⃣ <b>Kernel Launch</b></td>
    </tr>
    <tr>
      <td>Specify total threads via device control register</td>
      <td>Start execution by setting the start signal</td>
    </tr>
  </table>
</div>

The GPU comprises several key units:

<table>
  <tr>
    <td align="center">⚙️ <b>Device Control Register</b></td>
    <td align="center">🔄 <b>Dispatcher</b></td>
    <td align="center">💻 <b>Compute Cores</b></td>
  </tr>
  <tr>
    <td>Stores metadata for thread management</td>
    <td>Groups and distributes threads to cores</td>
    <td>Executes kernel instructions per thread</td>
  </tr>
  <tr>
    <td align="center">💾 <b>Memory Controllers</b></td>
    <td align="center">📦 <b>Cache</b></td>
  </tr>
  <tr>
    <td>Manages access to global memories</td>
    <td>Reduces repeated memory accesses</td>
  </tr>
</table>

## 🚀 Getting Started

### Prerequisites
<div align="center">
  <table>
    <tr>
      <td>🔧 Verilog simulator (e.g., Icarus Verilog)</td>
      <td>📖 Basic understanding of digital design</td>
      <td>💻 Familiarity with assembly programming</td>
    </tr>
  </table>
</div>

### Installation
```bash
# Clone the repository
git clone https://github.com/nirajumaretiya/tinygpu.git
cd tinygpu

# Set up your Verilog environment (Ubuntu/Debian)
sudo apt-get install iverilog
```

### Running Examples
```bash
# Compile the Verilog files
iverilog -o tinygpu_tb tinygpu_tb.v

# Run the simulation
vvp tinygpu_tb
```

## 🤝 Contributing

<div align="center">
  <table>
    <tr>
      <td>1️⃣ Fork the repository</td>
      <td>2️⃣ Create feature branch</td>
      <td>3️⃣ Commit changes</td>
    </tr>
    <tr>
      <td>4️⃣ Push to branch</td>
      <td>5️⃣ Open Pull Request</td>
    </tr>
  </table>
</div>

## 📝 License

<div align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"/>
  <p>This project is licensed under the MIT License - see the <a href="LICENSE">LICENSE</a> file for details.</p>
</div>

## 🙏 Acknowledgments

<div align="center">
  <table>
    <tr>
      <td>👨‍💻 Original project by <a href="https://github.com/adam-maj/tiny-gpu">Adam Majmudar</a></td>
    </tr>
    <tr>
      <td>🤝 All contributors who have helped improve this project</td>
    </tr>
    <tr>
      <td>🌍 The open-source hardware community for their valuable feedback</td>
    </tr>
  </table>
</div>

---

<div align="center">
  <img src="https://komarev.com/ghpvc/?username=nirajumaretiya&color=blueviolet" alt="Profile Views"/>
</div>
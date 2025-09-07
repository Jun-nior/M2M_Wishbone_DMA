# Memory-to-Memory System with DMA and Multi-master Wishbone Interconnect

## Table of Contents
* [Introduction](#intro)
* [Run tests](#test)
* [Architecture](#Architecture)
* [CSRs](#csrs)

## <a name="intro"></a> Introduction

A simple System-on-Chip (SoC) featuring a Memory-to-Memory (M2M) DMA controller within a multi-master Wishbone bus fabric with following features:
- System-Level CPU Access: The host CPU (simulated by the testbench) acts as the primary bus master, with the ability to perform read/write transactions directly to both the main memory (BRAM) and the DMA's Control/Status Registers via the central interconnect.
- DMA `Slave` Interface: The DMA IP provides a Wishbone `Slave` interface to allow the CPU to program its CSRs.
- DMA `Master` Interface: The DMA IP provides a Wishbone `Master` interface to autonomously fetch data from a source address and write it to a destination address in memory.
- Multi-Master Support: The system includes a central interconnect with a fixed-priority arbiter, ensuring the CPU is favorable than the DMA.
- Automated Register Generation: The entire CSR block is generated from a simple YAML specification using [Rggen](https://github.com/rggen/rggen) tool.
- Interrupt Capability: An interrupt can be generated upon completion of a transfer, allowing for efficient, event-driven software interaction.

## <a name="test"></a> Run tests


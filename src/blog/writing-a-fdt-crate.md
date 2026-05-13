---
title: "I wrote my own no-std zerocopy FDT devicetree's crate"
uri: "writing-a-fdt-crate"
date: "2026-05-10"
description: "I wrote a no-std no-alloc FDT devicetree parser in rust for my OS project."
project: "hfdt-rs"
---

The project is called [hfdt-rs](https://github.com/safiworks/hfdt-rs).

# Motivation

I was searching for a no-std zerocopy FDT device tree parser to use at the initial boot stage of my OS that would also provide a high-level enough abstraction API for my needs.

The problem is most of them were exteremly old and unmaintained, as well as missing features.

So I decided to implement my own from scratch anyways, and It turned out quite simple.

# Sources
- The [devicetree specification](https://www.devicetree.org/specifications).

This blog is just a horrible rewrite of some points in the specification, I recommend reading it first, and coming back here if you need more insight.

# Technical Overview

## Base
In memory first the devicetree has the following header:
```rs
#[repr(C)]
pub struct RawHeader {
    magic: u32,
    totalsize: u32,
    off_dt_struct: u32,
    off_dt_strings: u32,
    off_mem_rvsmap: u32,
    version: u32,
    last_comp_version: u32,
    boot_cpuid_phys: u32,
    size_dt_strings: u32,
    size_dt_structs: u32,
}
```
Everything in the devicetree is represented in big endian, the header is supposed to be aligned by `4`.

Next the devicetree is made of the following 3 sections:

### mem_rvsmap
At `off_mem_rvsmap` + `start of device tree`, The section is just made of reserved memory entries:
```rs
#[repr(C)]
pub struct RawMemRvsEntry {
    address: u64,
    size: u64,
}
```
(note: big endian)
The section is `8`-byte aligned.
The section is null-terminated with a `RawMemRvsEntry` that has `address` and `size` both set to `0`.

I'm not yet quite sure what this does, but it isn't that important.

### dt_strings
At `off_dt_strings` + `start of device tree`, This section contains raw strings that is each null-terminated.

Later this section is referenced by the device tree nodes.
This section would mostly likely just contain the property names.

### dt_structs
At `off_dt_structs` + `start of device tree`, This section contains the real deal, the device tree tokens or nodes or whatever you'd call it.

This section is made of tokens + additional data, each token is 4bytes (note big endian) and is aligned by `4`, so any extra bytes are padded with `0`s.
A token may be one of the following:

- `FDT_BEGIN_NODE`: (0x00000001) Starts a node, followed by a null-terminated string name, the name is padded with 0s to align by 4.
- `FDT_END_NODE`: (0x00000002) Ends a node, any `FDT_PROP` tokens in the middle of these 2 are properties of the node, any `FDT_BEGIN_NODE` tokens before this node ends are subnodes of this node.
- `FDT_PROP`: (0x00000003) A property, see below.
- `FDT_NOP`: (0x00000004) is supposed to literally do nothing, it is used to replace parts of the device tree with nothing without changing it's size (possible because everything is 4 byte aligned).
- `FDT_END`: (0x00000009) End of the FDT.

`FDT_PROP` (0x00000003) is followed by the following structure:
```rs
#[repr(C)]
pub struct RawFDTProp {
    name_off: u32,
    len: u32,
}
```
Where `name_off` is the offset into the `dt_strings` section, and `len` is the length of the property value in bytes (doesn't include this struct).

afterwards it is followed by `len` bytes of property value data, and then padded with `0`s to align by `4`.
properties usually share the same name between nodes but each node has it's own unique name, that is why `name_off` is an offset into the `dt_strings` section, but the node's name is not stored in the `dt_strings` section.

and that is it!

# Implementation
I implemented the bare base parsing in the `lib::base` module, it contains the raw struct definitions and a tiny bare parser that emits the following data:
```rs
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
/// Represents a raw FDT token's data.
///
/// Such as a node begin name, property name&value, or end of node/FDT.
pub enum RawFDTTokenData<'a> {
    /// A node's beginning, contains the node's name.
    NodeBegin(&'a str),
    /// A property, contains the property's name and value.
    Prop { name: &'a str, value: &'a [u8] },
    /// A node's end.
    NodeEnd,
    /// The FDT's end.
    FDTEnd,
}

#[derive(Debug, Clone, Copy)]
/// Represents a raw FDT token, including its offset in bytes within the FDT's structures section and data.
pub struct RawFDTToken<'a> {
    pub offset: usize,
    pub data: RawFDTTokenData<'a>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RawFDT<'a> {
    pub version: u32,
    pub mem_rvsmap: &'a [RawMemRvsEntry],
    pub dt_structs_bytes: &'a [u8],
    pub dt_strings_bytes: &'a [u8],
}
```
Which you can use to build your own higher-level FDT parsing logic.

on top of this is a higher-level layer to handle nodes and properties `lib::node`.
Which exposes a `Node` structure, you can iterate over it's subnodes and properties.

## Property Parsing
- A `cell` is a `u32` big-endian value.
- Properties can be concated ex. `<prop> = <0x55> "A string value";` is parsed as a `0x55` cell followed by the string value, this way you can also have a list of strings or other values.
- A `phandle` is a single cell value that references another node in the FDT, kinda like a pointer.

### \#address-cells & \#size-cells
- Defines the number of cells an address or a size takes.
- By definition affects the **children** of the node (that could be subnodes or *child bus*es).
- Mostly used by the `reg` property.
- `#address-cells` defaults to `2`.
- `#size-cells` defaults to `1`.

**NOTE**:
Devices such as the PCIe could use `#address-cells` or `#size-cells` values larger than the amount of cells a `usize` can hold, 

### reg
- A concatenated list of tuples of (address, size) respectively following the `#address-cells` and `#size-cells` properties (of the **parent** node, that is the node containing the node that contains the `reg` property).

(From the specification)

Suppose a device within a system-on-a-chip had two blocks of registers, a 32-byte block at offset 0x3000 in the SOC and a 256-byte block at offset 0xFE00. The reg property would be encoded as follows (assuming `#address-cells` and `#size-cells` values of 1 (**parent** node)):
```
<reg> = <0x3000 0x20 0xFE00 0x100>;
```

### ranges
- The ranges property defines a mapping or translation between the address space of the bus (the child address space) and the address space of the bus node's parent (the parent address space).
- The format of the value of the ranges property is a concatenated list of tuples of `(child-bus-address, parent-bus-address, length)`.
- `child-bus-address` follows the `#address-cells` property of the node that contains the `ranges` property.
- `parent-bus-address` follows the `#address-cells` property of the parent node of the node that contains the `ranges` property.
- `length` follows the `#size-cells` property of the node that contains the `ranges` property.

### An Example

```
pci {
    ...
    #address-cells = <3>;
    #size-cells = <2>;

    // CPU_PHYSICAL(2)  SIZE(2), as the parent node uses #address-cells = 2 and #size-cells = 2, see above for the definition of reg.
    reg = <0x0 0x40000000  0x0 0x1000000>;

    // BUS_ADDRESS(3) (address-cells)  CPU_PHYSICAL(2)  SIZE(2) (size-cells).
    ranges = <0x01000000 0x0 0x01000000  0x0 0x01000000  0x0 0x00010000>,
             <0x02000000 0x0 0x41000000  0x0 0x41000000  0x0 0x3f000000>;
    ...
}
```

### phandle
- Defines the phandle for this node, other nodes can reference this phandle to get a reference to this node.


## Parsing Interrupts
Interrupts are a bit complicated that is why they have their own section.
Read [Properties Parsing](#property-parsing) first.

- An `interrupt-specifier` is a list of cells that specifies the interrupt configuration, it's format is interrupt controller specific.


### interrupt-controller
This is a property that just indicates the node is an interrupt controller.

### interrupt-parent
- A `phandle` reference to the interrupt controller node that this node will use to generate interrupts.
- If not present, the interrupt controller node is assumed to be the parent node.

### \#interrupt-cells
- In an interrupt controller node, this property defines the number of cells an interrupt specifier takes.

### interrupts
- A list of interrupt specifiers (see above) that specify the possible interrupt configuration for this node each made of [`#interrupt-cells`](<#interrupt-cells>) cells as by the [interrupt-parent](<#interrupt-parent>).

### Interrupt Nexus
- An interrupt nexus maps nexus defined (nexus address, interrupts) to another interrupt controller's interrupts, eg. PCI as a nexus to the GIC.
Below is a list of the properties an interrupt nexus uses.

### interrupt-map-mask
- A bitmask that is applied (ANDed) to the nexus's interrupt specifiers to extract the relevant bits to later lookup through the [`interrupt-map`](<#interrupts-map>) table for the corresponding interrupt specifier.

Eg. PCIE would use the mask `interrupt-map-mask = <0xf800 0x00 0x00 0x07>;` each is a cell,
If you had to lookup through an interrupt map for a device where: 
bus number = `0x0`, device number = `0x12`, a function number = `0x3`, and an INTB pin (`0x2`).

You'll have the value `<0x9300 0 0 2>;` as by `(0x0 << 16) | (0x12 << 11) | (0x3 << 8)`, `0`, `0`, `0x2`) where `0x2` is the INTB pin.

Note how 3 cells are used for the address because `#address-cells=<3>;`, I have no idea why.

Later you'd apply the mask to that value and you'd end up with `<0x9000 0 0 2>;`, and then you'd use that value to lookup the corresponding interrupt specifier in the [`interrupt-map`](<#interrupt-map>) table, a complete example would be provided [below](#interrupt-mapping-example).


### interrupt-map
- A list of `(child unit address, child interrupt specifier, interrupt-parent phandle, interrupt-parent unit address, interrupt-parent specifier)`, to map from a child bus in the nexus to an interrupt in an interrupt controller.
- Lookup is done by applying the [`interrupt-map-mask`](<#interrupt-map-mask>) to the child the mask consists of `(child unit address mask, child interrupt specifier mask)`.

### Interrupt Mapping Example

```fdt
soc {
   compatible = "simple-bus";
   #address-cells = <1>;
   #size-cells = <1>;

   open-pic {
      clock-frequency = <0>;
      interrupt-controller;
      #address-cells = <0>;
      #interrupt-cells = <2>;
   };

   pci {
      #interrupt-cells = <1>;
      #size-cells = <2>;
      #address-cells = <3>;
      interrupt-map-mask = <0xf800 0 0 7>;
      interrupt-map = <
         /* IDSEL 0x11 - PCI slot 1 */
         0x8800 0 0 1 &open-pic 2 1 /* INTA */
         0x8800 0 0 2 &open-pic 3 1 /* INTB */
         0x8800 0 0 3 &open-pic 4 1 /* INTC */
         0x8800 0 0 4 &open-pic 1 1 /* INTD */
         /* IDSEL 0x12 - PCI slot 2 */
         0x9000 0 0 1 &open-pic 3 1 /* INTA */
         0x9000 0 0 2 &open-pic 4 1 /* INTB */
         0x9000 0 0 3 &open-pic 1 1 /* INTC */
         0x9000 0 0 4 &open-pic 2 1 /* INTD */
      >;
   };
};
```

`&open-pic` is a phandle to `open-pic`, the phandle property would be generated by the devicetree compiler.

Notice how the unit address after `&open-pic` is omitted out because `#address-cells` is `0`.

PCI is guaranteed to have a `#address-cells` of `3` so writing a driver should be easy although I'm not quite sure what the extra cell represents, and as you can see from the example above the mask masks out 2 of the address cells.

# BIOS images

Here you can keep BIOS images for the emulator. The GUI scans this folder
recursively and groups the images by CPU model (the first-level subfolder name).

```
BIOS/
├── i80148/
│   ├── BIOS.bin
│   ├── CBIOS.bin
│   ├── FBIOS0.3.01.bin
│   └── FBIOS0.3.05.bin
├── i8046/
│   └── ...
└── i148/
    └── ...
```

Rules:

- Only `.bin` files are shown in the **BIOS** tab.
- The subfolder name is the CPU model. Create a folder for every model you
  need (`i80148`, `i8046`, `i148`, `i248`, ...). Nested folders are supported
  (`BIOS/i80148/custom/v1.bin` is shown in the `i80148/custom` group).
- Images in the root of `BIOS/` are shown in the "General" group.
- Files are sorted by model, and the group of the currently selected CPU is
  shown first.

In the emulator, open the **BIOS** tab:

- **Rescan** - re-read the folder after adding or removing files.
- **Load BIOS file...** - load any `.bin` from an arbitrary location.
- **Current CPU only** - hide groups for other CPU models.
- Double-click an image (or select it and press **Load selected BIOS**) to boot it.

The emulator remembers the last selected BIOS, CPU, video card, RAM/VRAM size,
disk images, display settings and CPU speed in `emulator.cfg` next to
`emulator.exe`, and restores them on the next launch.

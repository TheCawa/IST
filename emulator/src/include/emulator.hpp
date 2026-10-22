#pragma once
#include <SDL.h>
#include <vector>
#include "cpu_api.h"
#include "videocard.h"

// Initialize SDL2, Dear ImGui and the selected video card.
bool emulator_init(SDL_Window** out_window, SDL_Renderer** out_renderer, const VideoCard* vc);

// Main rendering loop (screen + registers + menu)
void emulator_render(Cpu* cpu, SDL_Renderer* renderer, std::vector<uint8_t>& memory, std::vector<uint8_t>& vram);

// Switch the active CPU backend and resize/reinit memory/VRAM.
bool emulator_switch_cpu(Cpu* cpu, const CpuBackend* new_backend, std::vector<uint8_t>& memory, std::vector<uint8_t>& vram);

// Switch the active video card (reinitializes renderer resources).
bool emulator_switch_vc(Cpu* cpu, const VideoCard* new_vc, SDL_Renderer* renderer);

// Handle system events and ImGui events
bool emulator_handle_events(Cpu* cpu);

// Set desired RAM/VRAM sizes (used by Reset CPU / CPU switch).
void emulator_set_desired_ram_vram(size_t ram_kb, size_t vram_kb);

// CPU speed modes.
typedef enum {
    CPU_SPEED_ADAPTIVE = 0,   // run as many steps as fit in the frame budget
    CPU_SPEED_FIXED,          // run a fixed number of steps per frame
    CPU_SPEED_UNLIMITED       // run up to max_steps per frame
} CpuSpeedMode;

// CPU control state for the main loop
bool emulator_is_running();
bool emulator_consume_step();

// Input capture state (true when the emulated machine owns keyboard/mouse).
bool emulator_is_input_captured(void);

// CPU speed settings
void emulator_set_speed_mode(CpuSpeedMode mode);
CpuSpeedMode emulator_get_speed_mode(void);
void emulator_set_fixed_steps(int steps);
int  emulator_get_fixed_steps(void);
void emulator_set_max_steps(int steps);
int  emulator_get_max_steps(void);
int  emulator_get_frame_budget_ms(void);

// Report the number of CPU steps executed this frame for the frequency indicator.
void emulator_report_steps(int steps);

// -----------------------------------------------------------------------------
// Persistent configuration (emulator.cfg next to emulator.exe).
//
// The GUI saves the last used machine setup on exit and restores it on the
// next start. Command-line arguments (--cpu/--vc/--bios/--ram/--vram) always
// take precedence over the stored values.
// -----------------------------------------------------------------------------
#define EMU_CONFIG_PATH_MAX 512

typedef struct EmulatorConfig {
    char  cpu[64];                              // CPU backend name, e.g. "i80148"
    char  video_card[64];                       // Video card name ("" = default)
    char  bios_path[EMU_CONFIG_PATH_MAX];       // Last selected BIOS file
    char  disk_paths[DISK_MAX_DRIVES][EMU_CONFIG_PATH_MAX]; // Per-drive disk images
    int   ram_kb;                               // Requested RAM (0 = backend default)
    int   vram_kb;                              // Requested VRAM (0 = backend default)
    int   display_width;                        // Screen panel width in pixels
    int   display_height;                       // Screen panel height in pixels
    float display_scale;                        // Screen zoom
    int   color_depth;                          // 4 = 16 colors, 8 = 256 colors
    int   speed_mode;                           // CpuSpeedMode
    int   fixed_steps;                          // CPU_SPEED_FIXED steps per frame
    int   max_steps;                            // Max steps per frame
    int   frame_budget_ms;                      // Adaptive frame budget
    int   disk_drive;                           // Last selected disk drive index
    bool  valid;                                // A config file was loaded
} EmulatorConfig;

// Fill cfg with the built-in defaults.
void emulator_config_defaults(EmulatorConfig* cfg);

// Load/save the configuration file. Returns false if the file is missing or
// could not be written; cfg still receives defaults on load failure.
bool emulator_config_load(EmulatorConfig* cfg);
bool emulator_config_save(const EmulatorConfig* cfg);

// Apply display/speed-related fields to the running GUI state.
void emulator_apply_config(const EmulatorConfig* cfg);

// Capture the current GUI state + disk paths into cfg.
void emulator_capture_config(EmulatorConfig* cfg, const Cpu* cpu);

// Capture and write the current configuration in one call.
bool emulator_save_current_config(const Cpu* cpu);

// Remember which BIOS is currently loaded (shown in the BIOS tab and saved).
void emulator_set_bios_path(const char* path);

// Properly destroy all contexts
void emulator_shutdown();

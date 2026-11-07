#+private package

package kissfft

import "core:c"

when ODIN_OS == .Windows {
    when ODIN_ARCH == .amd64 {
        LIB_PATH :: "windows_x64/kissfft.lib"
    } else when ODIN_ARCH == .arm64 {
        LIB_PATH :: "windows_arm64/kissfft.lib"
    } else {
        #panic("ext:kissfft supports Windows amd64/arm64 only")
    }
} else when ODIN_OS == .Darwin {
    when ODIN_ARCH == .amd64 {
        LIB_PATH :: "darwin_x64/kissfft.darwin.a"
    } else when ODIN_ARCH == .arm64 {
        LIB_PATH :: "darwin_arm64/kissfft.darwin.a"
    } else {
        #panic("ext:kissfft supports Darwin amd64/arm64 only")
    }
} else when ODIN_OS == .Linux {
    @(require) foreign import _math "system:m"
    when ODIN_ARCH == .amd64 {
        LIB_PATH :: "linux_x64/kissfft.linux.a"
    } else when ODIN_ARCH == .arm64 {
        LIB_PATH :: "linux_arm64/kissfft.linux.a"
    } else {
        #panic("ext:kissfft supports Linux amd64/arm64 only")
    }
} else {
    #panic("ext:kissfft supports Windows, Darwin, and Linux only")
}

foreign import lib {LIB_PATH}

#assert(size_of(c.int) == 4)
#assert(size_of(Complex_F32) == 8)
#assert(align_of(Complex_F32) == align_of(f32))
#assert(size_of(Complex_F64) == 16)
#assert(align_of(Complex_F64) == align_of(f64))

@(default_calling_convention = "c", link_prefix = "catermujo_kissfft_")
foreign lib {
    f32_real_plan_create :: proc(length: c.int, out_plan: ^rawptr) -> c.int ---
    f32_real_plan_destroy :: proc(plan: ^rawptr) ---
    f32_real_transform :: proc(plan: rawptr, input: [^]f32, input_count: c.size_t, output: [^]Complex_F32, output_count: c.size_t) -> c.int ---

    f64_real_plan_create :: proc(length: c.int, out_plan: ^rawptr) -> c.int ---
    f64_real_plan_destroy :: proc(plan: ^rawptr) ---
    f64_real_transform :: proc(plan: rawptr, input: [^]f64, input_count: c.size_t, output: [^]Complex_F64, output_count: c.size_t) -> c.int ---

    f32_plan_create :: proc(length, inverse: c.int, out_plan: ^rawptr) -> c.int ---
    f32_plan_destroy :: proc(plan: ^rawptr) ---
    f32_transform :: proc(plan: rawptr, input: [^]Complex_F32, input_count: c.size_t, output: [^]Complex_F32, output_count: c.size_t) -> c.int ---

    f64_plan_create :: proc(length, inverse: c.int, out_plan: ^rawptr) -> c.int ---
    f64_plan_destroy :: proc(plan: ^rawptr) ---
    f64_transform :: proc(plan: rawptr, input: [^]Complex_F64, input_count: c.size_t, output: [^]Complex_F64, output_count: c.size_t) -> c.int ---
}

#+test

package kissfft

import "core:math"
import "core:testing"

@(test)
real_f32_matches_complex_spectrum :: proc(t: ^testing.T) {
    for length in ([7]int{2, 6, 10, 30, 128, 2048, 4096}) {
        real_plan, error := create_real_f32(length)
        testing.expect_value(t, error, .none)
        defer destroy(&real_plan)
        complex_plan, complex_error := create_f32(length, .forward)
        testing.expect_value(t, complex_error, .none)
        defer destroy(&complex_plan)
        samples := make([]f32, length)
        complex_input := make([]Complex_F32, length)
        real_output := make([]Complex_F32, length / 2 + 1)
        complex_output := make([]Complex_F32, length)
        defer delete(samples)
        defer delete(complex_input)
        defer delete(real_output)
        defer delete(complex_output)
        for &sample, i in samples {
            phase := f32(i) / f32(length)
            sample = .3 + .5 * math.sin(f32(math.TAU) * 3 * phase) + .1 * math.cos(f32(math.TAU) * 11 * phase)
            sample += .15 if i % 2 == 0 else -.15
            complex_input[i].real = sample
        }
        testing.expect_value(t, transform_real(&real_plan, samples, real_output), .none)
        testing.expect_value(t, transform(&complex_plan, complex_input, complex_output), .none)
        for value, bin in real_output {
            reference := complex_output[bin]
            tolerance := f32(2e-6) * f32(length)
            testing.expectf(t, abs(value.real - reference.real) < tolerance, "length %d, bin %d real", length, bin)
            testing.expectf(t, abs(value.imag - reference.imag) < tolerance, "length %d, bin %d imag", length, bin)
        }
        testing.expect_value(t, real_output[0].imag, 0)
        testing.expect_value(t, real_output[length / 2].imag, 0)
    }
}

@(test)
real_f64_impulse_and_tone :: proc(t: ^testing.T) {
    for length in ([4]int{2, 6, 10, 2048}) {
        plan, error := create_real_f64(length)
        testing.expect_value(t, error, .none)
        defer destroy(&plan)
        input := make([]f64, length)
        output := make([]Complex_F64, length / 2 + 1)
        defer delete(input)
        defer delete(output)
        input[0] = 1
        testing.expect_value(t, transform_real(&plan, input, output), .none)
        for value in output {
            testing.expect(t, abs(value.real - 1) < 1e-12)
            testing.expect(t, abs(value.imag) < 1e-12)
        }
        for &sample, i in input do sample = math.cos(math.TAU * f64(i) / f64(length))
        testing.expect_value(t, transform_real(&plan, input, output), .none)
        expected := f64(length) if length == 2 else f64(length) / 2
        testing.expect(t, abs(output[1].real - expected) < 1e-10)
        testing.expect(t, abs(output[1].imag) < 1e-10)
    }
}

@(test)
real_plan_validates_sizes_and_overlap :: proc(t: ^testing.T) {
    for length in ([4]int{-1, 0, 1, 3}) {
        plan, error := create_real_f32(length)
        testing.expect_value(t, error, .invalid_length)
        testing.expect_value(t, plan.handle, nil)
    }
    unsupported, unsupported_error := create_real_f32(14)
    testing.expect_value(t, unsupported_error, .unsupported_length)
    testing.expect_value(t, unsupported.handle, nil)
    plan, error := create_real_f32(8)
    testing.expect_value(t, error, .none)
    input: [8]f32
    output: [5]Complex_F32
    testing.expect_value(t, transform_real(&plan, input[:7], output[:]), .input_length_mismatch)
    testing.expect_value(t, transform_real(&plan, input[:], output[:4]), .output_length_mismatch)
    shared: [10]f32
    // Deliberately alias the two ABI buffers to check the native range validation.
    aliased := (cast([^]Complex_F32)raw_data(shared[:]))[:5]
    testing.expect_value(t, transform_real(&plan, shared[:8], aliased), .overlapping_buffers)
    destroy(&plan)
    destroy(&plan)
    testing.expect_value(t, transform_real(&plan, input[:], output[:]), .invalid_plan)
}

@(test)
real_native_boundary :: proc(t: ^testing.T) {
    testing.expect_value(t, Error(f32_real_plan_create(8, nil)), .invalid_plan)
    handle: rawptr
    testing.expect_value(t, Error(f32_real_plan_create(3, &handle)), .invalid_length)
    testing.expect_value(t, handle, nil)
    testing.expect_value(t, Error(f32_real_plan_create(14, &handle)), .unsupported_length)
    testing.expect_value(t, handle, nil)
    testing.expect_value(t, Error(f32_real_plan_create(8, &handle)), .none)
    defer f32_real_plan_destroy(&handle)
    input: [8]f32
    output: [5]Complex_F32
    testing.expect_value(
        t,
        Error(f32_real_transform(nil, raw_data(input[:]), 8, raw_data(output[:]), 5)),
        .invalid_plan,
    )
    testing.expect_value(
        t,
        Error(f32_real_transform(handle, raw_data(input[:]), 7, raw_data(output[:]), 5)),
        .input_length_mismatch,
    )
    testing.expect_value(
        t,
        Error(f32_real_transform(handle, raw_data(input[:]), 8, raw_data(output[:]), 4)),
        .output_length_mismatch,
    )
    testing.expect_value(t, Error(f32_real_transform(handle, nil, 8, raw_data(output[:]), 5)), .invalid_plan)
    testing.expect_value(t, Error(f32_real_transform(handle, raw_data(input[:]), 8, nil, 5)), .invalid_plan)
    shared: [18]f32
    input_before := shared[:8]
    output_after := (cast([^]Complex_F32)raw_data(shared[8:]))[:5]
    testing.expect_value(
        t,
        Error(f32_real_transform(handle, raw_data(input_before), 8, raw_data(output_after), 5)),
        .none,
    )
    output_before := (cast([^]Complex_F32)raw_data(shared[:]))[:5]
    input_after := shared[10:]
    testing.expect_value(
        t,
        Error(f32_real_transform(handle, raw_data(input_after), 8, raw_data(output_before), 5)),
        .none,
    )
    partial_overlap := (cast([^]Complex_F32)raw_data(shared[7:]))[:5]
    testing.expect_value(
        t,
        Error(f32_real_transform(handle, raw_data(input_before), 8, raw_data(partial_overlap), 5)),
        .overlapping_buffers,
    )
    f32_real_plan_destroy(nil)
    f32_real_plan_destroy(&handle)
    testing.expect_value(t, handle, nil)
    double_handle: rawptr
    testing.expect_value(t, Error(f64_real_plan_create(8, &double_handle)), .none)
    testing.expect_value(t, Error(f64_real_transform(double_handle, nil, 8, nil, 5)), .invalid_plan)
    f64_real_plan_destroy(&double_handle)
    testing.expect_value(t, double_handle, nil)
}

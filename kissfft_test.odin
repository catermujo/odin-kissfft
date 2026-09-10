#+test

package kissfft

import "core:math"
import "core:testing"

@(test)
f32_impulse_transform :: proc(t: ^testing.T) {
    plan, err := create_f32(8, .forward)
    testing.expect_value(t, err, Error.none)
    defer destroy(&plan)

    input: [8]Complex_F32
    output: [8]Complex_F32
    input[0].real = 1
    testing.expect_value(t, transform(&plan, input[:], output[:]), Error.none)
    for value in output {
        testing.expect(t, math.abs(value.real - 1) < 1e-6)
        testing.expect(t, math.abs(value.imag) < 1e-6)
    }
}

@(test)
f64_round_trip :: proc(t: ^testing.T) {
    forward, forward_err := create_f64(6, .forward)
    testing.expect_value(t, forward_err, Error.none)
    defer destroy(&forward)
    inverse, inverse_err := create_f64(6, .inverse)
    testing.expect_value(t, inverse_err, Error.none)
    defer destroy(&inverse)

    input := [6]Complex_F64{{real = 1}, {real = 2}, {real = 3}, {real = 4}, {real = 5}, {real = 6}}
    frequency: [6]Complex_F64
    restored: [6]Complex_F64
    testing.expect_value(t, transform(&forward, input[:], frequency[:]), Error.none)
    testing.expect_value(t, transform(&inverse, frequency[:], restored[:]), Error.none)
    for value, index in restored {
        testing.expect(t, math.abs(value.real / 6 - input[index].real) < 1e-12)
        testing.expect(t, math.abs(value.imag / 6) < 1e-12)
    }
}

@(test)
validation_and_destroy_are_safe :: proc(t: ^testing.T) {
    unsupported, unsupported_err := create_f32(7, .forward)
    testing.expect_value(t, unsupported_err, Error.unsupported_length)
    testing.expect(t, unsupported.handle == nil)
    invalid, invalid_err := create_f32(4, Direction(99))
    testing.expect_value(t, invalid_err, Error.invalid_direction)
    testing.expect(t, invalid.handle == nil)

    plan, err := create_f32(4, .forward)
    testing.expect_value(t, err, Error.none)
    values: [4]Complex_F32
    testing.expect_value(t, transform(&plan, values[:3], values[:]), Error.input_length_mismatch)
    testing.expect_value(t, transform(&plan, values[:], values[:]), Error.overlapping_buffers)
    destroy(&plan)
    destroy(&plan)
    testing.expect_value(t, transform(&plan, values[:], values[:]), Error.invalid_plan)
}

package kissfft

import "core:c"

Complex_F32 :: struct {
    real: f32,
    imag: f32,
}

Complex_F64 :: struct {
    real: f64,
    imag: f64,
}

Direction :: enum u8 {
    forward,
    inverse,
}

Error :: enum u8 {
    none,
    invalid_length,
    invalid_direction,
    unsupported_length,
    allocation_failed,
    invalid_plan,
    input_length_mismatch,
    output_length_mismatch,
    overlapping_buffers,
}

Plan_F32 :: struct {
    handle:    rawptr,
    length:    int,
    direction: Direction,
}

Plan_F64 :: struct {
    handle:    rawptr,
    length:    int,
    direction: Direction,
}

create_f32 :: proc(length: int, direction: Direction) -> (plan: Plan_F32, err: Error) {
    if length < 2 || length > int(max(c.int)) {
        return {}, .invalid_length
    }
    if direction != .forward && direction != .inverse {
        return {}, .invalid_direction
    }
    status := Error(f32_plan_create(c.int(length), c.int(direction), &plan.handle))
    if status != .none {
        return {}, status
    }
    plan.length = length
    plan.direction = direction
    return plan, .none
}

create_f64 :: proc(length: int, direction: Direction) -> (plan: Plan_F64, err: Error) {
    if length < 2 || length > int(max(c.int)) {
        return {}, .invalid_length
    }
    if direction != .forward && direction != .inverse {
        return {}, .invalid_direction
    }
    status := Error(f64_plan_create(c.int(length), c.int(direction), &plan.handle))
    if status != .none {
        return {}, status
    }
    plan.length = length
    plan.direction = direction
    return plan, .none
}

destroy_f32 :: proc(plan: ^Plan_F32) {
    if plan == nil {
        return
    }
    f32_plan_destroy(&plan.handle)
    plan^ = {}
}

destroy_f64 :: proc(plan: ^Plan_F64) {
    if plan == nil {
        return
    }
    f64_plan_destroy(&plan.handle)
    plan^ = {}
}

transform_f32 :: proc(plan: ^Plan_F32, input, output: []Complex_F32) -> Error {
    if plan == nil || plan.handle == nil {
        return .invalid_plan
    }
    if len(input) != plan.length {
        return .input_length_mismatch
    }
    if len(output) != plan.length {
        return .output_length_mismatch
    }
    return Error(f32_transform(
        plan.handle,
        raw_data(input),
        c.size_t(len(input)),
        raw_data(output),
        c.size_t(len(output)),
    ))
}

transform_f64 :: proc(plan: ^Plan_F64, input, output: []Complex_F64) -> Error {
    if plan == nil || plan.handle == nil {
        return .invalid_plan
    }
    if len(input) != plan.length {
        return .input_length_mismatch
    }
    if len(output) != plan.length {
        return .output_length_mismatch
    }
    return Error(f64_transform(
        plan.handle,
        raw_data(input),
        c.size_t(len(input)),
        raw_data(output),
        c.size_t(len(output)),
    ))
}

destroy :: proc{destroy_f32, destroy_f64}
transform :: proc{transform_f32, transform_f64}

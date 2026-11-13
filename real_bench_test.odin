#+test
#+when BENCH

package kissfft

import "core:fmt"
import "core:math"
import "core:testing"
import "core:time"

@(test)
benchmark_real_and_complex_2048 :: proc(t: ^testing.T) {
    LENGTH :: 2048
    ROUNDS :: 10000
    BATCHES :: 6
    complex_plan, complex_error := create_f32(LENGTH, .forward)
    testing.expect_value(t, complex_error, .none)
    defer destroy(&complex_plan)
    real_plan, real_error := create_real_f32(LENGTH)
    testing.expect_value(t, real_error, .none)
    defer destroy(&real_plan)
    input: [LENGTH]f32
    complex_input, complex_output: [LENGTH]Complex_F32
    real_output: [LENGTH / 2 + 1]Complex_F32
    for &sample, i in input {
        sample = .4 * math.sin(f32(i) * .12) + .2 * math.cos(f32(i) * .47)
        complex_input[i].real = sample
    }
    for _ in 0 ..< 1000 {
        testing.expect_value(t, transform(&complex_plan, complex_input[:], complex_output[:]), .none)
        testing.expect_value(t, transform_real(&real_plan, input[:], real_output[:]), .none)
    }
    elapsed: [2]time.Duration
    failures := 0
    for batch in 0 ..< BATCHES {
        // Alternate order after warmup so neither path always inherits the hotter CPU and cache.
        for position in 0 ..< 2 {
            path := (batch + position) % 2
            start := time.tick_now()
            if path == 0 {
                for _ in 0 ..< ROUNDS {
                    failures += int(transform(&complex_plan, complex_input[:], complex_output[:]) != .none)
                }
            } else {
                for _ in 0 ..< ROUNDS {
                    failures += int(transform_real(&real_plan, input[:], real_output[:]) != .none)
                }
            }
            elapsed[path] += time.tick_since(start)
        }
    }
    testing.expect_value(t, failures, 0)
    testing.expect(t, abs(real_output[39].real - complex_output[39].real) < .001)
    fmt.printf(
        "2048 f32, %d transforms/path: complex %v/transform, real %v/transform, speedup %.3fx\n",
        ROUNDS * BATCHES,
        elapsed[0] / (ROUNDS * BATCHES),
        elapsed[1] / (ROUNDS * BATCHES),
        f64(elapsed[0]) / f64(elapsed[1]),
    )
}

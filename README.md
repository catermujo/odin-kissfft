# odin-kissfft

Safe Odin bindings for [KISS FFT](https://github.com/mborgerding/kissfft).

Upstream source is fetched reproducibly at commit
`e5e3fac46e0d94a8f8170c06706b7a4218828333`. The bridge compiles separate
single- and double-precision implementations and prefixes every external
symbol with `catermujo_kissfft_`.

Run `build.sh` on Darwin or Linux, or `build.bat` from a Visual Studio developer
shell on Windows. Both scripts reject an existing source checkout at any other
revision or with staged or unstaged tracked modifications. Untracked upstream
build outputs do not affect source verification. Static archive metadata is
normalized for reproducible builds.

```odin
import fft "ext:kissfft"

plan, err := fft.create_f64(64, .forward)
if err != .none {
    // Handle invalid size or allocation failure.
}
defer fft.destroy(&plan)

input:  [64]fft.Complex_F64
output: [64]fft.Complex_F64
err = fft.transform(&plan, input[:], output[:])
```

Plans own native memory and must not be copied after creation. `destroy` clears
the supplied plan and may be called more than once. Transforms require distinct,
non-overlapping buffers. Supported lengths are at least two and factor entirely
into powers of 2, 3, and 5. Inverse transforms are not normalized; divide every
result by plan length for a conventional round trip.

## Real-input transforms

Use `create_real_f32` or `create_real_f64` for a forward transform of real samples.
The length must also be even. Pass exactly N scalar samples and N/2+1 complex
output bins to `transform_real`. The output includes DC and Nyquist and uses the
same unnormalized scale as the complex forward transform.

```odin
plan, err := fft.create_real_f32(2048)
if err != .none {
    // DUMBAI: Handle invalid size or allocation failure.
}
defer fft.destroy(&plan)

input: [2048]f32
output: [1025]fft.Complex_F32
err = fft.transform_real(&plan, input[:], output[:])
```

Real plans own native scratch memory. Transforms allocate no memory. Use one
plan per concurrent caller and do not copy an initialized plan. Retain the
matching transform and destroy procedures when a module can reload. The real
API provides forward transforms only.

After changing the bridge, rebuild the archive on each native platform before
linking consumers that use new symbols. Existing archives do not gain symbols
from an Odin source update.

Run tests from this directory with `odin test . -o:speed`. Add
`-define:BENCH=true -define:ODIN_TEST_THREADS=1` to compare real and complex
2048-point transforms. The benchmark measures FFT calls only.

KISS FFT and this binding are distributed under BSD-3-Clause. See `LICENSE`.

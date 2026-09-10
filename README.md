# odin-kissfft

Safe Odin bindings for [KISS FFT](https://github.com/mborgerding/kissfft).

Upstream source is fetched reproducibly at commit
`e5e3fac46e0d94a8f8170c06706b7a4218828333`. The bridge compiles separate
single- and double-precision implementations and prefixes every external
symbol with `catermujo_kissfft_`.

Run `build.sh` on Darwin or Linux, or `build.bat` from a Visual Studio developer
shell on Windows. Both scripts reject an existing source checkout at any other
revision.

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

KISS FFT and this binding are distributed under BSD-3-Clause. See `LICENSE`.

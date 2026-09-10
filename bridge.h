#ifndef CATERMUJO_KISSFFT_BRIDGE_H
#define CATERMUJO_KISSFFT_BRIDGE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    float real;
    float imag;
} catermujo_kissfft_complex_f32;

typedef struct {
    double real;
    double imag;
} catermujo_kissfft_complex_f64;

enum catermujo_kissfft_status {
    CATERMUJO_KISSFFT_OK = 0,
    CATERMUJO_KISSFFT_INVALID_LENGTH = 1,
    CATERMUJO_KISSFFT_INVALID_DIRECTION = 2,
    CATERMUJO_KISSFFT_UNSUPPORTED_LENGTH = 3,
    CATERMUJO_KISSFFT_ALLOCATION_FAILED = 4,
    CATERMUJO_KISSFFT_INVALID_PLAN = 5,
    CATERMUJO_KISSFFT_INPUT_LENGTH_MISMATCH = 6,
    CATERMUJO_KISSFFT_OUTPUT_LENGTH_MISMATCH = 7,
    CATERMUJO_KISSFFT_OVERLAPPING_BUFFERS = 8,
};

int32_t catermujo_kissfft_f32_plan_create(int32_t length, int32_t inverse, void **out_plan);
void catermujo_kissfft_f32_plan_destroy(void **plan);
int32_t catermujo_kissfft_f32_transform(
    void *plan,
    const catermujo_kissfft_complex_f32 *input,
    size_t input_count,
    catermujo_kissfft_complex_f32 *output,
    size_t output_count
);

int32_t catermujo_kissfft_f64_plan_create(int32_t length, int32_t inverse, void **out_plan);
void catermujo_kissfft_f64_plan_destroy(void **plan);
int32_t catermujo_kissfft_f64_transform(
    void *plan,
    const catermujo_kissfft_complex_f64 *input,
    size_t input_count,
    catermujo_kissfft_complex_f64 *output,
    size_t output_count
);

#ifdef __cplusplus
}
#endif

#endif

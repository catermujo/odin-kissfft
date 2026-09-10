#include "bridge.h"

#include <stdlib.h>

#ifndef CATERMUJO_KISSFFT_SCALAR
#error "CATERMUJO_KISSFFT_SCALAR is required"
#endif

#ifndef CATERMUJO_KISSFFT_COMPLEX
#error "CATERMUJO_KISSFFT_COMPLEX is required"
#endif

#ifndef CATERMUJO_KISSFFT_NAME
#error "CATERMUJO_KISSFFT_NAME is required"
#endif

#define CATERMUJO_KISSFFT_JOIN_INNER(a, b) a##b
#define CATERMUJO_KISSFFT_JOIN(a, b) CATERMUJO_KISSFFT_JOIN_INNER(a, b)
#define CATERMUJO_KISSFFT_SYMBOL(suffix) CATERMUJO_KISSFFT_JOIN(CATERMUJO_KISSFFT_NAME, suffix)

#define kiss_fft_scalar CATERMUJO_KISSFFT_SCALAR
#define kiss_fft_alloc CATERMUJO_KISSFFT_SYMBOL(_core_alloc)
#define kiss_fft CATERMUJO_KISSFFT_SYMBOL(_core_transform)
#define kiss_fft_stride CATERMUJO_KISSFFT_SYMBOL(_core_transform_stride)
#define kiss_fft_cleanup CATERMUJO_KISSFFT_SYMBOL(_core_cleanup)
#define kiss_fft_next_fast_size CATERMUJO_KISSFFT_SYMBOL(_core_next_fast_size)
#if defined(__clang__) || defined(__GNUC__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wsign-compare"
#endif
#include "kissfft/kiss_fft.c"
#if defined(__clang__) || defined(__GNUC__)
#pragma GCC diagnostic pop
#endif

typedef struct {
    kiss_fft_cfg configuration;
    int32_t length;
} CATERMUJO_KISSFFT_SYMBOL(_plan);

_Static_assert(sizeof(kiss_fft_cpx) == sizeof(CATERMUJO_KISSFFT_COMPLEX), "complex ABI size mismatch");
_Static_assert(_Alignof(kiss_fft_cpx) == _Alignof(CATERMUJO_KISSFFT_COMPLEX), "complex ABI alignment mismatch");

static int CATERMUJO_KISSFFT_SYMBOL(_length_is_supported)(int32_t length) {
    if (length < 2) {
        return 0;
    }
    while ((length % 2) == 0) {
        length /= 2;
    }
    while ((length % 3) == 0) {
        length /= 3;
    }
    while ((length % 5) == 0) {
        length /= 5;
    }
    return length == 1;
}

static int CATERMUJO_KISSFFT_SYMBOL(_buffers_overlap)(
    const CATERMUJO_KISSFFT_COMPLEX *input,
    CATERMUJO_KISSFFT_COMPLEX *output,
    size_t count
) {
    uintptr_t input_begin = (uintptr_t)input;
    uintptr_t input_end = input_begin + count * sizeof(*input);
    uintptr_t output_begin = (uintptr_t)output;
    uintptr_t output_end = output_begin + count * sizeof(*output);
    return input_begin < output_end && output_begin < input_end;
}

int32_t CATERMUJO_KISSFFT_SYMBOL(_plan_create)(int32_t length, int32_t inverse, void **out_plan) {
    if (out_plan == NULL) {
        return CATERMUJO_KISSFFT_INVALID_PLAN;
    }
    *out_plan = NULL;
    if (length < 2) {
        return CATERMUJO_KISSFFT_INVALID_LENGTH;
    }
    if (inverse != 0 && inverse != 1) {
        return CATERMUJO_KISSFFT_INVALID_DIRECTION;
    }
    if (!CATERMUJO_KISSFFT_SYMBOL(_length_is_supported)(length)) {
        return CATERMUJO_KISSFFT_UNSUPPORTED_LENGTH;
    }

    CATERMUJO_KISSFFT_SYMBOL(_plan) *plan = malloc(sizeof(*plan));
    if (plan == NULL) {
        return CATERMUJO_KISSFFT_ALLOCATION_FAILED;
    }
    plan->configuration = CATERMUJO_KISSFFT_SYMBOL(_core_alloc)(length, inverse, NULL, NULL);
    if (plan->configuration == NULL) {
        free(plan);
        return CATERMUJO_KISSFFT_ALLOCATION_FAILED;
    }
    plan->length = length;
    *out_plan = plan;
    return CATERMUJO_KISSFFT_OK;
}

void CATERMUJO_KISSFFT_SYMBOL(_plan_destroy)(void **opaque_plan) {
    if (opaque_plan == NULL || *opaque_plan == NULL) {
        return;
    }
    CATERMUJO_KISSFFT_SYMBOL(_plan) *plan = *opaque_plan;
    free(plan->configuration);
    plan->configuration = NULL;
    plan->length = 0;
    free(plan);
    *opaque_plan = NULL;
}

int32_t CATERMUJO_KISSFFT_SYMBOL(_transform)(
    void *opaque_plan,
    const CATERMUJO_KISSFFT_COMPLEX *input,
    size_t input_count,
    CATERMUJO_KISSFFT_COMPLEX *output,
    size_t output_count
) {
    if (opaque_plan == NULL) {
        return CATERMUJO_KISSFFT_INVALID_PLAN;
    }
    CATERMUJO_KISSFFT_SYMBOL(_plan) *plan = opaque_plan;
    if (input_count != (size_t)plan->length) {
        return CATERMUJO_KISSFFT_INPUT_LENGTH_MISMATCH;
    }
    if (output_count != (size_t)plan->length) {
        return CATERMUJO_KISSFFT_OUTPUT_LENGTH_MISMATCH;
    }
    if (input == NULL || output == NULL) {
        return CATERMUJO_KISSFFT_INVALID_PLAN;
    }
    if (CATERMUJO_KISSFFT_SYMBOL(_buffers_overlap)(input, output, input_count)) {
        return CATERMUJO_KISSFFT_OVERLAPPING_BUFFERS;
    }
    CATERMUJO_KISSFFT_SYMBOL(_core_transform)(
        plan->configuration,
        (const kiss_fft_cpx *)input,
        (kiss_fft_cpx *)output
    );
    return CATERMUJO_KISSFFT_OK;
}

//===-- lib/quadmath/spacing.cpp --------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "math-entries.h"
#include "numeric-template-specs.h"

namespace Fortran::runtime {
extern "C" {

#if HAS_LDBL128 || HAS_FLOAT128
// SPACING (16.9.180)
F128Type RTDEF(Spacing16)(F128Type x) { return Spacing<113>(x); }
#endif

} // extern "C"
} // namespace Fortran::runtime

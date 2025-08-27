; ModuleID = 'probe6.ad357297f34f1129-cgu.0'
source_filename = "probe6.ad357297f34f1129-cgu.0"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx11.0.0"

@alloc_7971f3465817cc18ad816e3dbdd7087a = private unnamed_addr constant [7 x i8] c"<anon>\00", align 1
@alloc_b9b30cce65897495d8b789b323503a84 = private unnamed_addr constant <{ ptr, [16 x i8] }> <{ ptr @alloc_7971f3465817cc18ad816e3dbdd7087a, [16 x i8] c"\07\00\00\00\00\00\00\00\01\00\00\00\1F\00\00\00" }>, align 8

; probe6::probe
; Function Attrs: uwtable
define void @_ZN6probe65probe17h189d29e616133cc3E() unnamed_addr #0 {
start:
  ret void
}

; core::panicking::panic_const::panic_const_div_by_zero
; Function Attrs: cold noinline noreturn uwtable
declare void @_ZN4core9panicking11panic_const23panic_const_div_by_zero17h30ab0fbdfc40f8d1E(ptr align 8) unnamed_addr #1

attributes #0 = { uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #1 = { cold noinline noreturn uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 8, !"PIC Level", i32 2}
!1 = !{!"rustc version 1.89.0 (29483883e 2025-08-04) (Homebrew)"}

; ModuleID = 'probe5.61899ebbcef8bee1-cgu.0'
source_filename = "probe5.61899ebbcef8bee1-cgu.0"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx11.0.0"

@alloc_2e38410fced2c310c68bdf2d45d0c3bd = private unnamed_addr constant [4 x i8] c"\02\00\00\00", align 4
@alloc_7971f3465817cc18ad816e3dbdd7087a = private unnamed_addr constant [7 x i8] c"<anon>\00", align 1
@alloc_f70a73aebd44b078dd19b7ed404007db = private unnamed_addr constant <{ ptr, [16 x i8] }> <{ ptr @alloc_7971f3465817cc18ad816e3dbdd7087a, [16 x i8] c"\07\00\00\00\00\00\00\00\01\00\00\00+\00\00\00" }>, align 8

; <i32 as core::ops::arith::AddAssign<&i32>>::add_assign
; Function Attrs: inlinehint uwtable
define internal void @"_ZN66_$LT$i32$u20$as$u20$core..ops..arith..AddAssign$LT$$RF$i32$GT$$GT$10add_assign17h8307b95d5e0572a0E"(ptr align 4 %self, ptr align 4 %other, ptr align 8 %0) unnamed_addr #0 {
start:
  %other1 = load i32, ptr %other, align 4
  %1 = load i32, ptr %self, align 4
  %2 = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %1, i32 %other1)
  %_4.0 = extractvalue { i32, i1 } %2, 0
  %_4.1 = extractvalue { i32, i1 } %2, 1
  br i1 %_4.1, label %panic, label %bb1

bb1:                                              ; preds = %start
  store i32 %_4.0, ptr %self, align 4
  ret void

panic:                                            ; preds = %start
; call core::panicking::panic_const::panic_const_add_overflow
  call void @_ZN4core9panicking11panic_const24panic_const_add_overflow17h949f4c3ca8a38a2cE(ptr align 8 %0) #4
  unreachable
}

; probe5::probe
; Function Attrs: uwtable
define void @_ZN6probe55probe17h937e1844cb7cfeeaE() unnamed_addr #1 {
start:
  %x = alloca [4 x i8], align 4
  store i32 1, ptr %x, align 4
; call <i32 as core::ops::arith::AddAssign<&i32>>::add_assign
  call void @"_ZN66_$LT$i32$u20$as$u20$core..ops..arith..AddAssign$LT$$RF$i32$GT$$GT$10add_assign17h8307b95d5e0572a0E"(ptr align 4 %x, ptr align 4 @alloc_2e38410fced2c310c68bdf2d45d0c3bd, ptr align 8 @alloc_f70a73aebd44b078dd19b7ed404007db)
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32) #2

; core::panicking::panic_const::panic_const_add_overflow
; Function Attrs: cold noinline noreturn uwtable
declare void @_ZN4core9panicking11panic_const24panic_const_add_overflow17h949f4c3ca8a38a2cE(ptr align 8) unnamed_addr #3

attributes #0 = { inlinehint uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #1 = { uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { cold noinline noreturn uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #4 = { noreturn }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 8, !"PIC Level", i32 2}
!1 = !{!"rustc version 1.89.0 (29483883e 2025-08-04) (Homebrew)"}

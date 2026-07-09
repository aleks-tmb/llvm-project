; RUN: opt -passes='print<scalar-evolution>' -disable-output -scalar-evolution-propagate-guards-through-zext-add=false %s 2>&1 | FileCheck %s --check-prefixes=CHECK,OFF
; RUN: opt -passes='print<scalar-evolution>' -disable-output -scalar-evolution-propagate-guards-through-zext-add=true %s 2>&1 | FileCheck %s --check-prefixes=CHECK,ON

; Loop-guard decomposition of  zext(C + Y) >u K  into a tighter lower
; bound on Y, observed as a smaller constant max backedge-taken count.

;     if (L < 5 && L > 0 && zext(L-1) > 1) {
;       i = 0;
;       do { ++i; } while (i != 5-L);
;     }
define void @propagate_umin_zext_nsw_add(i32 %L) {
; CHECK-LABEL: 'propagate_umin_zext_nsw_add'
; OFF: Loop %loop: constant max backedge-taken count is i32 3
; ON:  Loop %loop: constant max backedge-taken count is i32 1
entry:
  %ub = icmp ult i32 %L, 5
  %lb.not = icmp ugt i32 %L, 0
  %and = and i1 %ub, %lb.not
  br i1 %and, label %step, label %exit

step:
  %sl = add nsw i32 %L, -1
  %exit64 = zext i32 %sl to i64
  %tc = sub nsw i32 5, %L
  %cmp = icmp ugt i64 %exit64, 1
  br i1 %cmp, label %loop, label %exit

loop:
  %iv = phi i32 [ 0, %step ], [ %iv.next, %loop ]
  %iv.next = add nuw nsw i32 %iv, 1
  %ec = icmp eq i32 %iv.next, %tc
  br i1 %ec, label %exit, label %loop

exit:
  ret void
}


;     if (Y < 5 && zext(Y+4) > 6) {
;       i = 0;
;       do { ++i; } while (i != 5-Y);
;     }
; Non-negative C=4 needs no prior lower bound on Y.
define void @propagate_umin_zext_nsw_add_positive_c(i32 %Y) {
; CHECK-LABEL: 'propagate_umin_zext_nsw_add_positive_c'
; OFF: Loop %loop: constant max backedge-taken count is i32 4
; ON:  Loop %loop: constant max backedge-taken count is i32 1
entry:
  %ub = icmp ult i32 %Y, 5
  br i1 %ub, label %step, label %exit

step:
  %ay = add nsw i32 %Y, 4
  %eay = zext i32 %ay to i64
  %tc = sub i32 5, %Y
  %cmp = icmp ugt i64 %eay, 6
  br i1 %cmp, label %loop, label %exit

loop:
  %iv = phi i32 [ 0, %step ], [ %iv.next, %loop ]
  %iv.next = add nuw nsw i32 %iv, 1
  %ec = icmp eq i32 %iv.next, %tc
  br i1 %ec, label %exit, label %loop

exit:
  ret void
}

;     if (L < 5 && zext(L-1) > 1) {
;       i = 0;
;       do { ++i; } while (i != 5-L);
;     }
; No dominating  L > 0  branch: C = -1 is negative and there is no prior
;  L >= |C|  fact, so decomposition MUST NOT fire.
define void @no_decomp_when_no_prior_lb(i32 %L) {
; CHECK-LABEL: 'no_decomp_when_no_prior_lb'
; OFF: Loop %loop: constant max backedge-taken count is i32 4
; ON:  Loop %loop: constant max backedge-taken count is i32 4
entry:
  %ub = icmp ult i32 %L, 5
  br i1 %ub, label %step, label %exit

step:
  %sl = add nsw i32 %L, -1
  %exit64 = zext i32 %sl to i64
  %tc = sub nsw i32 5, %L
  %cmp = icmp ugt i64 %exit64, 1
  br i1 %cmp, label %loop, label %exit

loop:
  %iv = phi i32 [ 0, %step ], [ %iv.next, %loop ]
  %iv.next = add nuw nsw i32 %iv, 1
  %ec = icmp eq i32 %iv.next, %tc
  br i1 %ec, label %exit, label %loop

exit:
  ret void
}

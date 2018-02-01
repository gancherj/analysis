(* mathcomp analysis (c) 2017 Inria and AIST. License: CeCILL-C.              *)
Require Import Reals.
From Coq Require Import ssreflect ssrfun ssrbool.
From mathcomp Require Import ssrnat eqtype choice ssralg ssrnum.
From SsrReals Require Import boolp reals.
Require Import Rstruct Rbar set posnum topology hierarchy.

(******************************************************************************)
(*              BACHMANN-LANDAU NOTATIONS : BIG AND LITTLE O                  *)
(******************************************************************************)
(******************************************************************************)
(* F is a filter, K is an absRingType and V W X Y Z are normed spaces over K  *)
(* alternatively, K can be equal to the reals R (from the standard library    *)
(* for now)                                                                   *)
(* This libary is very assymetric, in multiple respects:                      *)
(* - most rewrite rules can only be rewritten from left to right.             *)
(*   e.g. an equation 'o_F f = 'O_G g can be used only from LEFT TO RIGHT     *)
(* - conversely most small 'o_F f in your goal are very specific,             *)
(*     only 'a_F f is mutable                                                 *)
(*                                                                            *)
(* - most notations are either parse only or print only.                      *)
(*   Indeed all the 'O_F notations contain a function which is NOT displayed. *)
(*   This might be confusing as sometimes you might get 'O_F g = 'O_F g       *)
(*   and not be able to solve by reflexivity.                                 *)
(*   - In order to have a look at the hidden function, rewrite showo.         *)
(*   - Do not use showo during a normal proof.                                *)
(*   - All theorems should be stated so that when an impossible reflexivity   *)
(*     is encounterd, it is of the form 'O_F g = 'O_F g so that you       *)
(*     know you should use eqOE in order to generalize your 'O_F g        *)
(*     to an arbitrary 'O_F g                                                 *)
(*                                                                            *)
(*  bigO F f g == f is a bigO of g near F,                                    *)
(*                use only if you want to go back to filter reasoning.        *)
(*                                                                            *)
(*  Parsable notations:                                                       *)
(*    [bigO of f] == recovers the canonical structure of big-o of f           *)
(*                   expands to itself                                        *)
(*       f =O_F h == f is a bigO of h near F,                                 *)
(*                   this is the preferred way for statements.                *)
(*                   expands to the equation (f = 'O_F h)                     *)
(*                   rewrite from LEFT to RIGHT only                          *)
(*   f = g +O_F h == f is equal to g plus a bigO near F,                      *)
(*                   this is the preferred way for statements.                *)
(*                   expands to the equation (f = g + 'O_F h)                 *)
(*                   rewrite from LEFT to RIGHT only                          *)
(*                   /!\ When you have to prove                               *)
(*                   (f =O_F h) or (f = g +O_F h).                            *)
(*                   you must (apply: eqOE) as soon as possible in a proof    *)
(*                   in order to turn it into 'a_O_F f with a shelved content *)
(*                   /!\ under rare circumstances, a hint may do that for you *)
(*   [O_F h of f] == returns a function with a bigO canonical structure       *)
(*                   provably equal to f if f is indeed a bigO of h           *)
(*                   provably equal to 0 otherwise                            *)
(*                   expands to ('O_F h)                                      *)
(*           'O_F == pattern to match a bigO with a specific F                *)
(*             'O == pattern to match a bigO with a generic F                 *)
(*                                                                            *)
(*   Printing only notations:                                                 *)
(*       {O_F f} == the type of functions that are a bigO of f near F         *)
(*      'a_O_F f == an existential bigO, must come from (apply: eqOE)         *)
(*        'O_F f == a generic bigO, with a function you should not rely on,   *)
(*                  but there is no way you can use eqOE on it.               *)
(*                                                                            *)
(* The former works exactly the same by with littleo instead of bigO.         *)
(******************************************************************************)

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Import GRing.Theory Num.Def Num.Theory.

Delimit Scope R_scope with coqR.
Delimit Scope real_scope with real.
Local Close Scope R_scope.
Local Open Scope ring_scope.
Local Open Scope real_scope.
Local Open Scope classical_set_scope.

Section function_space.

Definition cst {T T' : Type} (x : T') : T -> T' := fun=> x.

Program Definition fct_zmodMixin (T : Type) (M : zmodType) :=
  @ZmodMixin (T -> M) \0 (fun f x => - f x) (fun f g => f \+ g) _ _ _ _.
Next Obligation. by move=> f g h; rewrite funeqE=> x /=; rewrite addrA. Qed.
Next Obligation. by move=> f g; rewrite funeqE=> x /=; rewrite addrC. Qed.
Next Obligation. by move=> f; rewrite funeqE=> x /=; rewrite add0r. Qed.
Next Obligation. by move=> f; rewrite funeqE=> x /=; rewrite addNr. Qed.
Canonical fct_zmodType T (M : zmodType) := ZmodType (T -> M) (fct_zmodMixin T M).

Program Definition fct_ringMixin (T : pointedType) (M : ringType) :=
  @RingMixin [zmodType of T -> M] (cst 1) (fun f g x => f x * g x)
             _ _ _ _ _ _.
Next Obligation. by move=> f g h; rewrite funeqE=> x /=; rewrite mulrA. Qed.
Next Obligation. by move=> f; rewrite funeqE=> x /=; rewrite mul1r. Qed.
Next Obligation. by move=> f; rewrite funeqE=> x /=; rewrite mulr1. Qed.
Next Obligation. by move=> f g h; rewrite funeqE=> x /=; rewrite mulrDl. Qed.
Next Obligation. by move=> f g h; rewrite funeqE=> x /=; rewrite mulrDr. Qed.
Next Obligation.
by apply/eqP; rewrite funeqE => /(_ point) /eqP; rewrite oner_eq0.
Qed.
Canonical fct_ringType (T : pointedType) (M : ringType) :=
  RingType (T -> M) (fct_ringMixin T M).

Program Canonical fct_comRingType (T : pointedType) (M : comRingType) :=
  ComRingType (T -> M) _.
Next Obligation. by move=> f g; rewrite funeqE => x; rewrite mulrC. Qed.

Program Definition fct_lmodMixin (U : Type) (R : ringType) (V : lmodType R)
  := @LmodMixin R [zmodType of U -> V] (fun k f => k \*: f) _ _ _ _.
Next Obligation. rewrite funeqE => x; exact: scalerA. Qed.
Next Obligation. by move=> f; rewrite funeqE => x /=; rewrite scale1r. Qed.
Next Obligation. by move=> f g h; rewrite funeqE => x /=; rewrite scalerDr. Qed.
Next Obligation. by move=> f g; rewrite funeqE => x /=; rewrite scalerDl. Qed.
Canonical fct_lmodType U (R : ringType) (V : lmodType R) :=
  LmodType _ (U -> V) (fct_lmodMixin U V).

End function_space.

Section Linear1.
Context (R : ringType) (U : lmodType R) (V : zmodType) (s : R -> V -> V).
Canonical linear_eqType := EqType {linear U -> V | s} gen_eqMixin.
Canonical linear_choiceType := ChoiceType {linear U -> V | s} gen_choiceMixin.
End Linear1.
Section Linear2.
Context (R : ringType) (U : lmodType R) (V : zmodType) (s : R -> V -> V)
        (s_law : GRing.Scale.law s).
Canonical linear_pointedType := PointedType {linear U -> V | GRing.Scale.op s_law}
                                            (@GRing.null_fun_linear R U V s s_law).
End Linear2.

(* tags for littleo and bigO notations *)
Definition the_tag : unit := tt.
Definition gen_tag : unit := tt.
Definition a_tag : unit := tt.
Lemma showo : (gen_tag = tt) * (the_tag = tt) * (a_tag = tt). Proof. by []. Qed.

(* Tentative to handle small o and big O notations *)
Section Domination.

Context {K : absRingType} {T : Type} {V W : normedModType K}.

Definition littleo (F : set (set T)) (f : T -> V) (g : T -> W) :=
  forall eps : R, 0 < eps -> \forall x \near F, `|[f x]| <= eps * `|[g x]|.

Structure littleo_type (F : set (set T)) (g : T -> W) := Littleo {
  littleo_fun :> T -> V;
  _ : `[< littleo F littleo_fun g >]
}.
Notation "{o_ F f }" := (littleo_type F f)
  (at level 0, F at level 0, format "{o_ F  f }").

Canonical littleo_subtype (F : set (set T)) (g : T -> W) :=
  [subType for (@littleo_fun F g)].

Lemma littleo_class (F : set (set T)) (g : T -> W) (f : {o_F g}) : `[<littleo F f g>].
Proof. by case: f => ?. Qed.
Hint Resolve littleo_class.

Definition littleo_clone (F : set (set T)) (g : T -> W) (f : T -> V) (fT : {o_F g}) c
  of phant_id (littleo_class fT) c := @Littleo F g f c.
Notation "[littleo 'of' f 'for' fT ]" := (@littleo_clone _ _ f fT _ idfun)
  (at level 0, f at level 0, format "[littleo  'of'  f  'for'  fT ]").
Notation "[littleo 'of' f ]" := (@littleo_clone _ _ f _ _ idfun)
  (at level 0, f at level 0, format "[littleo  'of'  f ]").

Lemma littleo0_subproof F g : Filter F -> littleo F 0 g.
Proof.
move=> FF _/posnumP[eps] /=; apply: filterE => x; rewrite normm0.
by rewrite mulr_ge0 // ltrW.
Qed.

Canonical littleo0 (F : filter_on T) g :=
  Littleo (asboolT (@littleo0_subproof F g _)).

Definition the_littleo (_ : unit) (F : filter_on T)
  (phF : phantom (set (set T)) F) f h := littleo_fun (insubd (littleo0 F h) f).
Notation PhantomF := (Phantom (set (set T))).
Arguments the_littleo : simpl never, clear implicits.

Notation mklittleo tag x := (the_littleo tag _ (PhantomF x)).
(* Parsing *)
Notation "[o_ x e 'of' f ]" := (mklittleo gen_tag x f e)
  (at level 0, x, e at level 0, only parsing).
(*Printing*)
Notation "[o '_' x e 'of' f ]" := (the_littleo _ _ (PhantomF x) f e)
  (at level 0, x, e at level 0, format "[o '_' x  e  'of'  f ]").
(* These notation is printing only in order to display 'o
   without looking at the contents, use showo to dispaly *)
Notation "''o_' x e " := (the_littleo the_tag _ (PhantomF x) _ e)
  (at level 0, x, e at level 0, format "''o_' x  e ").
Notation "''a_o_' x e " := (the_littleo a_tag _ (PhantomF x) _ e)
  (at level 0, x, e at level 0, format "''a_o_' x  e ").
Notation "''o' '_' x" := (the_littleo gen_tag _ (PhantomF x) _)
  (at level 0, x at level 0, format "''o' '_' x").

Notation "f = g '+o_' F h" :=
  (f%function = g%function + mklittleo the_tag F (f \- g) h)
  (at level 70, no associativity,
   g at next level, F at level 0, h at next level,
   format "f  =  g  '+o_' F  h").
Notation "f '=o_' F h" :=
  (f%function = (mklittleo the_tag F f h))
  (at level 70, no associativity,
   F at level 0, h at next level,
   format "f  '=o_' F  h").
Notation "f == g '+o_' F h" :=
  (f%function == g%function + mklittleo the_tag F (f \- g) h)
  (at level 70, no associativity,
   g at next level, F at level 0, h at next level,
   format "f  ==  g  '+o_' F  h").
Notation "f '==o_' F h" :=
  (f%function == (mklittleo the_tag F f h))
  (at level 70, no associativity,
   F at level 0, h at next level,
   format "f  '==o_' F  h").

Lemma littleoP (F : set (set T)) (g : T -> W) (f : {o_F g}) : littleo F f g.
Proof. exact/asboolP. Qed.
Hint Extern 0 (littleo _ _ _) => solve[apply: littleoP] : core.
Hint Extern 0 (locally _ _) => solve[apply: littleoP] : core.
Hint Extern 0 (prop_near1 _) => solve[apply: littleoP] : core.
Hint Extern 0 (prop_near2 _) => solve[apply: littleoP] : core.

Lemma littleoE (tag : unit) (F : filter_on T)
   (phF : phantom (set (set T)) F) f h :
   littleo F f h -> the_littleo tag F phF f h = f.
Proof. by move=> /asboolP?; rewrite /the_littleo /insubd insubT. Qed.

Canonical the_littleo_littelo (tag : unit) (F : filter_on T)
  (phF : phantom (set (set T)) F) f h := [littleo of the_littleo tag F phF f h].

Lemma opp_littleo_subproof (F : filter_on T) e (df : {o_F e}) :
   littleo F (- (df : _ -> _)) e.
Proof.
move=> _/posnumP[eps]; near=> x; [rewrite normmN; near: x|end_near].
by apply: littleoP.
Qed.

Canonical opp_littleo (F : filter_on T) e (df : {o_F e}) :=
  Littleo (asboolT (opp_littleo_subproof df)).

Lemma oppo (F : filter_on T) (f : T -> V) e : - [o_F e of f] =o_F e.
Proof. by rewrite [RHS]littleoE. Qed.

Lemma oppox (F : filter_on T) (f : T -> V) e x :
  - [o_F e of f] x = [o_F e of - [o_F e of f]] x.
Proof. by move: x; rewrite -/(- _ =1 _) {1}oppo. Qed.

Lemma add_littleo_subproof (F : filter_on T) e (df dg : {o_F e}) :
  littleo F (df \+ dg) e.
Proof.
move=> _/posnumP[eps]; near=> x => /=.
  rewrite [eps%:num]splitr mulrDl.
  rewrite (ler_trans (ler_normm_add _ _)) // ler_add //; near: x.
by end_near; apply: littleoP.
Qed.

Canonical add_littleo (F : filter_on T) e (df dg : {o_F e}) :=
  @Littleo _ _ (_ + _) (asboolT (add_littleo_subproof df dg)).
Canonical addfun_littleo (F : filter_on T) e (df dg : {o_F e}) :=
  @Littleo _ _ (_ \+ _) (asboolT (add_littleo_subproof df dg)).

Lemma addo (F : filter_on T) (f g: T -> V) e :
  [o_F e of f] + [o_F e of g] =o_F e.
Proof. by rewrite [RHS]littleoE. Qed.

Lemma addox (F : filter_on T) (f g: T -> V) e x :
  [o_F e of f] x + [o_F e of g] x =
  [o_F e of [o_F e of f] + [o_F e of g]] x.
Proof. by move: x; rewrite -/(_ + _ =1 _) {1}addo. Qed.

Lemma eqadd_some_oP (F : filter_on T) (f g : T -> V) (e : T -> W) h :
  f = g + [o_F e of h] -> littleo F (f - g) e.
Proof.
rewrite /the_littleo /insubd=> ->.
case: insubP => /= [u /asboolP fg_o_e ->|_] eps  /=.
  by rewrite addrAC subrr add0r; apply: fg_o_e.
by rewrite addrC addKr; apply: littleoP.
Qed.

Lemma eqaddoP (F : filter_on T) (f g : T -> V) (e : T -> W) :
   (f = g +o_ F e) <-> (littleo F (f - g) e).
Proof.
by split=> [/eqadd_some_oP|fg_o_e]; rewrite ?littleoE // addrC addrNK.
Qed.

Lemma eqoP (F : filter_on T) (e : T -> W) (f : T -> V) :
   (f =o_ F e) <-> (littleo F f e).
Proof. by rewrite -[f]subr0 -eqaddoP -[f \- 0]/(f - 0) subr0 add0r. Qed.

Lemma eq_some_oP (F : filter_on T) (e : T -> W) (f : T -> V) h :
   f = [o_F e of h] -> littleo F f e.
Proof. by have := @eqadd_some_oP F f 0 e h; rewrite add0r subr0. Qed.

(* replaces a 'o_F e by a "canonical one" *)
(* mostly to prevent problems with dependent types *)
Lemma eqaddoE (F : filter_on T) (f g : T -> V) h (e : T -> W) :
  f = g + mklittleo a_tag F h e -> f = g +o_ F e.
Proof. by move=> /eqadd_some_oP /eqaddoP. Qed.

Lemma eqoE (F : filter_on T) (f : T -> V) h (e : T -> W) :
  f = mklittleo a_tag F h e -> f =o_F e.
Proof. by move=> /eq_some_oP /eqoP. Qed.

Lemma littleo_eqo (F : filter_on T) (g : T -> W) (f : {o_F g}) :
   (f : _ -> _) =o_F g.
Proof. by apply/eqoP; apply: littleoP. Qed.

Lemma scale_littleo_subproof (F : filter_on T) e (df : {o_F e}) a :
  littleo F (a *: (df : _ -> _)) e.
Proof.
have [->|a0] := eqVneq a 0; first by rewrite scale0r.
move=> _ /posnumP[eps]; have aa := absr_eq0 a; near=> x => /=.
  rewrite (ler_trans (ler_normmZ _ _)) //.
  by rewrite -ler_pdivl_mull ?ltr_def ?aa ?a0 //= mulrA; near: x.
by end_near; apply: littleoP; rewrite mulr_gt0 // invr_gt0 ?ltr_def ?aa ?a0 /=.
Qed.

Canonical scale_littleo (F : filter_on T) e a (df : {o_F e}) :=
  Littleo (asboolT (scale_littleo_subproof df a)).

Lemma scaleo (F : filter_on T) a (f : T -> V) e :
  a *: [o_F e of f] = [o_F e of a *: [o_F e of f]].
Proof. by rewrite [RHS]littleoE. Qed.

(* This should actually be bigO *)
Definition bigOF (F : set (set T)) (f : T -> V) (g : T -> W) :=
  \forall k \near +oo, \forall x \near F, `|[f x]| <= k * `|[g x]|.

Definition bigOW (F : set (set T)) (f : T -> V) (g : T -> W) :=
  exists k, \forall x \near F, `|[f x]| <= k * `|[g x]|.

Lemma bigOWFE (F : set (set T)) : Filter F -> bigOW F = bigOF F.
Proof.
rewrite predeq2E => FF f g; split=> [[k] |] kP; last first.
  by near +oo have k; [exists k; near: k|end_near].
near=> k'.
  near=> x.
    by rewrite (ler_trans (near kP _ _)) // ler_wpmul2r // ltrW //; near: k'.
  by end_near.
by end_near; exists k.
Qed.

Definition bigO (F : set (set T)) (f : T -> V) (g : T -> W) :=
  exists2 k, k > 0 & \forall x \near F, `|[f x]| <= k * `|[g x]|.

Lemma bigOWE (F : set (set T)) : Filter F -> bigOW F = bigO F.
Proof.
rewrite predeq2E => f g; split=> [[k] | [k k_gt0]] kP; last by exists k.
exists (maxr k 1); first by rewrite ltr_maxr ltr01 orbT.
by apply: filterS kP => x /ler_trans; apply; rewrite ler_wpmul2r // ler_maxr lerr.
Qed.

Lemma bigOFE (F : set (set T)) : Filter F -> bigOF F = bigO F.
Proof. by move=> FF; rewrite -bigOWE bigOWFE. Qed.

Lemma bigOWP (F : set (set T)) f g : Filter F -> bigOW F f g -> bigO F f g.
Proof. by move=> /bigOWE->. Qed.

Lemma bigOWI (F : set (set T)) f g : Filter F -> bigO F f g -> bigOW F f g.
Proof. by move=> /bigOWE->. Qed.

Lemma bigOFP (F : set (set T)) f g : Filter F -> bigOF F f g -> bigO F f g.
Proof. by move=> /bigOFE->. Qed.

Lemma bigOFI (F : set (set T)) f g : Filter F -> bigO F f g -> bigOF F f g.
Proof. by move=> /bigOFE->. Qed.

Structure bigO_type (F : set (set T)) (g : T -> W) := BigO {
  bigO_fun :> T -> V;
  _ : `[< bigO F bigO_fun g >]
}.
Notation "{O_ F f }" := (bigO_type F f)
  (at level 0, F at level 0, format "{O_  F  f }").

Canonical bigO_subtype (F : set (set T)) (g : T -> W) :=
  [subType for (@bigO_fun F g)].

Lemma bigO_class (F : set (set T)) (g : T -> W) (f : {O_F g}) : `[<bigO F f g>].
Proof. by case: f => ?. Qed.
Hint Resolve bigO_class.

Definition bigO_clone (F : set (set T)) (g : T -> W) (f : T -> V) (fT : {O_F g}) c
  of phant_id (bigO_class fT) c := @BigO F g f c.
Notation "[bigO 'of' f 'for' fT ]" := (@bigO_clone _ _ f fT _ idfun)
  (at level 0, f at level 0, format "[bigO  'of'  f  'for'  fT ]").
Notation "[bigO 'of' f ]" := (@bigO_clone _ _ f _ _ idfun)
  (at level 0, f at level 0, format "[bigO  'of'  f ]").

Lemma bigO0_subproof F g : Filter F -> bigO F 0 g.
Proof.
move=> FF; apply/bigOWP.
by exists 0 => //; apply: filterE=> x; rewrite normm0 mul0r.
Qed.

Canonical bigO0 (F : filter_on T) g := BigO (asboolT (@bigO0_subproof F g _)).

Definition the_bigO (u : unit) (F : filter_on T)
  (phF : phantom (set (set T)) F) f h := bigO_fun (insubd (bigO0 F h) f).
Arguments the_bigO : simpl never, clear implicits.

Notation mkbigO tag x := (the_bigO tag _ (PhantomF x)).
(* Parsing *)
Notation "[O_ x e 'of' f ]" := (mkbigO gen_tag x f e)
  (at level 0, x, e at level 0, only parsing).
(*Printing*)
Notation "[O '_' x e 'of' f ]" := (the_bigO _ _ (PhantomF x) f e)
  (at level 0, x, e at level 0, format "[O '_' x  e  'of'  f ]").
(* These notation is printing only in order to display 'o
   without looking at the contents, use showo to display *)
Notation "''O_' x e " := (the_bigO the_tag _ (PhantomF x) _ e)
  (at level 0, x, e at level 0, format "''O_' x  e ").
Notation "''a_O_' x e " := (the_bigO a_tag _ (PhantomF x) _ e)
  (at level 0, x, e at level 0, format "''a_O_' x  e ").
Notation "''O' '_' x" := (the_bigO gen_tag _ (PhantomF x) _)
  (at level 0, x at level 0, format "''O' '_' x").

Notation "f = g '+O_' F h" :=
  (f%function = g%function + mkbigO the_tag F (f \- g) h)
  (at level 70, no associativity,
   g at next level, F at level 0, h at next level,
   format "f  =  g  '+O_' F  h").
Notation "f '=O_' F h" := (f%function = mkbigO the_tag F f h)
  (at level 70, no associativity,
   F at level 0, h at next level,
   format "f  '=O_' F  h").
Notation "f == g '+O_' F h" :=
  (f%function == g%function + mkbigO the_tag F (f \- g) h)
  (at level 70, no associativity,
   g at next level, F at level 0, h at next level,
   format "f  ==  g  '+O_' F  h").
Notation "f '==O_' F h" := (f%function == mkbigO the_tag F f h)
  (at level 70, no associativity,
   F at level 0, h at next level,
   format "f  '==O_' F  h").

Lemma bigOP (F : set (set T)) (g : T -> W) (f : {O_F g}) : bigO F f g.
Proof. exact/asboolP. Qed.
Hint Extern 0 (bigO _ _ _) => solve[apply: bigOP] : core.
Hint Extern 0 (locally _ _) => solve[apply: bigOP] : core.
Hint Extern 0 (prop_near1 _) => solve[apply: bigOP] : core.
Hint Extern 0 (prop_near2 _) => solve[apply: bigOP] : core.

Lemma bigOW_hint (F : filter_on T) (g : T -> W) (f : {O_F g}) : bigOW F f g.
Proof. exact/bigOWI. Qed.
Hint Extern 0 (bigOW _ _ _) => solve[apply: bigOW_hint] : core.
Hint Extern 0 (locally _ _) => solve[apply: bigOW_hint] : core.
Hint Extern 0 (prop_near1 _) => solve[apply: bigOW_hint] : core.
Hint Extern 0 (prop_near2 _) => solve[apply: bigOW_hint] : core.

Lemma bigOE (tag : unit) (F : filter_on T) (phF : phantom (set (set T)) F) f h :
   bigO F f h -> the_bigO tag F phF f h = f.
Proof. by move=> /asboolP?; rewrite /the_bigO /insubd insubT. Qed.

Canonical the_bigO_bigO (tag : unit) (F : filter_on T)
  (phF : phantom (set (set T)) F) f h := [bigO of the_bigO tag F phF f h].

Lemma opp_bigO_subproof (F : filter_on T) e (df : {O_F e}) :
   bigO F (- (df : _ -> _)) e.
Proof.
have [_/posnumP[k] kP] := bigOP [bigO of df]; apply: bigOWP; exists k%:num.
by near=> x; [rewrite normmN; near: x|end_near].
Qed.

Canonical Opp_bigO (F : filter_on T) e (df : {O_F e}) :=
  BigO (asboolT (opp_bigO_subproof df)).

Lemma oppO (F : filter_on T) (f : T -> V) e : - [O_F e of f] =O_F e.
Proof. by rewrite [RHS]bigOE. Qed.

Lemma oppOx (F : filter_on T) (f : T -> V) e x :
  - [O_F e of f] x = [O_F e of - [O_F e of f]] x.
Proof. by move: x; rewrite -/(- _ =1 _) {1}oppO. Qed.

Lemma add_bigO_subproof (F : filter_on T) e (df dg : {O_F e}) :
  bigO F (df \+ dg) e.
Proof.
have [[_/posnumP[kf] xkf] [_ /posnumP[kg] xkg]] := (bigOP df, bigOP dg).
exists (kf%:num + kg%:num) => //.
apply: filterS2 xkf xkg => x /ler_add fD/fD{fD}.
by rewrite mulrDl; apply: ler_trans; apply: ler_normm_add.
Qed.

Canonical add_bigO (F : filter_on T) e (df dg : {O_F e}) :=
  @BigO _ _ (_ + _) (asboolT (add_bigO_subproof df dg)).
Canonical addfun_bigO (F : filter_on T) e (df dg : {O_F e}) :=
  BigO (asboolT (add_bigO_subproof df dg)).

Lemma addO (F : filter_on T) (f g: T -> V) e :
  [O_F e of f] + [O_F e of g] =O_F e.
Proof. by rewrite [RHS]bigOE. Qed.

Lemma addOx (F : filter_on T) (f g: T -> V) e x :
  [O_F e of f] x + [O_F e of g] x =
  [O_F e of [O_F e of f] + [O_F e of g]] x.
Proof. by move: x; rewrite -/(_ + _ =1 _) {1}addO. Qed.

Lemma eqadd_some_OP (F : filter_on T) (f g : T -> V) (e : T -> W) h :
  f = g + [O_F e of h] -> bigO F (f - g) e.
Proof.
rewrite /the_bigO /insubd=> ->.
case: insubP => /= [u /asboolP fg_o_e ->|_].
  by rewrite addrAC subrr add0r; apply: fg_o_e.
by rewrite addrC addKr; apply: bigOP.
Qed.

Lemma eqaddOP (F : filter_on T) (f g : T -> V) (e : T -> W) :
   (f = g +O_ F e) <-> (bigO F (f - g) e).
Proof. by split=> [/eqadd_some_OP|fg_O_e]; rewrite ?bigOE // addrC addrNK. Qed.

Lemma eqOP (F : filter_on T) (e : T -> W) (f : T -> V) :
   (f =O_ F e) <-> (bigO F f e).
Proof. by rewrite -[f]subr0 -eqaddOP -[f \- 0]/(f - 0) subr0 add0r. Qed.

Lemma eqOWP (F : filter_on T) (e : T -> W) (f : T -> V) :
   (f =O_ F e) <-> (bigOW F f e).
Proof. by rewrite bigOWE; apply: eqOP. Qed.

Lemma eqOFP (F : filter_on T) (e : T -> W) (f : T -> V) :
   (f =O_ F e) <-> (bigOF F f e).
Proof. by rewrite bigOFE; apply: eqOP. Qed.

Lemma eq_some_OP (F : filter_on T) (e : T -> W) (f : T -> V) h :
   f = [O_F e of h] -> bigO F f e.
Proof. by have := @eqadd_some_OP F f 0 e h; rewrite add0r subr0. Qed.

Lemma bigO_eqO (F : filter_on T) (g : T -> W) (f : {O_F g}) :
   (f : _ -> _) =O_F g.
Proof. by apply/eqOP; apply: bigOP. Qed.

Lemma eqO_bigO (F : filter_on T) (e : T -> W) (f : T -> V) :
   f =O_ F e -> bigO F f e.
Proof. by rewrite eqOP. Qed.

(* replaces a 'O_F e by a "canonical one" *)
(* mostly to prevent problems with dependent types *)
Lemma eqaddOE (F : filter_on T) (f g : T -> V) h (e : T -> W) :
  f = g + mkbigO a_tag F h e -> f = g +O_ F e.
Proof.  by move=> /eqadd_some_OP /eqaddOP. Qed.

Lemma eqOE (F : filter_on T) (f : T -> V) h (e : T -> W) :
  f = mkbigO a_tag F h e -> f =O_F e.
Proof. by move=> /eq_some_OP /eqOP. Qed.

Lemma eqoO (F : filter_on T) (f : T -> V) (e : T -> W) :
  [o_F e of f] =O_F e.
Proof. by apply/eqOP; exists 1 => //; apply: littleoP. Qed.
Hint Resolve eqoO.

Lemma littleo_eqO (F : filter_on T) (e : T -> W) (f : {o_F e}) :
   (f : _ -> _) =O_F e.
Proof. by apply: eqOE; rewrite littleo_eqo. Qed.

Canonical littleo_is_bigO (F : filter_on T) (e : T -> W) (f : {o_F e}) :=
  BigO (asboolT (eqO_bigO (littleo_eqO f))).
Canonical the_littleo_bigO (tag : unit) (F : filter_on T)
  (phF : phantom (set (set T)) F) f h := [bigO of the_littleo tag F phF f h].

End Domination.

Notation "{o_ F f }" := (@littleo_type _ _ _ _ F f)
  (at level 0, F at level 0, format "{o_ F  f }").

Notation "{O_ F f }" := (@bigO_type _ _ _ _ F f)
  (at level 0, F at level 0, format "{O_ F  f }").

Notation "[littleo 'of' f 'for' fT ]" :=
  (@littleo_clone _ _ _ _ _ _ f fT _ idfun)
  (at level 0, f at level 0, format "[littleo  'of'  f  'for'  fT ]").
Notation "[littleo 'of' f ]" :=
  (@littleo_clone _ _ _ _ _ _ f _ _ idfun)
  (at level 0, f at level 0, format "[littleo  'of'  f ]").

Notation "[bigO 'of' f 'for' fT ]" :=
  (@bigO_clone _ _ _ _ _ _ f fT _ idfun)
  (at level 0, f at level 0, format "[bigO  'of'  f  'for'  fT ]").
Notation "[bigO 'of' f ]" :=
  (@bigO_clone _ _ _ _ _ _ f _ _ idfun)
  (at level 0, f at level 0, format "[bigO  'of'  f ]").

Arguments the_littleo {_ _ _ _} _ _ _ _ _ : simpl never.
Arguments the_bigO {_ _ _ _} _ _ _ _ _ : simpl never.
Local Notation PhantomF x := (Phantom _ [filter of x]).

Notation mklittleo tag x := (the_littleo tag _ (PhantomF x)).
(* Parsing *)
Notation "[o_ x e 'of' f ]" := (mklittleo gen_tag x f e)
  (at level 0, x, e at level 0, only parsing).
Notation "'o_ x" := (the_littleo _ _ (PhantomF x) _)
  (at level 200, x at level 0, only parsing).
Notation "'o" := (the_littleo _ _ _ _) (at level 200, only parsing).
(*Printing*)
Notation "[o '_' x e 'of' f ]" := (the_littleo _ _ (Phantom _ x) f e)
  (at level 0, x, e at level 0, format "[o '_' x  e  'of'  f ]").
(* These notation is printing only in order to display 'o
   without looking at the contents, use showo to dispaly *)
Notation "''o_' x e " := (the_littleo the_tag _ (Phantom _ x) _ e)
  (at level 0, x, e at level 0, format "''o_' x  e ").
Notation "''a_o_' x e " := (the_littleo a_tag _ (Phantom _ x) _ e)
  (at level 0, x, e at level 0, format "''a_o_' x  e ").
Notation "''o' '_' x" := (the_littleo gen_tag _ (Phantom _ x) _)
  (at level 0, x at level 0, format "''o' '_' x").

Notation mkbigO tag x := (the_bigO tag _ (PhantomF x)).
(* Parsing *)
Notation "[O_ x e 'of' f ]" := (mkbigO gen_tag x f e)
  (at level 0, x, e at level 0, only parsing).
Notation "'O_ x" := (the_bigO _ _ (PhantomF x) _)
  (at level 200, x at level 0, only parsing).
Notation "'O" := (the_bigO _ _ _ _) (at level 200, only parsing).
(*Printing*)
Notation "[O '_' x e 'of' f ]" := (the_bigO _ _ (Phantom _ x) f e)
  (at level 0, x, e at level 0, format "[O '_' x  e  'of'  f ]").
(* These notation is printing only in order to display 'o
   without looking at the contents, use showo to dispaly *)
Notation "''O_' x e " := (the_bigO the_tag _ (Phantom _ x) _ e)
  (at level 0, x, e at level 0, format "''O_' x  e ").
Notation "''a_O_' x e " := (the_bigO a_tag _ (Phantom _ x) _ e)
  (at level 0, x, e at level 0, format "''a_O_' x  e ").
Notation "''O' '_' x" := (the_bigO gen_tag _ (Phantom _ x) _)
  (at level 0, x at level 0, format "''O' '_' x").


Notation "f = g '+o_' F h" :=
  (f%function = g%function + mklittleo the_tag F (f \- g) h)
  (at level 70, no associativity,
   g at next level, F at level 0, h at next level,
   format "f  =  g  '+o_' F  h",
   only parsing).
Notation "f '=o_' F h" :=
  (f%function = (mklittleo the_tag F f h))
  (at level 70, no associativity,
   F at level 0, h at next level,
   format "f  '=o_' F  h",
   only parsing).

Notation "f = g '+O_' F h" :=
  (f%function = g%function + mkbigO the_tag F (f \- g) h)
  (at level 70, no associativity,
   g at next level, F at level 0, h at next level,
   format "f  =  g  '+O_' F  h",
   only parsing).
Notation "f '=O_' F h" := (f%function = mkbigO the_tag F f h)
  (at level 70, no associativity,
   F at level 0, h at next level,
   format "f  '=O_' F  h",
   only parsing).

Notation "f == g '+o_' F h" :=
  (f%function == g%function + mklittleo the_tag F (f \- g) h)
  (at level 70, no associativity,
   g at next level, F at level 0, h at next level,
   format "f  ==  g  '+o_' F  h",
   only parsing).
Notation "f '==o_' F h" :=
  (f%function == (mklittleo the_tag F f h))
  (at level 70, no associativity,
   F at level 0, h at next level,
   format "f  '==o_' F  h",
   only parsing).

Notation "f == g '+O_' F h" :=
  (f%function == g%function + mkbigO the_tag F (f \- g) h)
  (at level 70, no associativity,
   g at next level, F at level 0, h at next level,
   format "f  ==  g  '+O_' F  h",
   only parsing).
Notation "f '==O_' F h" := (f%function == mkbigO the_tag F f h)
  (at level 70, no associativity,
   F at level 0, h at next level,
   format "f  '==O_' F  h",
   only parsing).

Hint Extern 0 (_ = 'o__ _) => apply: eqoE; reflexivity : core.
Hint Extern 0 (_ = 'O__ _) => apply: eqOE; reflexivity : core.
Hint Extern 0 (_ = 'O__ _) => apply: eqoO; reflexivity : core.
Hint Extern 0 (_ = _ + 'o__ _) => apply: eqaddoE; reflexivity : core.
Hint Extern 0 (_ = _ + 'O__ _) => apply: eqaddOE; reflexivity : core.
Hint Extern 0 (bigO _ _ _) => solve[apply: bigOP] : core.
Hint Extern 0 (locally _ _) => solve[apply: bigOP] : core.
Hint Extern 0 (prop_near1 _) => solve[apply: bigOP] : core.
Hint Extern 0 (prop_near2 _) => solve[apply: bigOP] : core.
Hint Extern 0 (bigOW _ _ _) => solve[apply: bigOW_hint] : core.
Hint Extern 0 (locally _ _) => solve[apply: bigOW_hint] : core.
Hint Extern 0 (prop_near1 _) => solve[apply: bigOW_hint] : core.
Hint Extern 0 (prop_near2 _) => solve[apply: bigOW_hint] : core.
Hint Extern 0 (littleo _ _ _) => solve[apply: littleoP] : core.
Hint Extern 0 (locally _ _) => solve[apply: littleoP] : core.
Hint Extern 0 (prop_near1 _) => solve[apply: littleoP] : core.
Hint Extern 0 (prop_near2 _) => solve[apply: littleoP] : core.
Hint Resolve littleo_class.
Hint Resolve bigO_class.
Hint Resolve littleo_eqO.

Section Limit.

Context {K : absRingType} {T : Type} {V W X : normedModType K}.

Lemma eqolimP (F : filter_on T) (f : T -> V) (l : V) :
  f @ F --> l <-> f = cst l +o_F (cst (1 : K^o)).
Proof.
split=> fFl.
  apply/eqaddoP => _/posnumP[eps]; near=> x.
    by rewrite /cst ltrW //= normmB; near: x.
  by end_near; apply: (flim_norm _ fFl); rewrite mulr_gt0 // ?absr1_gt0.
apply/flim_normP=> _/posnumP[eps]; rewrite !near_simpl.
have lt_eps x : x <= (eps%:num / 2%:R) * `|1 : K^o|%real -> x < eps.
  rewrite absr1 mulr1 => /ler_lt_trans; apply.
  by rewrite ltr_pdivr_mulr // ltr_pmulr // ltr1n.
near=> x.
  by rewrite [X in X x]fFl opprD addNKr normmN lt_eps //; near: x.
by end_near; rewrite /= !near_simpl; apply: littleoP; rewrite divr_gt0.
Qed.

Lemma eqolim (F : filter_on T) (f : T -> V) (l : V) e :
  f = cst l + [o_F (cst (1 : K^o)) of e] -> f @ F --> l.
Proof. by move=> /eqaddoE /eqolimP. Qed.

Lemma eqolim0P (F : filter_on T) (f : T -> V) :
  f @ F --> (0 : V) <-> f =o_F (cst (1 : K^o)).
Proof. by rewrite eqolimP add0r -[f \- cst 0]/(f - 0) subr0. Qed.

Lemma eqolim0 (F : filter_on T) (f : T -> V) :
  f =o_F (cst (1 : K^o)) -> f @ F --> (0 : V).
Proof. by move=> /eqoE /eqolim0P. Qed.

(* ideally the precondition should be f = '[O_F g of f'] with a *)
(* universally quantified f' which is irrelevant and replaced by *)
(* a hole, on the fly, by ssreflect rewrite *)
Lemma littleo_bigO_eqo {F : filter_on T}
  (g : T -> W) (f : T -> V) (h : T -> X) :
  f =O_F g -> [o_F f of h] =o_F g.
Proof.
move->; apply/eqoP => _/posnumP[eps] /=.
set k := 'O g; have [/= _/posnumP[c]] := bigOP [bigO of k].
apply: filter_app; near=> x.
  rewrite -!ler_pdivr_mull //; apply: ler_trans.
  by rewrite ler_pdivr_mull // mulrA; near: x.
by end_near; rewrite /= !near_simpl; apply: littleoP.
Qed.
Arguments littleo_bigO_eqo {F}.

Lemma bigO_littleo_eqo {F : filter_on T} (g : T -> W) (f : T -> V) (h : T -> X) :
  f =o_F g -> [O_F f of h] =o_F g.
Proof.
move->; apply/eqoP => _/posnumP[eps].
set k := 'O _; have [/= _/posnumP[c]] := bigOP [bigO of k].
apply: filter_app; near=> x.
  by move=> /ler_trans; apply; rewrite -ler_pdivl_mull // mulrA; near: x.
by end_near; rewrite /= !near_simpl; apply: littleoP.
Qed.
Arguments bigO_littleo_eqo {F}.

Lemma bigO_bigO_eqO {F : filter_on T} (g : T -> W) (f : T -> V) (h : T -> X) :
  f =O_F g -> ([O_F f of h] : _ -> _) =O_F g.
Proof.
move->; apply/eqOWP.
set k := 'O g; have [c c_gt0 kP] := bigOP [bigO of k].
set k' := 'O k; have [c' c'_gt0 k'P] := bigOP [bigO of k'].
exists (c' * c) => //; apply: filterS2 kP k'P => x.
by rewrite -(ler_pmul2l c'_gt0) mulrA => /(ler_trans _); apply.
Qed.
Arguments bigO_bigO_eqO {F}.

Lemma add2o (F : filter_on T) (f g : T -> V) (e : T -> W) :
  f =o_F e -> g =o_F e -> f + g =o_F e.
Proof. by move=> -> ->; rewrite addo. Qed.

Lemma addfo (F : filter_on T) (h f : T -> V) (e : T -> W) :
  f =o_F e -> f + [o_F e of h] =o_F e.
Proof. by move->; rewrite addo. Qed.

Lemma oppfo (F : filter_on T) (h f : T -> V) (e : T -> W) :
  f =o_F e -> - f =o_F e.
Proof. by move->; rewrite oppo. Qed.

Lemma add2O (F : filter_on T) (f g : T -> V) (e : T -> W) :
  f =O_F e -> g =O_F e -> f + g =O_F e.
Proof. by move=> -> ->; rewrite addO. Qed.

Lemma addfO (F : filter_on T) (h f : T -> V) (e : T -> W) :
  f =O_F e -> f + [O_F e of h] =O_F e.
Proof. by move->; rewrite addO. Qed.

Lemma oppfO (F : filter_on T) (h f : T -> V) (e : T -> W) :
  f =O_F e -> - f =O_F e.
Proof. by move->; rewrite oppO. Qed.

Lemma idO (F : filter_on T) (e : T -> W) : e =O_F e.
Proof. by apply/eqOWP; exists 1; apply: filterE => x; rewrite mul1r. Qed.

Lemma littleo_littleo (F : filter_on T) (f : T -> V) (g : T -> W) (h : T -> X) :
  f =o_F g -> [o_F f of h] =o_F g.
Proof. by move=> ->; apply: eqoE; rewrite (littleo_bigO_eqo g). Qed.

End Limit.

Arguments littleo_bigO_eqo {K T V W X F}.
Arguments bigO_littleo_eqo {K T V W X F}.
Arguments bigO_bigO_eqO {K T V W X F}.

Section littleo_bigO_transitivity.

Context {K : absRingType} {T : Type} {V W Z : normedModType K}.

Lemma eqaddo_trans (F : filter_on T) (f g h : T -> V) fg gh (e : T -> W):
  f = g + [o_ F e of fg] -> g = h + [o_F e of gh] -> f = h +o_F e.
Proof. by move=> -> ->; rewrite -addrA addo. Qed.

Lemma eqaddO_trans (F : filter_on T) (f g h : T -> V) fg gh (e : T -> W):
  f = g + [O_ F e of fg] -> g = h + [O_F e of gh] -> f = h +O_F e.
Proof. by move=> -> ->; rewrite -addrA addO. Qed.

Lemma eqaddoO_trans (F : filter_on T) (f g h : T -> V) fg gh (e : T -> W):
  f = g + [o_ F e of fg] -> g = h + [O_F e of gh] -> f = h +O_F e.
Proof. by move=> -> ->; rewrite addrAC -addrA addfO. Qed.

Lemma eqaddOo_trans (F : filter_on T) (f g h : T -> V) fg gh (e : T -> W):
  f = g + [O_ F e of fg] -> g = h + [o_F e of gh] -> f = h +O_F e.
Proof. by move=> -> ->; rewrite -addrA addfO. Qed.

Lemma eqo_trans (F : filter_on T) (f : T -> V) f' (g : T -> W) g' (h : T -> Z) :
  f = [o_F g of f'] -> g = [o_F h of g'] -> f =o_F h.
Proof.  by move=> -> ->; rewrite (littleo_bigO_eqo h). Qed.

Lemma eqO_trans (F : filter_on T) (f : T -> V) f' (g : T -> W) g' (h : T -> Z) :
  f = [O_F g of f'] -> g = [O_F h of g'] -> f =O_F h.
Proof. by move=> -> ->; rewrite (bigO_bigO_eqO h). Qed.

Lemma eqOo_trans (F : filter_on T) (f : T -> V) f' (g : T -> W) g' (h : T -> Z) :
  f = [O_F g of f'] -> g = [o_F h of g'] -> f =o_F h.
Proof. by move=> -> ->; rewrite (bigO_littleo_eqo h). Qed.

Lemma eqoO_trans (F : filter_on T) (f : T -> V) f' (g : T -> W) g' (h : T -> Z) :
  f = [o_F g of f'] -> g = [O_F h of g'] -> f =o_F h.
Proof. by move=> -> ->; rewrite (littleo_bigO_eqo h). Qed.

End littleo_bigO_transitivity.

Section rule_of_products_in_R.

Variable pT : pointedType.

Lemma mulo (F : filter_on pT) (h1 h2 f g : pT -> R^o) :
  [o_F h1 of f] * [o_F h2 of g] =o_F (h1 * h2).
Proof.
rewrite [in RHS]littleoE // => _/posnumP[e]; near=> x.
  rewrite (ler_trans (absrM _ _)) // -(sqr_sqrtr (ltrW [gt0 of e%:num])) expr2.
  rewrite [`|[_]|]normrM mulrACA ler_pmul //; near: x.
by end_near=> /=; set h := 'o _; apply: (littleoP [littleo of h]).
Qed.

Lemma mulO (F : filter_on pT) (h1 h2 f g : pT -> R^o) :
  [O_F h1 of f] * [O_F h2 of g] =O_F (h1 * h2).
Proof.
rewrite [in RHS]bigOE // -bigOFE; set O1 := 'O _; set O2 := 'O _.
have [k1 _ k1P] := bigOP [bigO of O1]; have [k2 _ k2P] := bigOP [bigO of O2].
near=> k; first near=> x.
- rewrite (ler_trans (absrM _ _)) //.
  rewrite (@ler_trans _ ((k1 * k2) * `|[(h1 * h2) x]|)) //.
    by rewrite [`|[_]|]normrM mulrACA ler_pmul //; near: x.
  by rewrite ler_wpmul2r // ltrW //; near: k.
- by end_near.
- by end_near; exists (k1 * k2).
Qed.

(* NB: also enjoyed by bigOmega *)

End rule_of_products_in_R.

Section Shift.

Context {R : zmodType} {T : Type}.

Definition shift (x y : R) := y + x.
Notation center c := (shift (- c)).
Arguments shift x / y.

Lemma comp_shiftK (x : R) (f : R -> T) : (f \o shift x) \o center x = f.
Proof. by rewrite funeqE => y /=; rewrite addrNK. Qed.

Lemma comp_centerK (x : R) (f : R -> T) : (f \o center x) \o shift x = f.
Proof. by rewrite funeqE => y /=; rewrite addrK. Qed.

Lemma shift0 : shift 0 = id.
Proof. by rewrite funeqE => x /=; rewrite addr0. Qed.

Lemma center0 : center 0 = id.
Proof. by rewrite oppr0 shift0. Qed.

End Shift.
Arguments shift {R} x / y.
Notation center c := (shift (- c)).

Lemma near_shift {K : absRingType} {R : normedModType K}
   (y x : R) (P : set R) :
   (\near x, P x) = (\forall z \near y, (P \o shift (x - y)) z).
Proof.
rewrite propeqE; split=> /= /locally_normP [_/posnumP[e] ye];
apply/locally_normP; exists e%:num => // t /= et.
  apply: ye; rewrite /= !opprD addrA addrACA subrr add0r.
  by rewrite opprK addrC.
have /= := ye (t - (x - y)); rewrite addrNK; apply.
by rewrite /= !opprB addrA addrCA subrr addr0.
Qed.

Lemma flim_shift {T : Type}  {K : absRingType} {R : normedModType K}
  (x y : R) (f : R -> T) :
  (f \o shift x) @ y = f @ (y + x).
Proof.
rewrite funeqE => A; rewrite /= !near_simpl (near_shift (y + x)).
by rewrite (_ : _ \o _ = A \o f) // funeqE=> z; rewrite /= opprD addNKr addrNK.
Qed.

Section Linear3.
Context (U : normedModType R) (V : normedModType R) (s : R -> V -> V)
        (s_law : GRing.Scale.law s).

(* Split in multiple bits *)
(* - Locally bounded => locally lipshitz *)
(* - locally lipshitz + linear => lipshitz *)
(* - locally lipshitz => continuous at a point *)
(* - lipizhitz => uniformly continous *)
Lemma linear_continuous (f: {linear U -> V | GRing.Scale.op s_law}) :
  (f : _ -> _) =O_(0 : U) (cst (1 : R^o)) -> continuous f.
Proof.
move=> /eqOP [_/posnumP[l]].
rewrite /= => /locally_normP [_/posnumP[d]]; rewrite /cst /=.
rewrite [`|[1 : R^o]|]absr1 mulr1 => fl.
have [{l fl}_ /posnumP[l] f_lipshitz] :
  exists2 l, l > 0 & forall x , `|[f x]| <= l * `|[x]|.
  exists (l%:num / (d%:num / 2)) => //.
  move=> x; have := fl ((d%:num / 2) * `|[x]| ^-1 *: x).
  rewrite /= sub0r normmN.
  (** BUG! in a vector space, the normm should be totally scalable : normmZ *)
  admit.
move=> x; apply/flim_normP => _/posnumP[eps]; rewrite !near_simpl.
rewrite (near_shift 0) /= subr0; near=> y => /=.
  rewrite -linearB opprD addrC addrNK linearN normmN.
  by rewrite (ler_lt_trans (f_lipshitz _)) // -ltr_pdivl_mull //; near: y.
end_near.
apply/locally_normP.
by eexists; last by move=> ?; rewrite /= sub0r normmN; apply.
Admitted.

End Linear3.

Arguments linear_continuous {U V s s_law} f _.

Section big_omega.

Context {K : absRingType} {T : Type} {V W : normedModType K}.

Definition bigOmega (F : set (set T)) (f : T -> V) (g : T -> W) :=
  exists2 k, k > 0 & \forall x \near F, `|[f x]| >= k * `|[g x]|.

Structure bigOmega_type (F : set (set T)) (g : T -> W) := BigOmega {
  bigOmega_fun :> T -> V;
  _ : `[< bigOmega F bigOmega_fun g >]
}.

Notation "{Omega_ F f }" := (@bigOmega_type F f)
  (at level 0, F at level 0, format "{Omega_  F  f }").

Canonical bigOmega_subtype (F : set (set T)) (g : T -> W) :=
  [subType for (@bigOmega_fun F g)].

Lemma bigOmega_class (F : set (set T)) (g : T -> W) (f : {Omega_F g}) :
  `[<bigOmega F f g>].
Proof. by case: f => ?. Qed.
Hint Resolve bigOmega_class.

Definition bigOmega_clone (F : set (set T)) (g : T -> W) (f : T -> V) (fT : {Omega_F g}) c
  of phant_id (bigOmega_class fT) c := @BigOmega F g f c.
Notation "[bigOmega 'of' f 'for' fT ]" := (@bigOmega_clone _ _ f fT _ idfun)
  (at level 0, f at level 0, format "[bigOmega  'of'  f  'for'  fT ]").
Notation "[bigOmega 'of' f ]" := (@bigOmega_clone _ _ f _ _ idfun)
  (at level 0, f at level 0, format "[bigOmega  'of'  f ]").

Definition is_bigOmega (F : set (set T)) (g : T -> W) :=
  [qualify f : T -> V | `[<bigOmega F f g>] ].
Fact is_bigOmega_key (F : set (set T)) (g : T -> W) : pred_key (is_bigOmega F g).
Proof. by []. Qed.
Canonical is_bigOmega_keyed (F : set (set T)) (g : T -> W) :=
  KeyedQualifier (is_bigOmega_key F g).
Notation "`Omega_ F g" := (is_bigOmega F g)
  (at level 0, F at level 0, format "`Omega_ F g").

Lemma bigOmegaP (F : set (set T)) (g : T -> W) (f : {Omega_F g}) :
  bigOmega F f g.
Proof. exact/asboolP. Qed.
Hint Extern 0 (bigOmega _ _ _) => solve[apply: bigOmegaP] : core.
Hint Extern 0 (locally _ _) => solve[apply: bigOmegaP] : core.
Hint Extern 0 (prop_near1 _) => solve[apply: bigOmegaP] : core.
Hint Extern 0 (prop_near2 _) => solve[apply: bigOmegaP] : core.

Lemma eqOmegaO (F : filter_on T) (f : T -> V) (e : T -> W) :
  f \is `Omega_F(e) <-> e =O_F f.
Proof.
split => [| /eqOP[x x0 Hx] ];
  [rewrite qualifE => /asboolP[x x0 Hx]; apply/eqOP |
   rewrite qualifE; apply/asboolP];
  exists x^-1; rewrite ?invr_gt0 //.
- near=> y; [by rewrite ler_pdivl_mull //; near: y | end_near].
- near=> y; [by rewrite ler_pdivr_mull //; near: y | end_near].
Qed.

(* TODO? other properties about Omega
   f = Omega(h) -> f + g = Omega(h)
   [Omega f1 of g1] * [Omega f2 of g2] = [Omega f1f2 of g1g2]
   f = Omega g -> g = Omega h -> f = Omega h *)

End big_omega.

Notation "`Omega_ F g" := (is_bigOmega F g)
  (at level 0, F at level 0, format "`Omega_ F g").

Section big_theta.

Context {K : absRingType} {T : Type} {V W : normedModType K}.

Definition bigTheta (F : set (set T)) (f : T -> V) (g : T -> W) :=
  exists2 k, ((k.1 > 0) && (k.2 > 0)) &
    \forall x \near F, k.1 * `|[g x]| <= `|[f x]| /\ `|[f x]| <= k.2 * `|[g x]|.

Definition is_bigTheta (F : set (set T)) (g : T -> W) :=
  [qualify f : T -> V | `[<bigTheta F f g>] ].
Fact is_bigTheta_key (F : set (set T)) (g : T -> W) : pred_key (is_bigTheta F g).
Proof. by []. Qed.

Canonical is_bigTheta_keyed (F : set (set T)) (g : T -> W) :=
  KeyedQualifier (is_bigTheta_key F g).
Notation "`Theta_ F g" := (is_bigTheta F g)
  (at level 0, F at level 0, format "`Theta_ F g").

Lemma bigThetaE (F : filter_on T) (f : T -> V) (g : T -> W) :
  f \is `Theta_F(g) <-> f =O_F g /\ f \is `Omega_F(g).
Proof.
split.
- rewrite qualifE => /asboolP[[/= k1 k2] /andP[k10 k20]] /near_andP[Hx1 Hx2].
  split; by [rewrite eqOP; exists k2|rewrite qualifE; apply/asboolP; exists k1].
- case; rewrite eqOP qualifE => -[k1 k10 H1] /asboolP[k2 k20 H2].
  rewrite qualifE; apply/asboolP; exists (k2, k1) => /=; first by rewrite k20.
  apply/near_andP; split; by near=> x; [near: x|end_near].
Qed.

(* TODO: properties about Theta
   [Theta h of f] + [O h of g] = [Theta h of f + g]
   [Theta f1 of g1] * [Theta f2 of g2] = [Theta f1f2 of g1g2]
   f = Omega g -> g = Omega h -> f = Omega h
   g =Theta f <-> f = Theta g
   f =Theta f *)

End big_theta.

Notation "`Theta_ F g" := (is_bigTheta F g)
  (at level 0, F at level 0, format "`Theta_ F g").

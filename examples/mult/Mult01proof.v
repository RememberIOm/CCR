Require Import HoareDef MultHeader Mult0 Mult1 SimModSem.
Require Import Coqlib.
Require Import ImpPrelude.
Require Import Skeleton.
Require Import PCM.
Require Import ModSem Behavior.
Require Import Relation_Definitions.

(*** TODO: export these in Coqlib or Universe ***)
Require Import Relation_Operators.
Require Import RelationPairs.
From ITree Require Import
     Events.MapDefault.
From ExtLib Require Import
     Core.RelDec
     Structures.Maps
     Data.Map.FMapAList.

Require Import STB ProofMode.
Require Import HTactics2.

Set Implicit Arguments.

Local Open Scope nat_scope.



Section SIMMODSEM.

  Context `{@GRA.inG fRA Σ}.
  Context `{@GRA.inG gRA Σ}.
  Context `{@GRA.inG hRA Σ}.

  Let W: Type := Any.t * Any.t.

  Let wf: _ -> W -> Prop :=
    @mk_wf
      _
      unit
      (fun _ _ st_tgt => ⌜True⌝%I)
  .

  Theorem correct: refines2 [Mult0.Mult (fun _ => to_stb GlobalStb0)] [Mult1.Mult (fun _ => to_stb GlobalStb1)].
  Proof.
    eapply adequacy_local2. econs; ss.
    i. econstructor 1 with (wf:=wf) (le:=top2); ss; et; swap 2 3.
    { esplits. econs; ss. eapply to_semantic. iIntros "H". iSplits; ss. }

    econs; [|ss].

    {
      (*** init ***)
      init.
      rename mp_tgt into mpr_tgt.
      assert(exists mp_src mp_tgt (mr_src mr_tgt: Σ),
                mrp_src = Any.pair mp_src mr_src↑ ∧ mpr_tgt = Any.pair mp_tgt mr_tgt↑).
      { inv WF. esplits; et. } des; clarify.
      (*** init ***)



      harg. mDesAll; clarify. steps.
      harg_tgt.
      { iFrame. iSplits; et. instantiate (1:=True%I); ss. }

      steps.


      hret _; ss.
      { iDestruct "Q" as "[[A B] %]". iModIntro. iFrame. iSplits; et. }
      { iDestruct "Q" as "[_ %]". clarify. iPureIntro. r. esplits; et. }
    }

    econs; [|ss].
    {
      (*** init ***)
      init.
      rename mp_tgt into mpr_tgt.
      assert(exists mp_src mp_tgt (mr_src mr_tgt: Σ),
                mrp_src = Any.pair mp_src mr_src↑ ∧ mpr_tgt = Any.pair mp_tgt mr_tgt↑).
      { inv WF. esplits; et. } des; clarify.
      (*** init ***)



      harg. mDesAll; clarify. steps.
      mAssert _ with "PRE" as "PRE".
      { iApply (OwnM_Upd with "PRE"). eapply f01_update. }
      mUpd "PRE".

      harg_tgt.
      { iFrame. iSplits; et. iAssumption. }

      unfold ccallU. steps. stb_tac; clarify. force_l; stb_tac; clarify. steps.


      hcall _ _ _.
      { iModIntro. iDestruct "P" as "[[A %] %]". clarify. iFrame. iSplits; ss; et. iAssumption. }
      { esplits; ss; et. }
      { i. iIntros "H". ss. iDestruct "H" as "[A %]". eauto. }
      mDesAll. clarify. steps. force_l; stb_tac; ss; clarify. steps.



      hpost_tgt.
      { iFrame. iSplits; et. iAssumption. }
      steps. rewrite _UNWRAPU. steps. stb_tac. clarify.



      hcall _ _ _.
      { iModIntro. iDestruct "P" as "[% %]". clarify. iFrame. iSplits; ss; et. instantiate (1:=True%I). ss. }
      { esplits; ss; et. }
      { i. iIntros "H". ss. iDestruct "H" as "[A %]". eauto. }
      clear_fast. mDesAll. clarify. steps.



      hpost_tgt.
      { iFrame. iSplits; et. iAssumption. } 
      steps. rewrite _UNWRAPU0. steps.


      hret _; ss.
      { iDestruct "Q" as "[[A B] %]". iPoseProof (OwnM_Upd with "A") as "A".
        { eapply f23_update. }
        iMod "A". iModIntro. iSplits; ss; et. iFrame. }
      { iDestruct "Q" as "[_ %]". iPureIntro. clarify. r. esplits; et. }
    }

  Unshelve. all: ss. all: try exact 0.
  Qed.

End SIMMODSEM.

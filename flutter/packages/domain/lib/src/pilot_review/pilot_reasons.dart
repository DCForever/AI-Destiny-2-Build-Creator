/// Stable reason codes. They describe source gaps. They do not fill them.
abstract final class PilotReason {
  static const invalidSolipsism = 'invalid_solipsism_subclass';
  static const solipsismSubclassUnstated = 'solipsism_subclass_unstated';
  static const blankDoes = 'blank_does';
  static const absentDoes = 'absent_does';
  static const blankLoop = 'blank_loop';
  static const absentLoop = 'absent_loop';
  static const solipsismPerksUnresolved = 'solipsism_perks_unresolved';
  static const ergoTraitUnresolved = 'ergo_trait_unresolved';
  static const ergoElementUnresolved = 'ergo_element_unresolved';
  static const ergoFrameUnresolved = 'ergo_frame_unresolved';
  static const notesSetConflict = 'notes_set_conflict';
  static const doesNotesConflict = 'does_notes_conflict';
  static const loopNotesConflict = 'loop_notes_conflict';
  static const setProposalConflict = 'set_proposal_conflict';
  static const perkLabelConflict = 'perk_label_conflict';
  static const linkPathMismatch = 'link_path_mismatch';
}

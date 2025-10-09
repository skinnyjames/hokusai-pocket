class Hokusai::Blocks::Clipped < Hokusai::Block
  style <<-EOF
  [style]
  scissorStyle {
    height: 0.0;
    width: 0.0;
  }
  EOF

  template <<-EOF
  [template]
    scissorbegin { :auto="auto" :offset="offset" }
      slot
      scissorend { ...scissorStyle }
  EOF

  uses(
    scissorbegin: Hokusai::Blocks::ScissorBegin,
    scissorend: Hokusai::Blocks::ScissorEnd,
  )

  # automatically subtracts the offset from canvas.y
  computed :auto, default: true
  computed :offset, default: 0.0
end
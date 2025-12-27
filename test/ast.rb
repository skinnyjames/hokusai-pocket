class AstCommonTest < Hokusai::Test
  let(:template) do
    <<~EOF
    [template]
      first#id.class1.class2 { prop1="one" prop2="two" prop3="three" @event1="first" @event2="second" }
    EOF
  end

  let(:parent) do
    Hokusai::Ast.parse(template, "root")
  end

  let(:ast) { parent.children.first }

  test ".parse returns a new ast from a template" do
    expect(parent.class).to eql(Hokusai::Ast), "#{ast.class} not #{Hokusai::Ast}"
  end

  test "#type returns the ast type" do
    expect(ast.type).to eql("first")
  end

  test "#id returns the ast id" do
    expect(ast.id).to eql("id")
  end

  test "props returns hash of props" do
    expect(ast.props.keys).to include(%w[prop1 prop2 prop3])
    funcs = ast.props.values.map {|prop| prop.value.method }

    expect(funcs).to include(%w[one two three])
  end
end

class AstPropTest < Hokusai::Test
  let(:template) do
  <<~EOF
    [template]
      first { :computed="true" }
      second { notcomputed="true" }
  EOF
  end

  let(:parent) do
    Hokusai::Ast.parse(template, "root")
  end

  let(:ast) { parent.children.first }

  test "returns nil if a prop is not found" do
    expect(ast.prop("nope")).to be(nil)
  end

  test "returns a Hokusai::Ast::Prop" do
    prop1 = parent.children[0].prop("computed")
    prop2 = parent.children[1].prop("notcomputed")

    expect(prop1.class).to eql(Hokusai::Ast::Prop)
    expect(prop1.value.method).to eql("true")
    expect(prop1.computed?).to be(true)

    expect(prop2.computed?).to be(false)
  end
end

class AstEventTest < Hokusai::Test
  let(:template) do
    <<~EOF
      [template]
        first { @click="handle_click", @hover="handle_hover" }
    EOF
  end

  let(:parent) do
    Hokusai::Ast.parse(template, "root")
  end

  let(:ast) { parent.children.first }

  test "returns nil if an event isn't found" do
    expect(ast.event("none")).to be(nil)
  end

  test "returns a Hokusai::Ast::Event" do
    event = ast.event("hover")
    expect(event.class).to eql(Hokusai::Ast::Event)
    expect(event.name).to eql("hover")
    expect(event.value.method).to eql("handle_hover")
  end
end
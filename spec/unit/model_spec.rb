RSpec.describe Evil::Client::Model do
  before { class Test::Model < described_class; end }

  let(:model)    { klass.new(**options) }
  let(:klass)    { Test::Model }
  let(:options)  { { "id" => 42, "name" => "Andrew" } }
  let(:dsl_methods) do
    %i[options datetime logger scope basic_auth key_auth token_auth]
  end

  describe ".policy" do
    subject { klass.policy }

    it "subclasses Evil::Client::Policy" do
      expect(subject.superclass).to eq described_class.policy
      expect(described_class.policy.superclass).to eq Tram::Policy
    end

    it "refers back to the model" do
      expect(subject.model).to eq klass
    end
  end

  describe ".option" do
    it "is defined by Dry::Initializer DSL" do
      expect(klass).to be_a Dry::Initializer
    end

    it "fails when method name is reserved for DSL" do
      dsl_methods.each do |name|
        expect { klass.option name }
          .to raise_error Evil::Client::NameError
      end
    end

    it "allows the option to be renamed" do
      expect { klass.option :basic_auth, as: :something }.not_to raise_error
    end
  end

  describe ".let" do
    before do
      klass.option :id
      klass.let(:square_id) { id**2 }
    end

    subject { model.square_id }

    it "adds the corresponding memoizer to the instance" do
      expect(subject).to eq(42**2)
    end

    it "fails when method name is reserved for DSL" do
      dsl_methods.each do |name|
        expect { klass.let(name) { 0 } }
          .to raise_error Evil::Client::NameError
      end
    end
  end

  describe ".validate" do
    before do
      klass.option :name
      klass.validate { errors.add :name_present if name.to_s == "" }
    end

    let(:options) { { "name" => "" } }

    it "adds validation for an instance" do
      # see spec/fixtures/locale/en.yml
      expect { model }
        .to raise_error(StandardError, /The user has no name/)
    end
  end

  describe ".new" do
    subject { model }

    context "with wrong options" do
      before { klass.option :user, as: :customer }

      it "raises StandardError" do
        expect { subject }.to raise_error StandardError, /user/
      end
    end
  end

  describe ".extend" do
    before do
      class Test::Other < described_class
        option :first_name, optional: true
        option :last_name,  optional: true

        let(:name) { [first_name, last_name].compact.join(" ") }

        validate { errors.add :empty_name if name == "" }
      end

      class Test::Model < described_class
        extend Test::Other
        option :email, optional: true
      end
    end

    let(:options) do
      { first_name: "Joe", last_name: "Doe", email: "joe@example.com" }
    end

    subject { model }

    it "behaves like a model" do
      expect(subject).to be_a klass
      expect(subject.email).to eq "joe@example.com"
    end

    it "injects options from the other model" do
      expect(subject.first_name).to eq "Joe"
      expect(subject.last_name).to  eq "Doe"
    end

    it "injects memoizers from the other model" do
      expect(subject.name).to eq "Joe Doe"
    end

    context "with invalid options" do
      let(:options) { { email: "joe@example.com" } }

      it "injects validators from the other model" do
        expect { subject }.to raise_error(StandardError, /name/)
      end
    end
  end
end

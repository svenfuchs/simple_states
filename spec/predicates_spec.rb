describe SimpleStates, 'predicates' do
  let(:klass) do
    create_class do
      attr_accessor :started_at, :finished_at
      event :start
      event :finish, to: [:passed, :failed, :errored, :canceled]
    end
  end

  let(:obj) { klass.new(:started) }

  describe 'state?' do
    describe 'when the object has the given state' do
      it { expect(obj.state?(:started)).to eq true }
    end

    describe 'when the object does not have the given state' do
      it { expect(obj.state?(:passed)).to eq false }
    end
  end

  describe 'when the object has the state :started' do
    describe 'it responds to started?' do
      it { expect(obj.respond_to?(:started?)).to eq true }
    end

    describe 'it responds to passed?' do
      it { expect(obj.respond_to?(:passed?)).to eq true }
    end

    describe 'it does not respond to finished?' do
      it { expect(obj.respond_to?(:finished?)).to eq false }
    end

    describe 'started? returns true' do
      it { expect(obj.started?).to eq true }
    end

    describe 'passed? returns false' do
      it { expect(obj.passed?).to eq false }
    end
  end

  describe 'when the event :accept is not defined' do
    describe 'it does not respond to accepted?' do
      it { expect(obj.respond_to?(:accepted?)).to eq false }
    end

    describe 'accepted? raises NoMethodError' do
      it { expect { obj.accepted? }.to raise_error(NoMethodError) }
    end
  end

  describe 'when [state]? defined on the class body' do
    before { klass.send(:define_method, :started?) { false } }
    it { expect(obj.started?).to eq false }
  end
end

describe SimpleStates do
  let(:klass) { create_class }
  let(:obj) { klass.new }

  describe 'initial state' do
    describe 'uses :created by default' do
      it { expect(obj.state).to eq :created }
      it { expect(obj.state?(:created)).to eq true }
      it { expect(obj.created?).to eq true }
    end

    describe 'uses a custom initial state' do
      before { klass.initial_state = :started }
      it { expect(obj.state).to eq :started }
      it { expect(obj.state?(:started)).to eq true }
      it { expect(obj.started?).to eq true }
    end
  end

  describe 'exceptions' do
    describe 'invalid target state' do
      before { klass.event :finish, to: [:passed, :failed] }
      it { expect { obj.finish }.to raise_error(SimpleStates::Error, /a valid target state must be passed as an attribute/) }
    end

    describe 'unknown target state' do
      before { klass.event :finish }
      before { klass.send(:define_method, :finish) { self.state = :kaputt } }
      it { expect { obj.finish }.to raise_error(SimpleStates::Error, /Unknown state :kaputt.*Known states are: \[:created, :finished\]/) }
    end
  end
end

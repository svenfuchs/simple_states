describe SimpleStates, 'event' do
  let(:klass) do
    create_class do
      attr_accessor :started_at, :finished_at, :log
      event :start
      event :finish, to: [:passed, :failed, :errored, :canceled]
    end
  end

  let(:obj) { klass.new }

  describe 'returns true' do
    it { expect(obj.start).to eq true }
  end

  describe 'sets the state' do
    describe 'derives the target state name from the event' do
      it { expect { obj.start }.to change { obj.state }.to(:started) }
    end

    describe 'uses a given target state name' do
      before { klass.event :receive, to: :booting }
      it { expect { obj.receive }.to change { obj.state }.to(:booting) }
    end

    describe 'uses a state passed as an attributes' do
      it { expect { obj.finish(state: :passed) }.to change { obj.state }.to(:passed) }
    end
  end

  describe 'sets an event timestamp' do
    describe 'when no timestamp is passed' do
      it { expect { obj.start }.to change { obj.started_at }.to(Time.now.utc) }
    end

    describe 'when a timestamp is passed' do
      let(:attrs) { { started_at: now - 60, state: "started" } }
      it { expect { obj.start(attrs) }.to change { obj.started_at }.to(attrs[:started_at]) }
    end
  end

  describe 'ignores timestamp' do
    describe 'when started_at had been set earlier' do
      let(:attrs) { { started_at: now - 60, finished_at: now - 50, state: "passed" } }
      let(:early) { now - 55 }
      before      { obj.started_at = early }
      before      { obj.finish(attrs) }
      it { expect(obj.started_at).to eq early }
      it { expect(obj.finished_at).to eq attrs[:finished_at] }
    end

    describe 'when finished_at had been set earlier' do
      let(:attrs) { { started_at: now - 60, finished_at: now - 50, state: "passed" } }
      let(:early) { now - 45 }
      before      { obj.finished_at = early }
      before      { obj.finish(attrs) }
      it { expect(obj.started_at).to eq attrs[:started_at] }
      it { expect(obj.finished_at).to eq early }
    end
  end

  describe 'accepts an arbitrary attribute' do
    before { klass.send(:attr_accessor, :foo) }
    it { expect { obj.start(foo: :bar) }.to change { obj.foo }.to(:bar) }
  end

  describe 'calls a method with the same name after setting the state' do
    before { klass.send(:define_method, :start) { |*| self.log = state } }
    it { expect { obj.start }.to change { obj.log }.to(:started) }
  end
end

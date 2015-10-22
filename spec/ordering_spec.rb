describe SimpleStates, 'ordering' do
  let(:klass) do
    create_class do
      attr_accessor :started_at, :finished_at
      event :start
      event :finish
    end
  end

  let(:obj) { klass.new }

  shared_examples_for 'accepts the event' do
    it { expect(obj.finish).to eq true }
    it { expect { obj.finish }.to change { obj.state } }
    it { expect { obj.finish }.to change { obj.finished_at } }
  end

  shared_examples_for 'skips the event' do
    it { expect(obj.start).to eq false }
    it { expect { obj.start }.to_not change { obj.state } }
    it { expect { obj.start }.to_not change { obj.started_at } }
  end

  describe 'both states well known' do
    describe 'in order' do
      before { obj.start }
      include_examples 'accepts the event'
    end

    describe 'out of order' do
      before { obj.finish }
      include_examples 'skips the event'
    end
  end

  describe 'with an unknown initial state' do
    before { obj.state = :queued }

    describe 'in order' do
      before { obj.start }
      include_examples 'accepts the event'
    end

    describe 'out of order' do
      before { obj.finish }
      include_examples 'skips the event'
    end
  end
end

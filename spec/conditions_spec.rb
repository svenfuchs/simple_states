describe SimpleStates, 'conditions' do
  let(:klass)  { create_class { attr_accessor :started_at } }
  let(:obj)    { klass.new }

  describe ':if' do
    before { klass.event :start, if: :start? }

    describe 'if the condition applies' do
      before { klass.send(:define_method, :start?) { true } }

      describe 'sets the state' do
        it { expect { obj.start }.to change { obj.state }.from(:created).to(:started) }
      end

      describe 'sets the timestamp' do
        it { expect { obj.start }.to change { obj.started_at }.from(nil).to(Time.now.utc) }
      end

      describe 'returns true' do
        it { expect(obj.start).to eq true }
      end
    end

    describe 'if the condition fails' do
      before { klass.send(:define_method, :start?) { false } }

      describe 'does not set the state' do
        it { expect { obj.start }.to_not change { obj.state } }
      end

      describe 'does not set the timestamp' do
        it { expect { obj.start }.to_not change { obj.started_at } }
      end

      describe 'returns false' do
        it { expect(obj.start).to eq false }
      end
    end
  end

  describe ':unless' do
    before { klass.event :start, unless: :invalid? }

    describe 'if the condition applies' do
      before { klass.send(:define_method, :invalid?) { false } }

      describe 'sets the state' do
        it { expect { obj.start }.to change { obj.state }.from(:created).to(:started) }
      end

      describe 'sets the timestamp' do
        it { expect { obj.start }.to change { obj.started_at }.from(nil).to(Time.now.utc) }
      end

      describe 'returns true' do
        it { expect(obj.start).to eq true }
      end
    end

    describe 'if the condition fails' do
      before { klass.send(:define_method, :invalid?) { true } }

      describe 'does not set the state' do
        it { expect { obj.start }.to_not change { obj.state } }
      end

      describe 'does not set the timestamp' do
        it { expect { obj.start }.to_not change { obj.started_at } }
      end

      describe 'returns false' do
        it { expect(obj.start).to eq false }
      end
    end
  end
end

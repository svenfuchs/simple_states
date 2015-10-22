describe SimpleStates, 'callbacks' do
  let(:klass) do
    create_class do
      attr_reader :events

      def log(event)
        @events ||= []
        @events << event
      end
    end
  end

  let(:obj) { klass.new }

  describe ':before' do
    describe 'defined on an event' do
      before do
        klass.event :start, before: :log
      end

      before { obj.start }
      it { expect(obj.events).to eq [:start] }
    end

    describe 'defined using :all' do
      before do
        klass.event :start
        klass.event :finish
        klass.event :all, before: :log
      end

      before { [:start, :finish].each { |event| obj.send(event) } }
      it { expect(obj.events).to eq [:start, :finish] }
    end
  end

  describe ':after' do
    describe 'defined on an event' do
      before do
        klass.event :start, after: :log
      end

      before { obj.start }
      it { expect(obj.events).to eq [:start] }
    end

    describe 'defined using :all' do
      before do
        klass.event :start
        klass.event :finish
        klass.event :all, after: :log
      end

      before { [:start, :finish].each { |event| obj.send(event) } }
      it { expect(obj.events).to eq [:start, :finish] }
    end
  end

  describe 'arity' do
    let(:klass) { create_class { event :start, after: :log; attr_reader :args } }

    describe 'zero arguments' do
      before { klass.send(:define_method, :log) {} }
      it { expect { obj.start }.to_not raise_error }
    end

    describe 'defining one argument' do
      describe 'without a default' do
        before { klass.send(:define_method, :log) { |event| @args = [event] } }

        describe 'without any arguments passed' do
          before { obj.start }
          it { expect(obj.args).to eq [:start] }
        end

        describe 'with an attrs hash passed' do
          before { obj.start(started_at: Time.now.utc) }
          it { expect(obj.args).to eq [:start] }
        end
      end

      describe 'with a default' do
        before { klass.send(:define_method, :log) { |event = nil| @args = [event] } }

        describe 'without any arguments passed' do
          before { obj.start }
          it { expect(obj.args).to eq [:start] }
        end

        describe 'with an attrs hash passed' do
          before { obj.start(started_at: Time.now.utc) }
          it { expect(obj.args).to eq [:start] }
        end
      end
    end

    describe 'defining two arguments' do
      describe 'without a default' do
        before { klass.send(:define_method, :log) { |event, attrs| @args = [event, attrs] } }

        describe 'without any arguments passed' do
          before { obj.start }
          it { expect(obj.args).to eq [:start, {}] }
        end

        describe 'with an attrs hash passed' do
          let(:attrs) { { started_at: Time.now.utc } }
          before { obj.start(attrs) }
          it { expect(obj.args).to eq [:start, attrs] }
        end
      end

      describe 'with a default on attrs' do
        before { klass.send(:define_method, :log) { |event, attrs = {}| @args = [event, attrs] } }

        describe 'without any arguments passed' do
          before { obj.start }
          it { expect(obj.args).to eq [:start, {}] }
        end

        describe 'with an attrs hash passed' do
          let(:attrs) { { started_at: Time.now.utc } }
          before { obj.start(attrs) }
          it { expect(obj.args).to eq [:start, attrs] }
        end
      end

      describe 'with a default on both event and attrs' do
        before { klass.send(:define_method, :log) { |event = nil, attrs = {}| @args = [event, attrs] } }

        describe 'without any arguments passed' do
          before { obj.start }
          it { expect(obj.args).to eq [:start, {}] }
        end

        describe 'with an attrs hash passed' do
          let(:attrs) { { started_at: Time.now.utc } }
          before { obj.start(attrs) }
          # Ruby's method arity is -1 in this case, too. Not sure if there's a way to fix this.
          it { expect(obj.args).to eq [:start, {}] }
        end
      end
    end
  end
end


#
# specifying flor
#
# Fri Jun  3 06:09:21 JST 2016
#

require 'spec_helper'


describe 'Flor punit' do

  before :each do

    @unit = Flor::Unit.new('envs/test/etc/conf.json')
    @unit.conf['unit'] = 'pu_concurrence'
    @unit.hooker.add('journal', Flor::Journal)
    @unit.storage.delete_tables
    @unit.storage.migrate
    @unit.start
  end

  after :each do

    @unit.shutdown
  end

  describe 'concurrence' do

    it 'has no effect when empty' do

      msg = @unit.launch(
        %q{
          concurrence _
        },
        wait: true)

      expect(msg['point']).to eq('terminated')
    end

    it 'has no effect when empty (2)' do

      msg = @unit.launch(
        %q{
          concurrence tag: 'z'
        },
        wait: true)

      expect(msg['point']).to eq('terminated')

      wait_until { @unit.journal.find { |m| m['point'] == 'terminated' } }
      wait_until { @unit.journal.find { |m| m['point'] == 'end' } }

      expect(
        @unit.journal
          .collect { |m|
            [ m['point'], m['nid'], (m['tags'] || []).join(',') ].join(':') }
          .join("\n")
      ).to eq(%w[
        execute:0:
        execute:0_0:
        execute:0_0_0:
        receive:0_0:
        execute:0_0_1:
        receive:0_0:
        entered:0:z
        receive:0:
        receive::
        left:0:z
        terminated::
        end::
      ].join("\n"))
    end

    it 'executes atts in sequence then children in concurrence' do

      msg = @unit.launch(
        %q{
          concurrence tag: 'x', nada: 'y'
            trace 'a'
            trace 'b'
        },
        wait: true)

      expect(msg['point']).to eq('terminated')

      expect(
        @unit.traces.collect(&:text).join(' ')
      ).to eq(
        'a b'
      )

      expect(
        @unit.journal
          .collect { |m| [ m['point'][0, 3], m['nid'] ].join(':') }
      ).to comprise(%w[
        exe:0_2 exe:0_3
        exe:0_2_0 exe:0_3_0
        exe:0_2_0_0 exe:0_3_0_0
      ])
    end

    describe 'by default' do

      it 'merges all the payload, first reply wins' do

        msg = @unit.launch(
          %q{
            concurrence
              set f.a 0
              set f.a 1
              set f.b 2
          },
          wait: true)

        expect(msg['point']).to eq('terminated')
        expect(msg['payload']).to eq({ 'ret' => nil, 'a' => 0, 'b' => 2 })
      end
    end

    describe 'expect:' do

      it 'accepts an integer > 0' do

        msg = @unit.launch(
          %q{
            concurrence expect: 1
              set f.a 0
              set f.b 1
          },
          wait: true)

        expect(msg['point']).to eq('terminated')
        expect(msg['payload']).to eq({ 'ret' => nil, 'a' => 0 })

        wait_until { @unit.journal.find { |m| m['point'] == 'terminated' } }

        expect(
          @unit.journal
            .collect { |m| [ m['point'][0, 3], m['nid'] ].join(':') }
        ).to comprise(%w[
          rec:0 rec:0 can:0_2 rec: ter:
        ])
      end
    end

    context 'remaining:' do

      context "'forget'" do

        it 'prevents child cancelling' do

          msg = @unit.launch(
            %q{
              concurrence expect: 1 rem: 'forget'
                set f.a 0
                set f.b 1
            },
            wait: true)

          expect(msg['point']).to eq('terminated')
          expect(msg['payload']).to eq({ 'ret' => nil, 'a' => 0 })

          wait_until { @unit.journal.find { |m| m['point'] == 'terminated' } }

          expect(
            @unit.journal
              .collect { |m| [ m['point'][0, 3], m['nid'] ].join(':') }
          ).to comprise(%w[
            rec:0 rec:0 rec: ter:
          ])
        end
      end

      context "'wait'" do

        # ruote said:
        # There is a third setting, ‘wait’. It behaves like ‘cancel’, but the
        # concurrence waits for the cancelled children to reply. The workitems
        # from cancelled branches are merged in as well.

        it 'waits for the cancelled children' do

          msg = @unit.launch(
            %q{
              concurrence expect: 1 rem: 'wait'
                set f.a 0
                sleep 1
            },
            wait: true)

          expect(msg['point']).to eq('terminated')
          expect(msg['payload']).to eq({ 'ret' => nil, 'a' => 0 })

          wait_until { @unit.journal.find { |m| m['point'] == 'terminated' } }

          concurrence_over = @unit.journal.find { |m|
            m['point'] == 'receive' && m['from'] == '0' }
          sleep_over = @unit.journal.find { |m|
            m['point'] == 'receive' && m['nid'] == '0' && m['from'] == '0_3' }

          expect(concurrence_over['m']).to be.>(sleep_over['m'])
        end
      end
    end

    context 'upon cancelling' do

      it 'cancels all its children' do

        msg = @unit.launch(
          %q{
            concurrence
              task 'hole'
              task 'hole'
          },
          wait: '0_1 task')

        r = @unit.queue(
          { 'point' => 'cancel', 'exid' => msg['exid'], 'nid' => '0' },
          wait: true)

        expect(r['point']).to eq('terminated')

        wait_until do
          m = @unit.journal.last
          m['point'] == 'end' && m['er'] == 3
        end

        expect(
          @unit.journal
            .drop_while { |m|
              m['point'] != 'task' }
            .collect { |m|
              [ "m#{m['m']}s#{m['sm']}",
                "e#{m['er']}p#{m['pr']}",
                m['point'], m['nid'] ].join('-') }
            .join("\n")
        ).to eq(%w[
              m12s10-e1p1-task-0_0
              m13s11-e1p1-task-0_1
ms-e1p1-end-
            m14s-ep2-cancel-0
              m15s14-e2p2-cancel-0_0
              m16s14-e2p2-cancel-0_1
              m17s15-e2p2-detask-0_0
              m18s16-e2p2-detask-0_1
ms-e2p2-end-
              m19s-ep3-return-0_0
              m20s-ep3-return-0_1
              m21s-e3p3-receive-0_0
              m22s-e3p3-receive-0_1
            m23s21-e3p3-receive-0
            m24s22-e3p3-receive-0
          m25s24-e3p3-receive-
          m26s25-e3p3-terminated-
ms-e3p3-end-
        ].join("\n"))
      end
    end
  end
end


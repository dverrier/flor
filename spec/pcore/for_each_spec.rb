
#
# specifying flor
#
# Sat Oct 28 06:14:36 JST 2017
#

require 'spec_helper'


describe 'Flor procedures' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'for-each' do

    it 'iterates over each array element' do

      r = @executor.launch(
        %q{
          set l []
          for-each [ 0 1 2 3 4 5 6 7 ]
            def x
              pushr l (2 * x) if x % 2 == 0
        })

      expect(r['point']).to eq('terminated')
      expect(r['vars']).to eq({ 'l' => [ 0, 4, 8, 12 ] })
      expect(r['payload']['ret']).to eq((0..7).to_a)
    end

    it 'iterates over each object entry' do

      r = @executor.launch(
        %q{
          set l []
          for-each { a: 'A', b: 'B', c: 'C' }
            def k v i
              pushr l (+ k v i)
        })

      expect(r['point']
        ).to eq('terminated')
      expect(r['vars']
        ).to eq({ 'l' => %w[ aA0 bB1 cC2 ] })
      expect(r['payload']['ret']
        ).to eq({ 'a' => 'A', 'b' => 'B', 'c' => 'C' })
    end
  end
end


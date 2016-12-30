
#
# specifying flor
#
# Fri Dec 30 05:41:07 JST 2016  Ishinomaki
#

require 'spec_helper'


describe 'Flor core' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  # NOTA BENE: using "concurrence" even though it's deemed "unit" and not "core"

  describe 'cancel' do

     it 'cancels' do

       flon = %{
         concurrence
           sequence # 0_0
             stall _
           sequence
             _skip 1
             cancel '0_0'
       }

       r = @executor.launch(flon, archive: true)

       expect(r['point']).to eq('terminated')

       seq = @executor.archive['0_0']

       expect(
         seq['status'][0, 4]
       ).to eq(
         [ 'cancelled', 'cancel', '0_1_1', nil ]
       )

       expect(
         @executor.journal
           .select { |m| m['point'] == 'cancel' }
           .size
       ).to eq(
         2
       )
     end

     it "doesn't over-cancel" do

       flon = %{
         concurrence
           sequence # 0_0
             sequence
               sequence
                 sequence
                   sequence
                     sequence
                       sequence
                         stall _
           sequence
             _skip 1
             cancel '0_0'
             _skip 1
             cancel '0_0'
       }

       r = @executor.launch(flon, archive: true)

       expect(r['point']).to eq('terminated')

       seq = @executor.archive['0_0']

       expect(
         seq['status'][0, 4]
       ).to eq(
         [ 'cancelled', 'cancel', '0_1_1', nil ]
       )
     end

     it 'over-cancels if flavoured' # kill ???????????????????????????????????

     it 'cancels with "cancel" flavour even if aliased' do

       flon = %{
         set fukup cancel
         concurrence
           sequence # 0_1_0
             stall _
           sequence
             _skip 1
             fukup '0_1_0'
       }

       r = @executor.launch(flon, archive: true)

       expect(r['point']).to eq('terminated')

       seq = @executor.archive['0_1_0']

       expect(
         seq['status'][0, 4]
       ).to eq(
         [ 'cancelled', 'cancel', '0_1_1_1', nil ]
       )
     end
  end
end

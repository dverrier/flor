
class Flor::Pro::Range < Flor::Procedure
  #
  # "range" is a procedure to generate ranges of integers.
  #
  # ```
  # # range {end}
  # # range {start} {end}
  # # range {start} {end} {step}
  # range 0         #--> []
  # range 4         #--> [ 0, 1, 2, 3 ]
  # range 4 7       #--> [ 4, 5, 6 ]
  # range 4 14 2    #--> [ 4, 6, 8, 10, 12 ]
  # range (-4)      #--> [ 0, -1, -2, -3 ]
  # range 9 1 (-2)  #--> [ 9, 7, 5, 3 ] ]
  # ```

  name 'range'

  def pre_execute

    @node['rets'] = []
    #@node['atts'] = []

    unatt_unkeyed_children
  end

  def receive_last

    rets = @node['rets'].select { |r| r.is_a?(Numeric) }.collect(&:to_i)

    sta = rets[1] ? rets[0] : 0
    edn = rets[1] || rets[0]
    ste = rets[2] || ((sta > edn) ? -1 : 1)

    fail ArgumentError.new("#{@node['heat0']} step is 0") if ste == 0

    #payload['ret'] = (sta..edn - 1).step(ste).to_a
      # doesn't accept negative steps

    payload['ret'] = []
    cur = sta
      #
    loop do
      break if (ste < 0) ? (cur <= edn) : (cur >= edn)
      payload['ret'] << cur
      cur = cur + ste
    end

    super
  end
end


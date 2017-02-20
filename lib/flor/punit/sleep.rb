
class Flor::Pro::Sleep < Flor::Procedure
  #
  # Makes a branch of an execution sleep for a while.
  #
  # ```
  # sleep '1y'       # sleep for one year
  # sleep for: '2y'  # sleep for two years, with an explicit for:
  # sleep '2d1m10s'  # sleep for two days, one minute and ten seconds
  # ```

  name 'sleep'

  def pre_execute

    @node['atts'] = []
  end

  def receive_last

    t = att('for', nil)
    fail ArgumentError.new("missing a sleep time duration") unless t

    m = reply('point' => 'receive').first

    schedule('type' => 'in', 'string' => t, 'message' => m)
  end
end


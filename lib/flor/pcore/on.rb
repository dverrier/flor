
class Flor::Pro::On < Flor::Macro
  #
  # Catches signals or errors.
  #
  # ## signals
  #
  # Turns
  # ```
  # on 'approve'
  #   task 'bob' mission: 'gather signatures'
  # ```
  # into
  # ```
  # trap point: 'signal', name: 'approve'
  #   def msg
  #     task 'bob' mission: 'gather signatures'
  # ```
  #
  # It's OK trapping multiple signal names:
  # ```
  # on [ /^bl/ 'red' 'white' ]
  #   task 'bob' mission: "order can of $(sig) paint"
  # ```
  #
  # ## errors
  #
  # TODO
  #
  #
  # ## see also
  #
  # Trap and signal.

  name 'on'

  def rewrite_tree

    if att = find_catch # 22
      rewrite_as_catch_tree(att)
    else
      rewrite_as_trap_tree
    end
  end

  protected

  CATCHES = %w[ error ]
  #CATCHES = %w[ error cancel timeout ]

  def find_catch

    att_children
      .each_with_index { |t, i|
        tt = t[1].is_a?(Array) && t[1].length == 1 && t[1].first
        return [ tt[0], i ] if tt && tt[1] == [] && CATCHES.include?(tt[0]) }

    nil
  end

  def rewrite_as_catch_tree(att)

    flavour, index = att

    atts = att_children
    atts.delete_at(index)

    l = tree[2]

    th = [ "on_#{flavour}", [], l, *tree[3] ]
    atts.each { |ac| th[1] << Flor.dup(ac) }

    td = [ 'def', [], l ]
    td[1] << [ '_att', [ [ 'msg', [], l ] ], l ]
    td[1] << [ '_att', [ [ 'err', [], l ] ], l ] if flavour == 'error'
    non_att_children.each { |nac| td[1] << Flor.dup(nac) }

    th[1] << td

    th
  end

  def rewrite_as_trap_tree

    atts = att_children
    signame_i = atts.index { |at| at[1].size == 1 }

    fail Flor::FlorError.new("signal name not found in #{tree.inspect}", self) \
      unless signame_i

    tname = atts[signame_i]
    tname = Flor.dup(tname[1][0])
    atts.delete_at(signame_i)

    l = tree[2]

    th = [ 'trap', [], l, *tree[3] ]
    th[1] << [ '_att', [ [ 'point', [], l ], [ '_sqs', 'signal', l ] ], l ]
    th[1] << [ '_att', [ [ 'name', [], l ], tname ], l ]
    th[1] << [ '_att', [ [ 'payload', [], l ], [ '_sqs', 'event', l ] ], l ]
    atts.each { |ac| th[1] << Flor.dup(ac) }

    td = [ 'def', [], l ]
    td[1] << [ '_att', [ [ 'msg', [], l ] ], l ]
    non_att_children.each { |nac| td[1] << Flor.dup(nac) }

    th[1] << td

    th
  end
end

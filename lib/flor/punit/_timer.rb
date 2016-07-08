#--
# Copyright (c) 2015-2016, John Mettraux, jmettraux+flon@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


class Flor::Pro::UnderTimer < Flor::Procedure

  name '_timer'

  def pre_execute

    @node['atts'] = []
  end

  def receive_last

    (att('_timeout') ? schedule_timeout : schedule_execution) +
    super
  end

  protected

  def schedule_timeout

    t = att('in') || att('after') || att('at')

    tnid, cnid = determine_timers_cnid_parents

    m =
      reply(
        'point' => 'cancel',
        'nid' => tnid,
        'from' => tnid,
        'flavour' => 'timeout',
        'payload' => parent_node['payload']
      ).first

    schedule('in' => t, 'nid' => tnid, 'message' => m)
  end

  def schedule_execution

    t = att('in') || att('after') || att('at')

    tnid, cnid = determine_timers_cnid_parents

    m =
      reply(
        'point' => 'execute',
        'nid' => nid,
        'from' => tnid,
        'noreply' => true,
        'payload' => parent_node['payload']
      ).first

    if cnid
      m['cnid'] = cnid
      (@execution['nodes'][cnid]['closures'] ||= []) << nid
    end

    schedule('in' => t, 'message' => m, 'nid' => tnid)
  end

  def determine_timers_cnid_parents

    cnid = nil
    n = parent_node

    loop do
      cnid = n['nid'] if n['cnid']
      head = lookup_tree(n['nid'])[0]
      n = @execution['nodes'][n['parent']]
      break if head == 'timers'
    end

    [ n['nid'], cnid ]
  end
end


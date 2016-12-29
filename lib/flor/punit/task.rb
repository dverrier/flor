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


class Flor::Pro::Task < Flor::Procedure

  name 'task'

  def pre_execute

    @node['atts'] = []

    @node['patts'] = payload['atts'] if payload.has_key?('atts')
  end

  def do_receive

    return reply('payload' => determine_reply_payload) \
      if point == 'receive' && from == nil

    super
      # which goes to #receive or #receive_when_status
  end

  def receive_last_att

    queue(
      'point' => 'task',
      'exid' => exid, 'nid' => nid,
      'tasker' => att(nil),
      'payload' => determine_payload)
  end

  def cancel

    queue(
      'point' => 'detask',
      'exid' => exid, 'nid' => nid,
      'tasker' => att(nil),
      'payload' => determine_payload)
  end

  protected

  def determine_payload

    message_or_node_payload.merge(
      'atts' => @node['atts'].inject({}) { |h, (k, v)| h[k] = v if k; h })
  end

  def determine_reply_payload

    pl = Flor.dup(payload.current)

    if @node.has_key?('patts')
      pl['atts'] = Flor.dup(@node['patts'])
    else
      pl.delete('atts')
    end

    pl
  end
end


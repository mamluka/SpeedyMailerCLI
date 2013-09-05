require 'erb'
require 'ostruct'
opts = OpenStruct.new({
                          david: 'david',
                          cool: 2
                      })

s = ERB.new "sdfdsf <%= cool %>"

p s.result(opts.instance_eval {binding})

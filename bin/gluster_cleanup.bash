#!/bin/bash
cd /opt/gina/nrt-app-1.4.3g-20230420211225/
. env.sh

rails console << EOF
ActiveRecord::Base.lock_optimistically = false
require 'timeout'
require 'pp'

50.times do 
	passes = Pass.where('acquired_at < :date', date: 6.days.ago).limit(100).includes(jobs: [:products])
        pp passes
	passes.each do |x| 
		#x.destroy!
		status = Timeout::timeout(5*60) do
			#puts "Deleting #{x.id}"
                	x.destroy!
        	end
	end
end


s = Job.where("pass_id is null")
puts ("Lost Jobs: #{s.length}")
s.each do |x| 
	status = Timeout::timeout(5*60) do 
		x.delete if !x.pass
	end
end
EOF


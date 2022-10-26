require 'aws-sdk-s3'
require 'pp'
require_relative './shell_out_helper'
# copy_output("arn:aws:s3:::jc-l1-product-us-west-2","test.txt")
class Test
  include ProcessingFramework::ShellOutHelper

  def test
    Dir.glob('/mnt/raid/jcable/fire-aws/aws-fire-docker-starting-point/mounts/out/*.h5')[0, 10].each do |h5|
      puts "Doing #{h5}"
      s = copy_output('s3://jc-l1-product-us-west-2/waff__les/are/good/', h5)
    end
  end
end

t = Test.new
t.test

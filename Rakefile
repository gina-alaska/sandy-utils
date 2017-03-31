require 'rake/version_task'
Rake::VersionTask.new do |task|
  task.with_git_tag = true
end

desc "upload package to s3"
task :s3 do
  profile = ENV['AWS_PROFILE'] || 'uafgina'
  sh "source results/last_build.env; aws s3 cp results/$pkg_artifact s3://gina-packages --acl=public-read --profile=#{profile}; cat results/last_build.env"
end

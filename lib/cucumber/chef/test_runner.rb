module Cucumber
  module Chef
    class TestRunnerError < Error ; end

    class TestRunner

      require 'cucumber/chef/test_lab'

      def initialize(project_dir, config)
        @project_dir = project_dir
        @config = config
      end

      def run
        upload_project
        @project_path = File.join('/home/ubuntu', File.basename(@project_dir), 'features')
        connection = Net::SSH.start(@hostname, 'ubuntu', :keys => @key) do |ssh|
          @output = ssh.exec!("sudo cucumber #{@project_path}")
        end
        puts @output
      end

      def upload_project
        lab = Cucumber::Chef::TestLab.new(@config)
        @hostname = lab.public_hostname
        @key = File.expand_path(@config[:knife][:identity_file])
        %x[scp -r -i #{@key} #{@project_dir} ubuntu@#{@hostname}: 2>/dev/null]
        chef_dir = @config.generate_chef_dir
        %x[scp -r -i #{@key} #{chef_dir} ubuntu@#{@hostname}:. 2>/tmp/err 1>&2]
        FileUtils.rm_r chef_dir
        puts "Cucumber-chef project: #{File.basename(@project_dir)} sucessfully uploaded to the test lab."
      end
    end
  end
end

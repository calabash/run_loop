require 'open3'

describe 'monkey patching' do
  it "awesome-print '=='" do
    Open3.popen3('sh') do |stdin, stdout, stderr, _|
      stdin.puts 'bundle exec irb <<EOF'
      stdin.puts "require 'run_loop'"
      stdin.puts "foo = RunLoop::Version.new('9.9.9')"
      stdin.puts 'EOF'
      stdin.close
      out = stdout.read.strip
      err = stderr.read.strip
      expect(out[/Error: undefined method `major' for/,0]).to be == nil
      expect(out[/Error:/,0]).to be == nil
      expect(err).to be == ''
    end
  end
end

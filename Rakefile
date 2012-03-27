require 'rake'
require 'erb'
require 'shellwords'


desc "install the dot files into user's home directory"
task :install do
  replace_all = false
  Dir['*'].each do |file|
    next if %w[Rakefile README.rdoc LICENSE].include? file
    
    if File.exist?(File.join(ENV['HOME'], ".#{file.sub('.erb', '')}"))
      if File.identical? file, File.join(ENV['HOME'], ".#{file.chomp('.erb')}")
        puts "identical ~/.#{file.sub('.erb', '')}"
      elsif replace_all
        replace_file(file)
      else
        begin
          completed = true
          print "overwrite ~/.#{file.chomp('.erb')}? [yndaq] "
          $stdout.flush
          case $stdin.gets.chomp
          when 'a'
            replace_all = true
            replace_file(file)
          when 'y'
            replace_file(file)
          when 'd'
            completed = false
            old_file  = File.join(ENV['HOME'], ".#{file.chomp('.erb')}")
            old_file  = File.readlink(old_file) while File.symlink?(old_file)
            system('git', 'diff', old_file, file)
          when 'q'
            exit
          else
            puts "skipping ~/.#{file.sub('.erb', '')}"
          end
        end until completed
      end
    else
      link_file(file)
    end
  end
end
task :default => :install


# --- helper methods

def replace_file(file, target_dir=ENV['HOME'])
  system %Q{rm -rf "#{target_dir}/.#{file.sub('.erb', '')}"}
  link_file(file, target_dir)
end

def link_file(file, target_dir=ENV['HOME'])
  if file =~ /.erb$/
    puts "generating ~/.#{file.sub('.erb', '')}"
    File.open(File.join("#{target_dir}", ".#{file.sub('.erb', '')}"), 'w') do |new_file|
      new_file.write ERB.new(File.read(file)).result(binding)
    end
  else
    puts "linking file: #{file}"
    system %Q{ln -s "$PWD/#{file}" "#{target_dir}/.#{file}"}
  end
end


# --- martin -------------

desc "setup sublime 2 - command line launcher, themes, packages"
task :setup_sublime2 do
  if File.exists?("/Applications/Sublime Text 2.app") then
    print "Comman line launcher 'subl' ... "
    if !File.exists?("~/bin") then
      system('mkdir ~/bin')
    end
    system('ln -f -s "/Applications/Sublime Text 2.app/Contents/SharedSupport/bin/subl" ~/bin/subl')
    puts "installed"

    print "Themes ... "
    system('cp resources/sublime2/themes/*.tmTheme ~/Library/Application\ Support/Sublime\ Text\ 2/Packages/.')
    puts "installed"

    puts '--- To be install Packages --------------------------'
    puts '  Install Package installer'
    puts '  Install Pck: Gist'
    puts '  Install Pck: GotRecent(File)'
    puts '  Install Pck: GotoTag'
    puts '  Install Pck: RSpec (code navigation)'
    puts '  Install Pck: RSpec snippets and syntax'
    puts '  Install Pck: Rails related Files'
    puts '  Install Pck: Trailing Spaces'
    puts '  Install Pck: HTML5'
  else
    puts "Could not find 'Sublime Text 2'"
  end
end

# --- END: martin -------------

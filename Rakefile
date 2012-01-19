require 'rake'
require 'erb'


desc "install the dot files into user's home directory"
task :install do
  replace_all = false
  Dir['*'].each do |file|
    next if %w[Rakefile README.rdoc LICENSE RubyMine].include? file
    
    if File.exist?(File.join(ENV['HOME'], ".#{file.sub('.erb', '')}"))
      if File.identical? file, File.join(ENV['HOME'], ".#{file.sub('.erb', '')}")
        puts "identical ~/.#{file.sub('.erb', '')}"
      elsif replace_all
        replace_file(file)
      else
        print "overwrite ~/.#{file.sub('.erb', '')}? [ynaq] "
        case $stdin.gets.chomp
        when 'a'
          replace_all = true
          replace_file(file)
        when 'y'
          replace_file(file)
        when 'q'
          exit
        else
          puts "skipping ~/.#{file.sub('.erb', '')}"
        end
      end
    else
      link_file(file)
    end
  end
end




desc "setup sublime 2 - command line launcher, themes, packages"
task :setup_sublime2 do
  if File.exists?("/Applications/Sublime Text 2.app") then
    print "Comman line launcher 'subl' ... "
    system('ln -f -s "/Applications/Sublime Text 2.app/Contents/SharedSupport/bin/subl" ~/bin/subl')
    puts "installed"

    print "Themes ... "
    system('cp resources/sublime2/themes/*.tmTheme /Users/martin/Library/Application\ Support/Sublime\ Text\ 2/Packages/.')
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

require 'rake'
require 'erb'

desc "install the dot files into user's home directory"
task :install do
  replace_all = false
  Dir['*'].each do |file|
    next if %w[Rakefile README.rdoc LICENSE RubyMine31].include? file
    
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


# desc "install RubyMine31 settings"
# task :rubymine30 do
#   replace_all = false
#   target_dir = ENV['HOME']
#   target_dir = File.join(ENV['HOME'], "Library/Preferences/RubyMine31")
#   
#   if File.exists?("#{target_dir}") then
#     system %Q{cp -rf #{target_dir} #{target_dir}#{Time.now.strftime('%Y-%m-%d-T%H-%M-%S')}}
#   else
#     system %Q{mkdir -p #{target_dir}}
#   end
#   
#   Dir.chdir("rubymine30")
#   Dir['*'].each do |file|
#     if File.exist?(File.join("#{target_dir}", "#{file}"))
#       if File.identical? file, File.join("#{target_dir}", "#{file}")
#         puts "identical #{target_dir}/#{file}"
#       elsif replace_all
#         system %Q{cp -rf #{file} #{target_dir}/#{file}}
#         puts "replaced: #{target_dir}/#{file}"
#       else
#         print "overwrite #{file.sub('.erb', '')}? [ynaq] "
#         case $stdin.gets.chomp
#           when 'a'
#             replace_all = true
#             system %Q{cp -rf #{file} #{target_dir}/#{file}}
#             puts "replaced: #{target_dir}/#{file}"
#           when 'y'
#             system %Q{cp -rf #{file} #{target_dir}/#{file}}
#             puts "replaced: #{target_dir}/#{file}"
#           when 'q'
#             exit
#           else
#             puts "skipping #{file.sub('.erb', '')}"
#         end
#       end
#     else
#       system %Q{cp -R #{file} #{target_dir}/#{file}}
#       puts "copied #{target_dir}/#{file}"
#     end
#   end
# end


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

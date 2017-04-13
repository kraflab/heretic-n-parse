category_keys = {
  'm' => '"SM Max"',
  'f' => '"BP Max"',
  'x' => '"NM Max"',
  'n' => '"NM Speed"',
  'o' => '"NoMo"',
  'p' => '"Pacifist"',
  's' => '"SM Speed"',
  'b' => '"BP Speed"',
  't' => '"Tyson"'
}

# Given a list of files, extract author information, and parse file name
# Print out a list of demos, with available info
files = ARGV
files.each do |file_name|
  base_name = file_name.gsub(/\..+/, '').split('/').last
  short_name = base_name.downcase
  level = short_name[0..3]
  category = category_keys[level[2]]
  level[0] = 'e'
  level[2] = 'm'
  time_chars = short_name[4..-1].chars
  time_chars.shift while time_chars[0] =~ /[-0]/
  level += time_chars.shift if time_chars[0] == 's'
  time = time_chars.join
  time.insert(-3, ':') if time.length > 2
  success = false
  File.readlines(file_name).each do |line|
    if line[0..5].downcase == 'author'
      text = line.gsub(/\[.+\]|\(.+\)|<.+>|".+"|:|--/, '').scan /[^\s]+/
      text.shift
      text.reject! { |i| i =~ /@/ }
      name = text.join ' '
      case name
      when 'JC Dorne'
        name = 'JC'
      end
      puts "#{level} #{category} #{time} \"#{name}\" #{base_name}.zip"
      author_counts[name] += 1
      success = true
      break
    end
  end
  STDERR.puts "Fail: #{short_name}!" unless success
end

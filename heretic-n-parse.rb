# List of category file keys 'h1x1-yyy'
category_keys = {
  'm' => 'SM Max',
  'f' => 'BP Max',
  'x' => 'NM 100S',
  'n' => 'NM Speed',
  'o' => 'NoMo',
  'p' => 'Pacifist',
  's' => 'SM Speed',
  'b' => 'BP Speed',
  't' => 'Tyson'
}

# Given a list of zip files, extract demo information
# Print out a list of demos, with available info, for use with the api
files = ARGV
files.each do |file_name|
  # Parse info from the zip name
  base_name = file_name.gsub(/\..+/, '').split('/').last
  short_name = base_name.downcase
  level = short_name[0..3]
  category = category_keys[level[2]]
  if category.nil?
    STDERR.puts "Fail: #{base_name}: unknown category code"
    next
  end
  level[0] = 'E'
  level[2] = 'M'
  time_chars = short_name[4..-1].chars
  time_chars.shift while time_chars[0] == '-'
  level += time_chars.shift if time_chars[0] == 's'
  time = time_chars.join
  if time.length == 4 and category == 'NoMo'
    time.insert(-3, '.')
    time.insert(0, '0:')
  else
    time.insert(-3, ':')
  end
  success = false
  result = {tas: 0, guys: 1, file: file_name, version: 0, engine: nil,
            wad_username: 'heretic', time: time, level: level,
            levelstat: time, category_name: category, video_link: nil}
  sub_files = `unzip -o #{file_name}`.lines.collect { |i| i.scan(/[^\s]+/)[1] }.select { |i| i =~ /txt|lmp/i }
  rm_files = sub_files.join ' '
  
  # Detect / ignore bonus demos
  if sub_files.count != 2
    sub_files = sub_files.select{ |i| i =~ /#{base_name}/i }
    if sub_files.count != 2
      `rm #{rm_files}`
      STDERR.puts "Fail: #{base_name}: wrong file count"
      STDERR.puts "  #{rm_files}"
      next
    end
  end
  
  # Check for existence of target files
  txt_file_name = sub_files.find { |i| i =~ /txt/i }
  lmp_file_name = sub_files.find { |i| i =~ /lmp/i }
  if txt_file_name.nil?
    STDERR.puts "Fail: #{base_name}: missing txt file"
    next
  end
  if lmp_file_name.nil?
    STDERR.puts "Fail: #{base_name}: missing lmp file"
    next
  end
  
  # Assume lmp modify time is record date
  result[:recorded_at] = File.mtime(lmp_file_name)
  
  # Convert old encodings
  encoding = `file -i #{txt_file_name} | grep -o "=.*" | sed 's/=//'`.chomp
  if !`iconv -f #{encoding} -t UTF-8 #{txt_file_name} -o temp 2>&1`.empty?
    STDERR.puts "Bad encoding for #{txt_file_name}, but continuing..."
    `cp #{txt_file_name} temp`
  end
  
  # Parse file for author and game data
  file = File.open('temp')
  file.readlines.each do |line|
    case line[0..3].downcase
    when 'auth'
      # Remove extra info, such as email addresses
      line = line.force_encoding('UTF-8')
      text = line.gsub(/\[.+\]|\(.+\)|<.+>|".+"|:|--/, '').scan /[^\s]+/
      text.shift
      text.reject! { |i| i =~ /@/ }
      name = text.join ' '
      case name
      when 'JC Dorne'
        name = 'JC'
      when '-=QWERTY=-'
        name = 'QWERTY'
      end
      result[:players] = name
      success = true
    when 'game'
      # Check for vv's hack
      result[:engine] = line =~ /vv/ ? 'Heretic v1.3 + vv' : 'Heretic v1.3'
    end
  end
  
  # Clean up files
  `rm temp #{rm_files}`
  result[:engine] ||= 'Heretic v1.3'
  if success
    # Syntax for use with the api
    print 'post demo ='
    result.each do |k, v|
      print " #{k}: \"#{v}\""
    end
    puts
  else
    STDERR.puts "Fail: #{base_name}: #{result.to_s}"
  end
end

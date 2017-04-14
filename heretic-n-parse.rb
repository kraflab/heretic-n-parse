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

# Given a list of files, extract author information, and parse file name
# Print out a list of demos, with available info
files = ARGV
files.each do |file_name|
  base_name = file_name.gsub(/\..+/, '').split('/').last
  short_name = base_name.downcase
  level = short_name[0..3]
  category = category_keys[level[2]]
  level[0] = 'E'
  level[2] = 'M'
  time_chars = short_name[4..-1].chars
  time_chars.shift while time_chars[0] == '-'
  level += time_chars.shift if time_chars[0] == 's'
  time = time_chars.join
  time.insert(-3, ':')
  success = false
  result = {tas: 0, guys: 1, recorded_at: nil, file: nil, version: 0,
            wad_username: 'heretic', time: time, level: level,
            levelstat: time, category_name: category, video_link: nil}
  file = File.open(file_name)
  file.readlines.each do |line|
    case line[0..3].downcase
    when 'auth'
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
  if success
    result[:engine] ||= 'Heretic v1.3'
    # Syntax for use with the api
    print 'post demo ='
    result.each do |k, v|
      print " #{k}: \"#{v}\""
    end
    puts
  else
    STDERR.puts "Fail: #{base_name}!"
  end
end

require 'path'

def shell(*cmds)
  cmd = cmds.join("\n")
  puts cmd
  system cmd
end

#
# Install all tasks found in tasks folder
#
# See .rake files there for complete documentation.
#
Dir["tasks/*.rake"].each do |taskfile|
  load taskfile
end

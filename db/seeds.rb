# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
ts = Community.create :name => "Twelvestone", :introduction => "You all know who you are - designers, developers, degenerates . . ."

[
 [ "Waiting For Godot", "Yeah, you know what to do"],
 [ "Flash", "Isn't it dead yet? "],
 [ "Design", "Fancy!" ],
 [ "Development", "Development cheese"],
].each_with_index do |(name, description), i|
  ts.forums.create :name => name, :description => description, :ordinal => i
end


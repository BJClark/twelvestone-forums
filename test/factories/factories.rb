FactoryGirl.define do
  
  factory :user do
    sequence(:name)  {|n|  "Test User #{n}" }
    sequence(:email) {|n|  "user#{n}@example.com" }
    password               "password"
    password_confirmation  "password"
  end
  
  factory :forum do 
    sequence(:name) { |n| "Tiny Fuckers #{n}" }
    description "Just two primordial dwarves living and loving."
    sequence(:ordinal, 0)
  end
  
  factory :post do 
    text "FNORD"
    author { FactoryGirl.create(:user).as_embedded }
    conversation
  end
  
  factory :conversation do
    sequence(:title) { |n| "I killed a man and I didn't feel a thing #{n}" }
    forum
  end  
  
end


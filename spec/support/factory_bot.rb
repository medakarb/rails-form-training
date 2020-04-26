# To use build(:user), create(:user) without FactoryBot, add this
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

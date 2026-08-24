class PunditTestRecord
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def self.all
    User.all.map { |user| new(user) }
  end
end

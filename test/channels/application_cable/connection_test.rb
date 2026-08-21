require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "connects with a valid session cookie" do
    session = users(:one).sessions.create!(user_agent: "Rails Testing", ip_address: "127.0.0.1")
    cookies.signed[:session_id] = session.id

    connect

    assert_equal session.user, connection.current_user
  end

  test "rejects the connection without a valid session cookie" do
    assert_reject_connection { connect }
  end
end

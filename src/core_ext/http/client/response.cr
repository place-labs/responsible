require "../../../responsible/response"

class HTTP::Client::Response
  # Wraps `self` into a `Responsible::Response`.
  def ~
    Responsible::Response.new(self)
  end
end

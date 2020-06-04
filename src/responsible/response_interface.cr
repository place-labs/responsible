require "http/status"
require "http/headers"
require "./response"

module Responsible::ResponseInterface
  abstract def status : HTTP::Status

  abstract def headers : HTTP::Headers

  abstract def body? : String?

  abstract def body_io : IO

  # Wraps `self` into a `Responsible::Response`.
  def ~
    Responsible::Response.new(self)
  end
end

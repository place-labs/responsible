require "http/status"

module Responsible
  enum ResponseType
    Informational
    Success
    Redirection
    ClientError
    ServerError

    def self.from(status : HTTP::Status) : self
      case status
      when .informational?
        Informational
      when .success?
        Success
      when .redirection?
        Redirection
      when .client_error?
        ClientError
      when .server_error?
        ServerError
      else
        raise "unhandled response code"
      end
    end
  end
end

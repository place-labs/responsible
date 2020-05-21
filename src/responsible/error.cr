module Responsible
  class Error < IO::Error
    def self.from(response : Response)
      message = "HTTP #{response.status}"
      case response.status
      when .client_error?
        ClientError.new message
      when .server_error?
        ServerError.new message
      else
        new message
      end
    end
  end

  class ClientError < Error
  end

  class ServerError < Error
  end
end

